// import 'package:cloud_firestore/cloud_firestore.dart';

// class HotelRequest {
//   final String id;
//   final String userId;
//   final DateTime checkIn;
//   final DateTime checkOut;
//   final String location;
//   final bool isInternational;
//   final int nights;
//   final int members;
//   final String travelMode;
//   final String specialRequest;
//   final String status;
//   final DateTime createdAt;

//   HotelRequest({
//     required this.id,
//     required this.userId,
//     required this.checkIn,
//     required this.checkOut,
//     required this.location,
//     required this.isInternational,
//     required this.nights,
//     required this.members,
//     required this.travelMode,
//     required this.specialRequest,
//     required this.status,
//     required this.createdAt,
//   });

//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "userId": userId,
//     "checkIn": checkIn,
//     "checkOut": checkOut,
//     "location": location,
//     "isInternational": isInternational,
//     "nights": nights,
//     "members": members,
//     "travelMode": travelMode,
//     "specialRequest": specialRequest,
//     "status": status,
//     "createdAt": createdAt,
//   };

//   factory HotelRequest.fromJson(Map<String, dynamic> json) {
//     return HotelRequest(
//       id: json["id"],
//       userId: json["userId"],
//       checkIn: (json["checkIn"] as Timestamp).toDate(),
//       checkOut: (json["checkOut"] as Timestamp).toDate(),
//       location: json["location"],
//       isInternational: json["isInternational"],
//       nights: json["nights"],
//       members: json["members"],
//       travelMode: json["travelMode"],
//       specialRequest: json["specialRequest"],
//       status: json["status"],
//       createdAt: (json["createdAt"] as Timestamp).toDate(),
//     );
//   }
// }
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

  // Holiday-specific fields
  final String subDestination;
  final String memberName;
  final int totalDays;
  final int adults;
  final int kids;
  final DateTime? travelDate;
  final String? aadharUrl;

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
    this.subDestination = '',
    this.memberName = '',
    this.totalDays = 0,
    this.adults = 1,
    this.kids = 0,
    this.travelDate,
    this.aadharUrl,
  });

  // 🔥 FROM FIRESTORE (SAFE VERSION)
  factory HotelRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HotelRequest(
      id: doc.id,
      userId: data['userId'] ?? '',

      checkIn: data['checkIn'] != null
          ? (data['checkIn'] as Timestamp).toDate()
          : DateTime.now(),

      checkOut: data['checkOut'] != null
          ? (data['checkOut'] as Timestamp).toDate()
          : DateTime.now(),

      location: data['location'] ?? '',
      isInternational: data['isInternational'] ?? false,
      nights: data['nights'] ?? 0,
      members: data['members'] ?? 0,
      travelMode: data['travelMode'] ?? '',
      specialRequest: data['specialRequest'] ?? '',
      status: data['status'] ?? 'pending',

      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),

      subDestination: data['subDestination'] ?? '',
      memberName: data['memberName'] ?? '',
      totalDays: data['totalDays'] ?? 0,
      adults: data['adults'] ?? 1,
      kids: data['kids'] ?? 0,

      travelDate: data['travelDate'] != null
          ? (data['travelDate'] as Timestamp).toDate()
          : null,

      aadharUrl: data['aadharUrl'],
    );
  }

  // 🔥 TO FIRESTORE (PROPER TIMESTAMP CONVERSION)
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'checkIn': Timestamp.fromDate(checkIn),
    'checkOut': Timestamp.fromDate(checkOut),
    'location': location,
    'isInternational': isInternational,
    'nights': nights,
    'members': members,
    'travelMode': travelMode,
    'specialRequest': specialRequest,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'subDestination': subDestination,
    'memberName': memberName,
    'totalDays': totalDays,
    'adults': adults,
    'kids': kids,
    'travelDate': travelDate != null ? Timestamp.fromDate(travelDate!) : null,
    'aadharUrl': aadharUrl,
  };
}
