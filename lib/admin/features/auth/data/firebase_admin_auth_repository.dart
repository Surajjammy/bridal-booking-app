import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/admin_auth_repository.dart';

class FirebaseAdminAuthRepository implements AdminAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAdminAuthRepository(this._auth, this._firestore);

  @override
  Stream<AdminUser?> watchUser() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AdminUser(uid: user.uid, email: user.email ?? '');
    });
  }

  @override
  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('admins').doc(uid).get();
    return doc.exists;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AdminAuthFailure(_message(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      // Deliberately one message for unknown email and wrong password, so the
      // form never reveals which admin emails exist.
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a while and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this project.';
      default:
        debugPrint('Unhandled FirebaseAuthException: ${e.code} ${e.message}');
        return "Couldn't sign you in. Please try again.";
    }
  }
}
