enum HealthStatus { stable, warning, critical }

class CheckInModel {
  final String id;
  final String userId;
  final DateTime date;
  final List<String> symptoms;
  final HealthStatus healthStatus;
  final String? additionalNotes;
  final bool submittedToDoctor;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.symptoms,
    required this.healthStatus,
    this.additionalNotes,
    this.submittedToDoctor = false,
  });

  factory CheckInModel.fromMap(Map<String, dynamic> map, String id) {
    return CheckInModel(
      id: id,
      userId: map['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      healthStatus: HealthStatus.values.firstWhere(
            (e) => e.name == map['healthStatus'],
        orElse: () => HealthStatus.stable,
      ),
      additionalNotes: map['additionalNotes'],
      submittedToDoctor: map['submittedToDoctor'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'symptoms': symptoms,
      'healthStatus': healthStatus.name,
      'additionalNotes': additionalNotes,
      'submittedToDoctor': submittedToDoctor,
    };
  }
}