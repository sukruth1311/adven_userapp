import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:user_app/data/models/app_user.dart';
import 'package:user_app/data/models/document_file.dart';
import 'package:user_app/data/models/hotel_request.dart';
import 'package:user_app/data/models/membership.dart';
import 'package:user_app/data/models/membership_plan.dart';
import 'package:user_app/data/models/membership_request.dart';
import 'package:user_app/data/models/offer.dart';
import 'package:user_app/data/models/package_request.dart';
import 'package:user_app/data/models/review.dart';
import 'package:user_app/data/models/service_request.dart';
import 'package:user_app/data/models/user_document.dart';

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // 👤 USERS
  // ==========================================================

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  Future<AppUser?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();

    if (!doc.exists || doc.data() == null) return null;

    return AppUser.fromJson({
      'id': doc.id, // 🔥 always safe
      ...doc.data()!,
    });
  }

  Future<void> createServiceRequest({
    required String serviceType,
    required Map<String, dynamic> details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) throw Exception("User not logged in");

    await FirebaseFirestore.instance.collection('service_requests').add({
      "userId": user.uid,
      "serviceType": serviceType,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "details": details,
      "adminNotes": "",
      "confirmationDocUrl": "",
      "approvedAt": null,
    });
  }

  Stream<QuerySnapshot> streamUserServiceRequests(String userId) {
    return _firestore
        .collection('service_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateImmunities(
    String userId,
    Map<String, bool> immunities,
  ) async {
    await _db.collection('users').doc(userId).update({
      'immunities': immunities,
    });
  }

  Future<void> updateMembershipStatus(String userId, bool isMember) async {
    await _db.collection('users').doc(userId).update({'isMember': isMember});
  }

  Future<void> createAdminUser({
    required String firebaseUid,
    required String customUid,
    required String name,
    required String phone,
    required String email,
    required String role,
  }) async {
    await _db.collection("users").doc(firebaseUid).set({
      "customUid": customUid,
      "name": name,
      "phone": phone,
      "email": email,
      "role": role,
      "membershipApproved": false,
      "membershipPackage": null,
      "expiryDate": null,
      "immunities": {},
      "usageLimits": {},
      "createdByAdmin": true,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // 💳 MEMBERSHIP PLANS
  // ==========================================================

  Stream<List<MembershipPlan>> streamMembershipPlans() {
    return _db.collection('membership_plans').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MembershipPlan.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> createHolidayRequest({
    required String userId,
    required String destination,
    required String subDestination,
    required int totalDays,
    required int members,
    required String memberName,
    required DateTime travelDate,
    required File aadharFile,
  }) async {
    try {
      // 🔹 1. Upload Aadhaar file to Firebase Storage
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_aadhar";
      final ref = FirebaseStorage.instance.ref().child(
        "holiday_aadhar/$fileName",
      );

      await ref.putFile(aadharFile);

      final downloadUrl = await ref.getDownloadURL();

      // 🔹 2. Save request in Firestore
      await FirebaseFirestore.instance.collection("service_requests").add({
        "userId": userId,
        "serviceType": "holiday",
        "destination": destination,
        "subDestination": subDestination,
        "totalDays": totalDays,
        "members": members,
        "memberName": memberName,
        "travelDate": travelDate,
        "aadharUrl": downloadUrl,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to create holiday request: $e");
    }
  }

  // ==========================================================
  // 📩 MEMBERSHIP REQUESTS
  // ==========================================================

  Future<void> allocateMembership({
    required String userId,
    required String membershipName,
    required String membershipId,
    required DateTime expiryDate,
    required Map<String, bool> immunities,
    String? packageRequestId,
    String? requestId,
  }) async {
    // 1️⃣ Update user
    await _db.collection('users').doc(userId).update({
      "isMember": true,
      "membershipId": membershipId,
      "membershipName": membershipName,
      "expiryDate": expiryDate,
      "immunities": immunities,
    });

    // 2️⃣ Only update request if provided
    if (requestId != null) {
      final doc = await _db
          .collection('membership_requests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        await doc.reference.update({'status': 'approved'});
      }
    }
  }

  Stream<List<MembershipRequest>> streamUserPendingMembershipRequests(
    String userId,
  ) {
    return _db
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MembershipRequest.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> createMembershipRequest(MembershipRequest request) async {
    await _db
        .collection('membership_requests')
        .doc(request.id)
        .set(request.toJson());
  }

  Stream<List<MembershipRequest>> streamMembershipRequests() {
    return _db
        .collection('membership_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MembershipRequest.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<MembershipRequest>> streamUserMembershipRequests(String userId) {
    return _db
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MembershipRequest.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> approveMembership({
    required String userId,
    required String requestId,
    required String membershipId,
    required Map<String, bool> immunities,
  }) async {
    await _db.collection('users').doc(userId).update({
      'isMember': true,
      'membershipId': membershipId,
      'immunities': immunities,
    });

    await _db.collection('membership_requests').doc(requestId).update({
      'status': 'approved',
    });
  }

  // ==========================================================
  // 🏨 HOTEL REQUESTS
  // ==========================================================

  Future<void> createHotelRequest(HotelRequest request) async {
    await _db
        .collection('hotel_requests')
        .doc(request.id)
        .set(request.toJson());
  }

  Future<void> updateHotelRequestStatus(String id, String status) async {
    await _db.collection("hotel_requests").doc(id).update({"status": status});
  }

  Stream<List<HotelRequest>> streamAllHotelRequests() {
    return _db
        .collection('hotel_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HotelRequest.fromJson(doc.data()))
              .toList();
        });
  }

  Stream<List<HotelRequest>> streamUserHotelRequests(String userId) {
    return _db
        .collection('hotel_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HotelRequest.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> uploadHotelConfirmation({
    required String userId,
    required String hotelRequestId,
    required File file,
  }) async {
    final ref = _storage.ref().child(
      'hotel_documents/$userId/$hotelRequestId.pdf',
    );

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await _db.collection('hotel_documents').add({
      'userId': userId,
      'hotelRequestId': hotelRequestId,
      'fileUrl': url,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamUserHotelDocuments(String userId) {
    return _db
        .collection('hotel_documents')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((e) => e.data()).toList());
  }

  // ==========================================================
  // 📄 USER DOCUMENTS (Hotel Confirmation, Insurance, etc.)
  // ==========================================================

  Future<void> createUserDocument(UserDocument doc) async {
    await _db.collection('user_documents').doc(doc.id).set(doc.toJson());
  }

  Future<void> uploadUserDocument({
    required String userId,
    required String requestId,
    required String type, // hotel / holiday / membership
    required String title,
    required File file,
  }) async {
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.pdf";

    final ref = _storage.ref().child('user_documents/$userId/$fileName');

    // 1️⃣ Upload to storage
    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    // 2️⃣ Save Firestore entry (THIS is what screen reads)
    await _db.collection('user_documents').add({
      'userId': userId,
      'requestId': requestId,
      'fileUrl': url,
      'type': type,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserMembership({
    required String userId,
    required String membershipName,
    required String membershipId,
    required DateTime expiryDate,
    required Map<String, bool> immunities,
  }) async {
    await _db.collection('users').doc(userId).update({
      'isMember': true,
      'membershipName': membershipName,
      'membershipId': membershipId,
      'expiryDate': expiryDate.toIso8601String(),
      'immunities': immunities,
    });
  }

  Future<void> cancelMembership(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isMember': false,
      'membershipName': null,
      'membershipId': null,
      'expiryDate': null,
      'immunities': {},
    });
  }

  Stream<List<UserDocument>> streamUserDocuments(String userId) {
    return _db
        .collection('user_documents')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final firestoreDocs = snapshot.docs
              .map((doc) => UserDocument.fromFirestore(doc))
              .toList();

          if (firestoreDocs.isNotEmpty) {
            return firestoreDocs;
          }

          final resolvedFolderIds = await _resolveUserFolderIds(userId);
          return _listUserDocumentsFromStorageFolders(resolvedFolderIds);
        });
  }

  Future<Set<String>> _resolveUserFolderIds(String firebaseUid) async {
    final ids = <String>{firebaseUid};

    QueryDocumentSnapshot<Map<String, dynamic>>? userDoc;

    final byFirebaseUid = await _db
        .collection('users')
        .where('firebaseUid', isEqualTo: firebaseUid)
        .limit(1)
        .get();
    if (byFirebaseUid.docs.isNotEmpty) {
      userDoc = byFirebaseUid.docs.first;
    }

    if (userDoc == null) {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        final digitsOnly = phone.replaceAll('+91', '').trim();
        final byPhone = await _db
            .collection('users')
            .where('phone', isEqualTo: digitsOnly)
            .limit(1)
            .get();
        if (byPhone.docs.isNotEmpty) {
          userDoc = byPhone.docs.first;
        }
      }
    }

    if (userDoc != null) {
      ids.add(userDoc.id);
      final customUid = userDoc.data()['customUid'];
      if (customUid is String && customUid.isNotEmpty) {
        ids.add(customUid);
      }
    }

    return ids;
  }

  Future<List<UserDocument>> _listUserDocumentsFromStorageFolders(
    Set<String> folderIds,
  ) async {
    final docs = <UserDocument>[];
    final seenIds = <String>{};
    const baseFolders = ['user_documents', 'user_document'];

    for (final folderId in folderIds) {
      for (final baseFolder in baseFolders) {
        try {
          final userFolderRef = _storage.ref().child('$baseFolder/$folderId');
          final files = await _collectAllFiles(userFolderRef);
          if (files.isEmpty) continue;

          final folderDocs = await Future.wait(
            files.map((fileRef) async {
              final url = await fileRef.getDownloadURL();

              FullMetadata? metadata;
              try {
                metadata = await fileRef.getMetadata();
              } catch (_) {}

              final name = fileRef.name;
              final dotIndex = name.lastIndexOf('.');
              final type = dotIndex >= 0 && dotIndex < name.length - 1
                  ? name.substring(dotIndex + 1).toLowerCase()
                  : 'file';

              return UserDocument(
                id: fileRef.fullPath,
                userId: folderId,
                requestId: '',
                fileUrl: url,
                type: type,
                title: name,
                createdAt:
                    metadata?.timeCreated ??
                    metadata?.updated ??
                    DateTime.now(),
              );
            }),
          );

          for (final doc in folderDocs) {
            if (seenIds.add(doc.id)) {
              docs.add(doc);
            }
          }
        } on FirebaseException catch (_) {
          continue;
        }
      }
    }

    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }

  Future<List<Reference>> _collectAllFiles(Reference folderRef) async {
    final result = await folderRef.listAll();
    final files = List<Reference>.from(result.items);

    for (final childFolder in result.prefixes) {
      files.addAll(await _collectAllFiles(childFolder));
    }

    return files;
  }

  Future<void> deleteUserDocument(String documentId) async {
    await _db.collection('user_documents').doc(documentId).delete();
  }

  // ==========================================================
  // 📄 PUBLIC DOCUMENTS
  // ==========================================================

  Future<void> uploadDocument(DocumentFile document) async {
    await _db.collection('documents').doc(document.id).set(document.toJson());
  }

  Stream<List<DocumentFile>> streamPublicDocuments() {
    return _db
        .collection('documents')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DocumentFile.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> deleteDocument(String documentId) async {
    await _db.collection('documents').doc(documentId).delete();
  }

  // ==========================================================
  // 👥 ADMIN - STREAM ALL USERS
  // ==========================================================

  Stream<List<AppUser>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // ==========================================================
  // ⭐ REVIEWS
  // ==========================================================

  Future<void> createReview(Review review) async {
    await _db.collection('reviews').doc(review.id).set(review.toJson());
  }

  Stream<List<Review>> streamPendingReviews() {
    return _db
        .collection('reviews')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> approveReview(String reviewId) async {
    await _db.collection('reviews').doc(reviewId).update({'isApproved': true});
  }

  // ==========================================================
  // 🎁 OFFERS
  // ==========================================================

  Future<void> createOffer(Offer offer) async {
    await _db.collection('offers').doc(offer.id).set(offer.toJson());
  }

  Stream<List<Offer>> streamActiveOffers() {
    return _db
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Offer.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> deactivateOffer(String offerId) async {
    await _db.collection('offers').doc(offerId).update({'isActive': false});
  }

  // ==========================================================
  // 🏷 MEMBERSHIP DETAILS (Optional Separate Collection)
  // ==========================================================

  Future<void> createMembership(Membership membership) async {
    await _db
        .collection('memberships')
        .doc(membership.id)
        .set(membership.toJson());
  }

  Future<Membership?> getMembership(String userId) async {
    final query = await _db
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return Membership.fromJson(query.docs.first.data());
  }

  // ===============================
  // GET USER HOLIDAY REQUESTS
  // ===============================
  Stream<List<QueryDocumentSnapshot>> streamUserHolidayHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('holiday_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // ===============================
  // CALCULATE TOTAL USED HOLIDAYS
  // ===============================
  Future<int> getUsedHolidayDays(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('holiday_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();

    int total = 0;

    for (var doc in snapshot.docs) {
      total += (doc['daysBooked'] ?? 0) as int;
    }

    return total;
  }

  //========================================================= packages ===============
  Future<void> createPackageRequest(Map<String, dynamic> data) async {
    await _db.collection('package_requests').doc(data["id"]).set(data);
  }

  Future<void> approvePackageRequest(String requestId) async {
    await _db.collection('package_requests').doc(requestId).update({
      'status': 'approved',
    });
  }

  Future<void> rejectPackageRequest(String requestId) async {
    await _db.collection('package_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Stream<List<PackageRequest>> streamPackageRequests() {
    return _db
        .collection('package_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PackageRequest.fromJson(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> updatePackageRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _db.collection('package_requests').doc(requestId).update({
      'status': status,
    });
  }

  Stream<List<ServiceRequest>> getUserRequests() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('service_requests')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceRequest.fromFirestore(doc))
              .toList(),
        );
  }
}
