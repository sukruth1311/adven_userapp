import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  final String id;
  final String userId;
  final String serviceType;
  final String status;
  final Map<String, dynamic> details;
  final String adminNotes;
  final String confirmationDocUrl;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  ServiceRequest({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.status,
    required this.details,
    required this.adminNotes,
    required this.confirmationDocUrl,
    this.createdAt,
    this.approvedAt,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ServiceRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      status: data['status'] ?? 'pending',
      details: Map<String, dynamic>.from(data['details'] ?? {}),
      adminNotes: data['adminNotes'] ?? '',
      confirmationDocUrl: data['confirmationDocUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
