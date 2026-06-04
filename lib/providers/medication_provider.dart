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
  bool _isLoading = false;

  List<MedicationModel> get medications => _medications;
  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;

  void initialize(String userId) {
    _medSubscription?.cancel();
    _apptSubscription?.cancel();

    _medSubscription =
        _service.getMedicationsStream(userId).listen((meds) {
          _medications = meds;
          _checkAndMarkOverdue(userId);
          notifyListeners();
        });

    _apptSubscription =
        _service.getAppointmentsStream(userId).listen((appts) {
          _appointments = appts;
          notifyListeners();
        });
  }

  void _checkAndMarkOverdue(String userId) {
    final now = DateTime.now();
    for (final med in _medications) {
      for (final time in med.scheduledTimes) {
        final timeKey =
            '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}_${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        if (now.isAfter(time.add(const Duration(minutes: 30))) &&
            !med.takenStatus.containsKey(timeKey)) {
          _service.markMedicationOverdue(userId, med.id, timeKey);
        }
      }
    }
  }

  // Today's next upcoming medication
  MedicationModel? get nextMedication {
    final now = DateTime.now();
    MedicationModel? next;
    DateTime? nextTime;

    for (final med in _medications) {
      if (!med.isScheduledForDate(now)) continue;
      for (final time in med.scheduledTimes) {
        final todayTime = DateTime(
            now.year, now.month, now.day, time.hour, time.minute);
        if (todayTime.isAfter(now)) {
          if (nextTime == null || todayTime.isBefore(nextTime!)) {
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
      for (final time in med.scheduledTimes) {
        final todayTime = DateTime(
            now.year, now.month, now.day, time.hour, time.minute);
        if (todayTime.isAfter(now)) {
          if (nextTime == null || todayTime.isBefore(nextTime!)) {
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

  @override
  void dispose() {
    _medSubscription?.cancel();
    _apptSubscription?.cancel();
    super.dispose();
  }
}