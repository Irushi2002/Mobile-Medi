enum AppointmentStatus { upcoming, completed, missed }
enum RescheduleStatus { none, requested, accepted }

class AppointmentModel {
  final String id;
  final DateTime dateTime;
  final String clinic;
  final String doctorName;
  final String requestDetails;
  final AppointmentStatus status;
  final RescheduleStatus rescheduleStatus;
  final DateTime? rescheduleRequestedAt;
  final DateTime? newDateTime;
  final String? rescheduleNote;
  // Investigation fields from doctor/website
  final List<String> investigations;
  final String? investigationNotes;

  AppointmentModel({
    required this.id,
    required this.dateTime,
    required this.clinic,
    required this.doctorName,
    required this.requestDetails,
    required this.status,
    this.rescheduleStatus = RescheduleStatus.none,
    this.rescheduleRequestedAt,
    this.newDateTime,
    this.rescheduleNote,
    this.investigations = const [],
    this.investigationNotes,
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
      rescheduleStatus: RescheduleStatus.values.firstWhere(
            (e) => e.name == (map['rescheduleStatus'] ?? 'none'),
        orElse: () => RescheduleStatus.none,
      ),
      rescheduleRequestedAt: map['rescheduleRequestedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          map['rescheduleRequestedAt'] as int)
          : null,
      newDateTime: map['newDateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['newDateTime'] as int)
          : null,
      rescheduleNote: map['rescheduleNote'],
      investigations:
      List<String>.from(map['investigations'] ?? []),
      investigationNotes: map['investigationNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime.millisecondsSinceEpoch,
      'clinic': clinic,
      'doctorName': doctorName,
      'requestDetails': requestDetails,
      'status': status.name,
      'rescheduleStatus': rescheduleStatus.name,
      'rescheduleRequestedAt': rescheduleRequestedAt?.millisecondsSinceEpoch,
      'newDateTime': newDateTime?.millisecondsSinceEpoch,
      'rescheduleNote': rescheduleNote,
      'investigations': investigations,
      'investigationNotes': investigationNotes,
    };
  }

  bool get hasInvestigations => investigations.isNotEmpty;
}