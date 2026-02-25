import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userDataProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return const Stream.empty();
      }

      return FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: user.phoneNumber?.replaceAll("+91", ""))
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return null; // 🔥 prevents crash
            }
            return snapshot.docs.first;
          });
    });
