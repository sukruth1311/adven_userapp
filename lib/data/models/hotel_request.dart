import 'package:cloud_firestore/cloud_firestore.dart';

class HotelRequest {
  final String id;
  final String userId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String location;
  final bool isInternational;
  final int nights;
  final int members;
  final String travelMode;
  final String specialRequest;
  final String status;
  final DateTime createdAt;

  HotelRequest({
    required this.id,
    required this.userId,
    required this.checkIn,
    required this.checkOut,
    required this.location,
    required this.isInternational,
    required this.nights,
    required this.members,
    required this.travelMode,
    required this.specialRequest,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "checkIn": checkIn,
    "checkOut": checkOut,
    "location": location,
    "isInternational": isInternational,
    "nights": nights,
    "members": members,
    "travelMode": travelMode,
    "specialRequest": specialRequest,
    "status": status,
    "createdAt": createdAt,
  };

  factory HotelRequest.fromJson(Map<String, dynamic> json) {
    return HotelRequest(
      id: json["id"],
      userId: json["userId"],
      checkIn: (json["checkIn"] as Timestamp).toDate(),
      checkOut: (json["checkOut"] as Timestamp).toDate(),
      location: json["location"],
      isInternational: json["isInternational"],
      nights: json["nights"],
      members: json["members"],
      travelMode: json["travelMode"],
      specialRequest: json["specialRequest"],
      status: json["status"],
      createdAt: (json["createdAt"] as Timestamp).toDate(),
    );
  }
}
