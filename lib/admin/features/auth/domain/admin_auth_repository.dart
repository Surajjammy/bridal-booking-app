class AdminUser {
  final String uid;
  final String email;

  const AdminUser({required this.uid, required this.email});
}

/// What the signed-in person is allowed to do in the panel.
enum AdminAccess { signedOut, notAdmin, admin }

class AdminAuthFailure implements Exception {
  final String message;
  const AdminAuthFailure(this.message);

  @override
  String toString() => message;
}

abstract class AdminAuthRepository {
  /// Emits the signed-in user, or null when signed out.
  Stream<AdminUser?> watchUser();

  /// True when [uid] is listed in the `admins` collection.
  Future<bool> isAdmin(String uid);

  /// Throws [AdminAuthFailure] with a user-readable message.
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}
