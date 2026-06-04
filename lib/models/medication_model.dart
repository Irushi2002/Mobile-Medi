class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<DateTime> scheduledTimes;
  final String? instructions;
  final String? prescribedBy;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, MedicationStatus> takenStatus; // key: "yyyy-MM-dd HH:mm"

  MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.scheduledTimes,
    this.instructions,
    this.prescribedBy,
    required this.startDate,
    this.endDate,
    Map<String, MedicationStatus>? takenStatus,
  }) : takenStatus = takenStatus ?? {};

  factory MedicationModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicationModel(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      scheduledTimes: (map['scheduledTimes'] as List<dynamic>? ?? [])
          .map((t) => DateTime.fromMillisecondsSinceEpoch(t as int))
          .toList(),
      instructions: map['instructions'],
      prescribedBy: map['prescribedBy'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null,
      takenStatus: (map['takenStatus'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, MedicationStatus.values.firstWhere(
              (e) => e.name == v,
          orElse: () => MedicationStatus.pending,
        )),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'scheduledTimes': scheduledTimes.map((t) => t.millisecondsSinceEpoch).toList(),
      'instructions': instructions,
      'prescribedBy': prescribedBy,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'takenStatus': takenStatus.map((k, v) => MapEntry(k, v.name)),
    };
  }

  bool isScheduledForDate(DateTime date) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isBefore(start)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (target.isAfter(end)) return false;
    }
    return true;
  }
}

enum MedicationStatus { pending, taken, overdue, skipped }