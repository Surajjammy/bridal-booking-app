import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/artist/presentation/provider/artist_provider.dart';
import 'package:makeup_booking_app/features/auth/presentation/provider/auth_provider.dart';

import '../../data/booking_repository.dart';
import '../../domain/booking.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(firestoreProvider));
});

typedef SlotQuery = ({String artistId, DateTime day});

final bookedSlotsProvider =
    FutureProvider.autoDispose.family<Set<DateTime>, SlotQuery>((ref, query) {
  return ref
      .watch(bookingRepositoryProvider)
      .getBookedSlots(query.artistId, query.day);
});

final userBookingsProvider =
    StreamProvider.autoDispose<List<Booking>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(bookingRepositoryProvider).watchUserBookings(uid);
});
