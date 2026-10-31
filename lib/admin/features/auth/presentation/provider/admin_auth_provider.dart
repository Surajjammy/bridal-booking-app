import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firebase_admin_auth_repository.dart';
import '../../domain/admin_auth_repository.dart';

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) {
  return FirebaseAdminAuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final adminUserProvider = StreamProvider<AdminUser?>((ref) {
  return ref.watch(adminAuthRepositoryProvider).watchUser();
});

/// Combines "who is signed in" with "are they on the admins list". The
/// router and every screen decide access from this one provider.
final adminAccessProvider = FutureProvider<AdminAccess>((ref) async {
  final user = await ref.watch(adminUserProvider.future);
  if (user == null) return AdminAccess.signedOut;

  final isAdmin = await ref.watch(adminAuthRepositoryProvider).isAdmin(user.uid);
  return isAdmin ? AdminAccess.admin : AdminAccess.notAdmin;
});

class AdminSignInController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(adminAuthRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }
}

final adminSignInControllerProvider =
    AsyncNotifierProvider<AdminSignInController, void>(
  AdminSignInController.new,
);
