import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<QueryDocumentSnapshot?> validateUID({
    required String customUid,
    required String phone,
  }) async {
    final cleanPhone = phone.replaceAll("+91", "").trim();

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('customUid', isEqualTo: customUid.trim())
        .where('phone', isEqualTo: cleanPhone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first;
  }

  Future<void> updateUserDetails({
    required String name,
    required String email,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final query = await _firestore
        .collection('users')
        .where(
          'phone',
          isEqualTo: firebaseUser.phoneNumber?.replaceAll("+91", ""),
        )
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final docId = query.docs.first.id;

    await _firestore.collection('users').doc(docId).update({
      'name': name,
      'email': email,
      'isFirstLogin': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
