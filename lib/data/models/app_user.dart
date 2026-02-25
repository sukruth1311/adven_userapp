import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isMember;
  final String? membershipId;
  final String? membershipName;
  final DateTime? expiryDate;
  final Map<String, bool> immunities;
  final String? phone;
  final String? profileImage;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isMember,
    this.membershipId,
    this.membershipName,
    this.expiryDate,
    required this.immunities,
    this.phone,
    this.profileImage,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? expiry;

    if (json['expiryDate'] != null) {
      if (json['expiryDate'] is Timestamp) {
        expiry = (json['expiryDate'] as Timestamp).toDate();
      } else if (json['expiryDate'] is String) {
        expiry = DateTime.tryParse(json['expiryDate']);
      }
    }

    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isMember: json['isMember'] ?? false,
      membershipId: json['membershipId'],
      membershipName: json['membershipName'],
      expiryDate: expiry,
      immunities: Map<String, bool>.from(json['immunities'] ?? {}),
      phone: json['phone'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isMember': isMember,
      'membershipId': membershipId,
      'membershipName': membershipName,
      'expiryDate': expiryDate, // 🔥 DO NOT convert to string
      'immunities': immunities,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}
