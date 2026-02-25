import 'package:cloud_firestore/cloud_firestore.dart';

class UserDocument {
  final String id;
  final String userId;
  final String requestId;
  final String fileUrl;
  final String type;
  final String title;
  final DateTime createdAt;

  UserDocument({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.fileUrl,
    required this.type,
    required this.title,
    required this.createdAt,
  });

  /// 🔥 FROM FIRESTORE
  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAtRaw = data['createdAt'];

    return UserDocument(
      id: doc.id,
      userId: data['userId'] ?? '',
      requestId: data['requestId'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : DateTime.now(),
    );
  }

  /// 🔥 TO JSON (ADD THIS)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'requestId': requestId,
      'fileUrl': fileUrl,
      'type': type,
      'title': title,
      'createdAt': createdAt,
    };
  }
}
