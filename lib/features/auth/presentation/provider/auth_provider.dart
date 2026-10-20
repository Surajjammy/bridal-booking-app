import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/artist/presentation/provider/artist_provider.dart';

import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, ref.watch(firestoreProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in user's uid, or null when logged out.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});
