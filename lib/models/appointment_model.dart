// appointment_model.dart

enum AppointmentStatus { upcoming, completed, missed }

class AppointmentModel {
  final String id;
  final DateTime dateTime;
  final String clinic;
  final String doctorName;
  final String requestDetails;
  final AppointmentStatus status;

  AppointmentModel({
    required this.id,
    required this.dateTime,
    required this.clinic,
    required this.doctorName,
    required this.requestDetails,
    required this.status,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int),
      clinic: map['clinic'] ?? '',
      doctorName: map['doctorName'] ?? '',
      requestDetails: map['requestDetails'] ?? '',
      status: AppointmentStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.upcoming,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime.millisecondsSinceEpoch,
      'clinic': clinic,
      'doctorName': doctorName,
      'requestDetails': requestDetails,
      'status': status.name,
    };
  }
}