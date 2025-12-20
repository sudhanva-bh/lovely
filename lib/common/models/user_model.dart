// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  final String uid;
  final String name;
  final DateTime dob;
  final String gender;
  final String profilePictureURL;
  final String? coupleCode; // Added field
  final UserModel? partner;

  UserModel({
    required this.uid,
    required this.name,
    required this.dob,
    required this.gender,
    required this.profilePictureURL,
    this.coupleCode,
    this.partner,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    DateTime? dob,
    String? gender,
    String? profilePictureURL,
    String? coupleCode,
    UserModel? partner,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      profilePictureURL: profilePictureURL ?? this.profilePictureURL,
      coupleCode: coupleCode ?? this.coupleCode,
      partner: partner ?? this.partner,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'dob': dob.millisecondsSinceEpoch,
      'gender': gender,
      'profile_picture_url': profilePictureURL,
      'couple_code': coupleCode, // Added mapping
      'partner_uid': partner?.uid,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    dynamic partnerData = map['partner'];
    UserModel? partnerModel;

    if (partnerData is List) {
      if (partnerData.isNotEmpty) {
        partnerModel = UserModel.fromMap(
          partnerData.first as Map<String, dynamic>,
        );
      }
    } else if (partnerData is Map<String, dynamic>) {
      partnerModel = UserModel.fromMap(partnerData);
    }

    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      dob: DateTime.fromMillisecondsSinceEpoch(map['dob'] as int),
      gender: map['gender'] as String,
      profilePictureURL: (map['profile_picture_url'] as String?) ?? '',
      coupleCode: map['couple_code'] as String?, // Added mapping
      partner: partnerModel,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, dob: $dob, gender: $gender, profilePictureURL: $profilePictureURL, partner: $partner)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.name == name &&
        other.dob == dob &&
        other.gender == gender &&
        other.profilePictureURL == profilePictureURL &&
        other.partner == partner;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        dob.hashCode ^
        gender.hashCode ^
        profilePictureURL.hashCode ^
        partner.hashCode;
  }
}
