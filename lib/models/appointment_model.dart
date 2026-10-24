enum AppointmentStatus { upcoming, completed, missed }

/// Patient-side reschedule status — mirrors what the server stores in Firestore
enum RescheduleStatus {
  none,
  requested,
  approved,
  rejected,
  alternativeSuggested,
  // legacy alias kept for backward compatibility
  accepted,
}

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
  /// Message sent by staff (approval confirmation / rejection reason / alternative suggestion)
  final String? staffMessage;
  /// Suggested date string from staff (for alternativeSuggested status)
  final String? suggestedDate;
  /// Suggested time string from staff (for alternativeSuggested status)
  final String? suggestedTime;
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
    this.staffMessage,
    this.suggestedDate,
    this.suggestedTime,
    this.investigations = const [],
    this.investigationNotes,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse rescheduleStatus — handle both old ('accepted') and new values
    RescheduleStatus parseRescheduleStatus(String? raw) {
      switch (raw) {
        case 'requested':
          return RescheduleStatus.requested;
        case 'approved':
        case 'accepted': // legacy
          return RescheduleStatus.approved;
        case 'rejected':
          return RescheduleStatus.rejected;
        case 'alternativeSuggested':
          return RescheduleStatus.alternativeSuggested;
        default:
          return RescheduleStatus.none;
      }
    }

    return AppointmentModel(
      id: id,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int),
      clinic: map['clinic'] ?? '',
      doctorName: () {
        final name = map['doctorName'] ?? '';
        if (name.isNotEmpty && !name.toLowerCase().startsWith('dr.')) {
          return 'Dr. $name';
        }
        return name;
      }(),
      requestDetails: map['requestDetails'] ?? '',
      status: AppointmentStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.upcoming,
      ),
      rescheduleStatus: parseRescheduleStatus(map['rescheduleStatus'] as String?),
      rescheduleRequestedAt: map['rescheduleRequestedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          map['rescheduleRequestedAt'] as int)
          : null,
      newDateTime: map['newDateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['newDateTime'] as int)
          : null,
      rescheduleNote: map['rescheduleNote'],
      staffMessage: map['staffMessage'],
      suggestedDate: map['suggestedDate'],
      suggestedTime: map['suggestedTime'],
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
      'staffMessage': staffMessage,
      'suggestedDate': suggestedDate,
      'suggestedTime': suggestedTime,
      'investigations': investigations,
      'investigationNotes': investigationNotes,
    };
  }

  bool get hasInvestigations => investigations.isNotEmpty;
}