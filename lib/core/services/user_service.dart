import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:user_app/core/services/auth_service.dart';
import 'package:user_app/core/services/firestore_service.dart';
import 'package:user_app/data/models/app_user.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final AuthService _auth = AuthService.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  // ==========================================================
  // 🚀 REGISTER USER (Production Ready)
  // ==========================================================

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // 1️⃣ Create Firebase Auth user
      final firebaseUser = await _auth.signUpWithEmail(
        email.trim(),
        password.trim(),
      );

      final uid = firebaseUser.uid;

      // 2️⃣ Prepare Firestore user model
      final appUser = AppUser(
        id: uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: "user", // 🔥 default role
        isMember: false,
        membershipId: null,
        membershipName: null,
        expiryDate: null,
        immunities: {},
        phone: phone,
        profileImage: null,
      );

      // 3️⃣ Save to Firestore
      await _firestore.createUser(appUser);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? "Registration failed");
    } catch (e) {
      throw Exception("Something went wrong. Try again.");
    }
  }

  // ==========================================================
  // 👤 GET CURRENT APP USER
  // ==========================================================

  Future<AppUser?> getCurrentAppUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    return await _firestore.getUser(uid);
  }

  // ==========================================================
  // 🔄 SYNC AUTH USER WITH FIRESTORE (Safety Layer)
  // ==========================================================

  Future<void> ensureUserDocumentExists() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final existing = await _firestore.getUser(firebaseUser.uid);

    if (existing == null) {
      final newUser = AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? "User",
        email: firebaseUser.email ?? "",
        role: "user",
        isMember: false,
        membershipId: null,
        membershipName: null,
        expiryDate: null,
        immunities: {},
        phone: null,
        profileImage: null,
      );

      await _firestore.createUser(newUser);
    }
  }
}
