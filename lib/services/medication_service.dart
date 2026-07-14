import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> deleteDemoDataIfExists(String userId) async {
    try {
      debugPrint('Cleanup: Checking for previously seeded demo data for user: $userId');
      // 1. Delete default medications
      final medSnap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.medicationsCollection)
          .where('name', whereIn: ['Metformin', 'Lisinopril', 'Aspirin'])
          .get();

      if (medSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in medSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('Cleanup: Deleted ${medSnap.docs.length} demo medications.');
      } else {
        debugPrint('Cleanup: No demo medications found.');
      }

      // 2. Delete default appointments
      final apptSnap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.appointmentsCollection)
          .where('doctorName', whereIn: [
            'Dr. Nimal Perera',
            'Dr. Kamala Silva',
            'Dr. Ruwan Fernando',
            'Dr. Priya Jayasinghe'
          ])
          .get();

      if (apptSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in apptSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('Cleanup: Deleted ${apptSnap.docs.length} demo appointments.');
      } else {
        debugPrint('Cleanup: No demo appointments found.');
      }
      // 3. Delete empty/invalid name medications
      final invalidMedSnap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.medicationsCollection)
          .get();

      if (invalidMedSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        int invalidCount = 0;
        for (final doc in invalidMedSnap.docs) {
          final name = doc.data()['name'] as String?;
          if (name == null || name.trim().isEmpty) {
            batch.delete(doc.reference);
            invalidCount++;
          }
        }
        if (invalidCount > 0) {
          await batch.commit();
          debugPrint('Cleanup: Deleted $invalidCount invalid/empty medications.');
        }
      }
    } catch (e) {
      debugPrint('Cleanup Error: Failed to delete demo data: $e');
    }
  }
}