import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../models/appointment_model.dart';
import '../services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationService _service = MedicationService();

  List<MedicationModel> _medications = [];
  List<AppointmentModel> _appointments = [];
  StreamSubscription? _medSubscription;
  StreamSubscription? _apptSubscription;
  Timer? _overdueTimer;

  List<MedicationModel> get medications => _medications;
  List<AppointmentModel> get appointments => _appointments;

  void initialize(String userId) {
    _medSubscription?.cancel();
    _apptSubscription?.cancel();
    _overdueTimer?.cancel();

    _medSubscription =
        _service.getMedicationsStream(userId).listen((meds) {
          _medications = meds;
          notifyListeners();
        });

    _apptSubscription =
        _service.getAppointmentsStream(userId).listen((appts) {
          _appointments = appts;
          notifyListeners();
        });

    // Check overdue every minute
    _overdueTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _checkAndMarkOverdue(userId),
    );

    // Also check immediately
    Future.delayed(const Duration(seconds: 5),
            () => _checkAndMarkOverdue(userId));
  }

  void _checkAndMarkOverdue(String userId) {
    final now = DateTime.now();
    for (final med in _medications) {
      if (!med.isScheduledForDate(now)) continue;
      for (final time in med.scheduledTimes) {
        final todayTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
        final timeKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
        if (todayTime.isAfter(now)) {
          if (nextTime == null || todayTime.isBefore(nextTime)) {
            nextTime = todayTime;
            next = med;
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

  // Get overdue medications that haven't been replaced by next dose
  List<OverdueMed> get overdueMedications {
    final now = DateTime.now();
    final overdue = <OverdueMed>[];
    for (final med in _medications) {
      if (!med.isScheduledForDate(now)) continue;
      final sortedTimes = List<DateTime>.from(med.scheduledTimes)
        ..sort((a, b) => a.compareTo(b));
      for (int i = 0; i < sortedTimes.length; i++) {
        final t = sortedTimes[i];
        final todayTime =
        DateTime(now.year, now.month, now.day, t.hour, t.minute);
        final timeKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        final status = med.takenStatus[timeKey] ?? MedicationStatus.pending;
        if (status == MedicationStatus.overdue) {
          // Check if next dose exists and is in the future
          DateTime? nextDoseTime;
          if (i + 1 < sortedTimes.length) {
            final nt = sortedTimes[i + 1];
            nextDoseTime =
                DateTime(now.year, now.month, now.day, nt.hour, nt.minute);
          }
          final showUntil = nextDoseTime ?? todayTime.add(const Duration(hours: 24));
          if (now.isBefore(showUntil)) {
            overdue.add(OverdueMed(medication: med, scheduledTime: todayTime, timeKey: timeKey));
          }
        }
      }
    }
    return overdue;
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
    a.status == AppointmentStatus.upcoming &&
        a.dateTime.isAfter(now))
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

  @override
  void dispose() {
    _medSubscription?.cancel();
    _apptSubscription?.cancel();
    _overdueTimer?.cancel();
    super.dispose();
  }
}

class OverdueMed {
  final MedicationModel medication;
  final DateTime scheduledTime;
  final String timeKey;
  OverdueMed({
    required this.medication,
    required this.scheduledTime,
    required this.timeKey,
  });
}