import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../models/appointment_model.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../providers/settings_provider.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationService _service = MedicationService();
  final NotificationService _notifications = NotificationService();

  SettingsProvider? _settingsProvider;

  List<MedicationModel> _medications = [];
  List<AppointmentModel> _appointments = [];
  StreamSubscription? _medSubscription;
  StreamSubscription? _apptSubscription;
  Timer? _overdueTimer;

  List<MedicationModel> get medications => _medications;
  List<AppointmentModel> get appointments => _appointments;

  /// Call this whenever SettingsProvider changes so medication/appointment
  /// notifications can be re-scheduled with the correct flags.
  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    // Re-schedule with the latest settings
    if (_medications.isNotEmpty) {
      _notifications.scheduleAllMedicationNotifications(
        _medications,
        notificationsEnabled: settings.notificationsEnabled,
        soundEnabled: settings.soundEnabled,
      );
    }
    if (_appointments.isNotEmpty) {
      _notifications.scheduleAllAppointmentNotifications(
        _appointments,
        notificationsEnabled: settings.notificationsEnabled,
        soundEnabled: settings.soundEnabled,
      );
    }
  }

  Future<void> initialize(String userId) async {
    _medSubscription?.cancel();
    _apptSubscription?.cancel();
    _overdueTimer?.cancel();

    // Request notification permissions on Android 13+ / iOS
    await _notifications.requestPermissions();

    // Clean up any remaining/previously seeded demo data
    _service.deleteDemoDataIfExists(userId);

    _medSubscription =
        _service.getMedicationsStream(userId).listen((meds) async {
      _medications = meds;
      notifyListeners();

      // Reschedule all medication notifications whenever Firestore data changes
      await _notifications.scheduleAllMedicationNotifications(
        meds,
        notificationsEnabled: _settingsProvider?.notificationsEnabled ?? true,
        soundEnabled: _settingsProvider?.soundEnabled ?? true,
      );
    });

    _apptSubscription =
        _service.getAppointmentsStream(userId).listen((appts) async {
      _appointments = appts;
      notifyListeners();

      // Reschedule all appointment notifications whenever Firestore data changes
      await _notifications.scheduleAllAppointmentNotifications(
        appts,
        notificationsEnabled: _settingsProvider?.notificationsEnabled ?? true,
        soundEnabled: _settingsProvider?.soundEnabled ?? true,
      );
    });

    // Check overdue every minute
    _overdueTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndMarkOverdue(userId),
    );

    // Also check immediately
    Future.delayed(
        const Duration(seconds: 5), () => _checkAndMarkOverdue(userId));
  }

  void _checkAndMarkOverdue(String userId) {
    final now = DateTime.now();
    for (final med in _medications) {
      if (!med.isScheduledForDate(now)) continue;
      for (final time in med.scheduledTimes) {
        final todayTime =
            DateTime(now.year, now.month, now.day, time.hour, time.minute);
        final timeKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
            '_${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

        final currentStatus =
            med.takenStatus[timeKey] ?? MedicationStatus.pending;

        // Mark overdue if more than 30 minutes past scheduled time
        // and not already taken or already marked overdue
        if (now.isAfter(todayTime.add(const Duration(minutes: 30))) &&
            currentStatus == MedicationStatus.pending) {
          _service.markMedicationOverdue(userId, med.id, timeKey);
        }
      }
    }
  }

  MedicationModel? get nextMedication {
    final now = DateTime.now();
    MedicationModel? next;
    DateTime? nextTime;
    for (final med in _medications) {
      if (!med.isScheduledForDate(now)) continue;
      for (final t in med.scheduledTimes) {
        final todayTime =
            DateTime(now.year, now.month, now.day, t.hour, t.minute);
        final timeKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        final status = med.takenStatus[timeKey] ?? MedicationStatus.pending;
        if (status == MedicationStatus.pending && todayTime.isAfter(now)) {
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
              '_${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          final status = med.takenStatus[timeKey] ?? MedicationStatus.pending;
          if (status == MedicationStatus.pending && todayTime.isAfter(now)) {
            if (nextTime == null || todayTime.isBefore(nextTime)) {
              nextTime = todayTime;
              next = med;
            }
          }
        }
      }
    }
    return next;
  }

  DateTime? get nextMedicationTime {
    final now = DateTime.now();
    DateTime? nextTime;
    for (final med in _medications) {
      if (!med.isScheduledForDate(now)) continue;
      for (final t in med.scheduledTimes) {
        final todayTime =
            DateTime(now.year, now.month, now.day, t.hour, t.minute);
        if (todayTime.isAfter(now)) {
          if (nextTime == null || todayTime.isBefore(nextTime)) {
            nextTime = todayTime;
          }
        }
      }
    }
    return nextTime;
  }

  List<MedicationModel> getMedicationsForDate(DateTime date) {
    return _medications.where((m) => m.isScheduledForDate(date)).toList();
  }

  List<AppointmentModel> getAppointmentsForDate(DateTime date) {
    return _appointments.where((a) {
      return a.dateTime.year == date.year &&
          a.dateTime.month == date.month &&
          a.dateTime.day == date.day;
    }).toList();
  }

  List<AppointmentModel> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.status == AppointmentStatus.upcoming && a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<AppointmentModel> get missedAppointments {
    return _appointments
        .where((a) => a.status == AppointmentStatus.missed)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> markTaken(
      String userId, String medicationId, String timeKey) async {
    await _service.markMedicationTaken(userId, medicationId, timeKey);
  }

  Future<void> requestReschedule(
      String userId, String appointmentId, String note) async {
    await _service.requestReschedule(userId, appointmentId, note);
  }

  /// Fetches unbooked future slots for a doctor (used by the slot-picker).
  Future<List<Map<String, String>>> fetchAvailableSlots(
      String doctorId, String appointmentId) async {
    return _service.fetchAvailableSlots(doctorId, appointmentId);
  }

  /// Submits a reschedule request with a selected date, time and reason.
  Future<bool> requestRescheduleWithSlot(String userId, String appointmentId,
      String requestedDate, String requestedTime, String reason) async {
    return _service.requestRescheduleWithSlot(
        userId, appointmentId, requestedDate, requestedTime, reason);
  }

  @override
  void dispose() {
    _medSubscription?.cancel();
    _apptSubscription?.cancel();
    _overdueTimer?.cancel();
    super.dispose();
  }
}
