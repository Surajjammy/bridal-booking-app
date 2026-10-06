import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Starts phone verification for an E.164 number such as `+919876543210`.
  ///
  /// [onCodeSent] fires when the SMS is on its way. On some Android devices
  /// Firebase reads the SMS itself and signs in without the user typing the
  /// code; that path calls [onAutoSignedIn] instead.
  Future<void> sendOtp({
    required String phoneNumber,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onFailed,
    required void Function() onAutoSignedIn,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          await _ensureProfile(result.user!);
          onAutoSignedIn();
        } on FirebaseAuthException catch (e) {
          onFailed(_message(e));
        }
      },
      verificationFailed: (e) => onFailed(_message(e)),
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      await _ensureProfile(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Creates `users/{uid}` on first login; later logins leave it untouched.
  Future<void> _ensureProfile(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) return;
    await ref.set({
      'phone': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'That phone number looks invalid.';
      case 'invalid-verification-code':
        return 'Incorrect code. Please check and try again.';
      case 'session-expired':
        return 'The code has expired. Please request a new one.';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'Too many attempts. Please wait a while and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return "Couldn't verify your number. Please try again.";
    }
  }
}
