import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';
import '../models/appointment_model.dart';
import '../models/checkin_model.dart';
import '../utils/constants.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Medications ──────────────────────────────────────────────────────────

  Stream<List<MedicationModel>> getMedicationsStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.medicationsCollection)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => MedicationModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<List<MedicationModel>> getMedications(String userId) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.medicationsCollection)
        .get();
    return snap.docs
        .map((d) => MedicationModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> markMedicationTaken(
      String userId, String medicationId, String timeKey) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.medicationsCollection)
        .doc(medicationId)
        .update({'takenStatus.$timeKey': MedicationStatus.taken.name});
  }

  Future<void> markMedicationOverdue(
      String userId, String medicationId, String timeKey) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.medicationsCollection)
        .doc(medicationId)
        .update({'takenStatus.$timeKey': MedicationStatus.overdue.name});
  }

  Future<void> seedDemoMedications(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meds = [
      {
        'name': 'Metformin',
        'dosage': '500mg',
        'frequency': 'Twice daily',
        'scheduledTimes': [
          DateTime(now.year, now.month, now.day, 8, 0).millisecondsSinceEpoch,
          DateTime(now.year, now.month, now.day, 20, 0).millisecondsSinceEpoch,
        ],
        'instructions': 'Take with meals',
        'prescribedBy': 'Dr. Perera',
        'startDate': today.millisecondsSinceEpoch,
        'endDate': null,
        'takenStatus': {},
      },
      {
        'name': 'Lisinopril',
        'dosage': '10mg',
        'frequency': 'Once daily',
        'scheduledTimes': [
          DateTime(now.year, now.month, now.day, 9, 0).millisecondsSinceEpoch,
        ],
        'instructions': 'Take in the morning',
        'prescribedBy': 'Dr. Silva',
        'startDate': today.millisecondsSinceEpoch,
        'endDate': null,
        'takenStatus': {},
      },
      {
        'name': 'Aspirin',
        'dosage': '75mg',
        'frequency': 'Once daily',
        'scheduledTimes': [
          DateTime(now.year, now.month, now.day, 14, 0).millisecondsSinceEpoch,
        ],
        'instructions': 'Take after lunch',
        'prescribedBy': 'Dr. Perera',
        'startDate': today.millisecondsSinceEpoch,
        'endDate': null,
        'takenStatus': {},
      },
    ];
    final batch = _firestore.batch();
    for (final med in meds) {
      final ref = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.medicationsCollection)
          .doc();
      batch.set(ref, med);
    }
    await batch.commit();
  }

  // ─── Appointments ─────────────────────────────────────────────────────────

  Stream<List<AppointmentModel>> getAppointmentsStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.appointmentsCollection)
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => AppointmentModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<void> requestReschedule(
      String userId, String appointmentId, String note) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId)
        .update({
      'rescheduleStatus': RescheduleStatus.requested.name,
      'rescheduleRequestedAt': DateTime.now().millisecondsSinceEpoch,
      'rescheduleNote': note,
    });
  }

  Future<void> seedDemoAppointments(String userId) async {
    final now = DateTime.now();
    final appointments = [
      {
        'dateTime': DateTime(now.year, now.month, now.day + 3, 10, 30)
            .millisecondsSinceEpoch,
        'clinic': 'Cardiology Clinic',
        'doctorName': 'Dr. Nimal Perera',
        'requestDetails': 'Routine follow-up for blood pressure monitoring',
        'status': AppointmentStatus.upcoming.name,
        'rescheduleStatus': RescheduleStatus.none.name,
        'investigations': [
          'Full Blood Count (FBC)',
          'ECG Report',
          'Blood Pressure Log (last 2 weeks)',
        ],
        'investigationNotes':
        'Please bring all reports in original. Fasting required for blood tests.',
      },
      {
        'dateTime': DateTime(now.year, now.month, now.day + 7, 14, 0)
            .millisecondsSinceEpoch,
        'clinic': 'Endocrinology Department',
        'doctorName': 'Dr. Kamala Silva',
        'requestDetails': 'Diabetes management review and HbA1c test',
        'status': AppointmentStatus.upcoming.name,
        'rescheduleStatus': RescheduleStatus.none.name,
        'investigations': [
          'HbA1c Blood Test',
          'Fasting Blood Sugar Report',
          'Urine Microalbumin Test',
        ],
        'investigationNotes':
        'Must be fasting for at least 8 hours before blood test.',
      },
      {
        'dateTime': DateTime(now.year, now.month, now.day - 5, 9, 0)
            .millisecondsSinceEpoch,
        'clinic': 'General Medicine',
        'doctorName': 'Dr. Ruwan Fernando',
        'requestDetails': 'General health check-up',
        'status': AppointmentStatus.completed.name,
        'rescheduleStatus': RescheduleStatus.none.name,
        'investigations': [],
        'investigationNotes': null,
      },
      {
        'dateTime': DateTime(now.year, now.month, now.day - 10, 11, 0)
            .millisecondsSinceEpoch,
        'clinic': 'Dietetics Clinic',
        'doctorName': 'Dr. Priya Jayasinghe',
        'requestDetails': 'Dietary consultation and nutrition plan',
        'status': AppointmentStatus.missed.name,
        'rescheduleStatus': RescheduleStatus.none.name,
        'investigations': [],
        'investigationNotes': null,
      },
    ];
    final batch = _firestore.batch();
    for (final appt in appointments) {
      final ref = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.appointmentsCollection)
          .doc();
      batch.set(ref, appt);
    }
    await batch.commit();
  }

  // ─── Check-Ins ────────────────────────────────────────────────────────────

  Future<void> submitCheckIn(CheckInModel checkIn) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(checkIn.userId)
        .collection(AppConstants.checkInsCollection)
        .add(checkIn.toMap());
  }

  Future<void> updateCheckIn(
      String userId, String checkInId, CheckInModel checkIn) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.checkInsCollection)
        .doc(checkInId)
        .update(checkIn.toMap());
  }

  Future<CheckInModel?> getTodayCheckIn(String userId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.checkInsCollection)
        .where('date',
        isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
        isLessThan: end.millisecondsSinceEpoch)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CheckInModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Stream<List<CheckInModel>> getCheckInsStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.checkInsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => CheckInModel.fromMap(d.data(), d.id))
        .toList());
  }
}