import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/artist/presentation/provider/artist_provider.dart';

import '../../data/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(firestoreProvider));
});

/// TEMPORARY: there is no login yet, so every booking is attributed to this
/// placeholder. Replace with the Firebase Auth uid when phone login lands.
final currentUserIdProvider = Provider<String>((ref) => 'dev-user');

typedef SlotQuery = ({String artistId, DateTime day});

final bookedSlotsProvider =
    FutureProvider.autoDispose.family<Set<DateTime>, SlotQuery>((ref, query) {
  return ref
      .watch(bookingRepositoryProvider)
      .getBookedSlots(query.artistId, query.day);
});
