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
///
/// The stream has no value for a moment after launch, even when a saved
/// session is being restored. Reading only the stream at that moment would
/// wrongly say "nobody is logged in", so until it delivers we ask the auth
/// repository directly, which already knows.
final currentUserIdProvider = Provider<String?>((ref) {
  final fromStream = ref.watch(authStateProvider);
  if (fromStream.hasValue) return fromStream.value?.uid;
  return ref.read(authRepositoryProvider).currentUserId;
});
