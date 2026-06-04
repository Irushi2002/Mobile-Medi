// ─── user_model.dart ───────────────────────────────────────────────────────

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String? address;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? hospitalId;
  final String? primaryCondition;
  final String? diagnosis;
  final String? allergies;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final bool privacyAccepted;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.hospitalId,
    this.primaryCondition,
    this.diagnosis,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.privacyAccepted = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'],
      bloodGroup: map['bloodGroup'],
      hospitalId: map['hospitalId'],
      primaryCondition: map['primaryCondition'],
      diagnosis: map['diagnosis'],
      allergies: map['allergies'],
      emergencyContactName: map['emergencyContactName'],
      emergencyContactNumber: map['emergencyContactNumber'],
      privacyAccepted: map['privacyAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'hospitalId': hospitalId,
      'primaryCondition': primaryCondition,
      'diagnosis': diagnosis,
      'allergies': allergies,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'privacyAccepted': privacyAccepted,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactNumber,
    bool? privacyAccepted,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender,
      bloodGroup: bloodGroup,
      hospitalId: hospitalId,
      primaryCondition: primaryCondition,
      diagnosis: diagnosis,
      allergies: allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    );
  }
}