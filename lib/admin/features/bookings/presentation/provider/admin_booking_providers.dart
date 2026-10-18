import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/providers/clock_provider.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';

import '../../data/firestore_admin_booking_repository.dart';
import '../../domain/admin_booking_repository.dart';
import '../../domain/booking_filter.dart';

final adminBookingRepositoryProvider = Provider<AdminBookingRepository>((ref) {
  return FirestoreAdminBookingRepository(FirebaseFirestore.instance);
});

final adminBookingsProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(adminBookingRepositoryProvider).watchBookings();
});

class BookingFilterController extends Notifier<BookingFilter> {
  @override
  BookingFilter build() => BookingFilter.needsAction;

  void select(BookingFilter filter) => state = filter;
}

final bookingFilterProvider =
    NotifierProvider<BookingFilterController, BookingFilter>(
  BookingFilterController.new,
);

class BookingSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final bookingSearchQueryProvider =
    NotifierProvider<BookingSearchQuery, String>(BookingSearchQuery.new);

/// How many bookings sit under each tab, so the tabs can show a count.
final bookingCountsProvider = Provider<Map<BookingFilter, int>>((ref) {
  final bookings = ref.watch(adminBookingsProvider).value ?? const <Booking>[];
  final now = ref.watch(clockProvider)();

  return {
    for (final filter in BookingFilter.values)
      filter: bookings.where((b) => filter.matches(b, now)).length,
  };
});

/// The bookings for the chosen tab, narrowed by the search box (artist or
/// service) and ordered sensibly for that tab.
final visibleBookingsProvider = Provider<AsyncValue<List<Booking>>>((ref) {
  final filter = ref.watch(bookingFilterProvider);
  final query = ref.watch(bookingSearchQueryProvider).trim().toLowerCase();
  final now = ref.watch(clockProvider)();

  return ref.watch(adminBookingsProvider).whenData((bookings) {
    final matching = bookings.where((b) {
      if (!filter.matches(b, now)) return false;
      if (query.isEmpty) return true;
      return b.artistName.toLowerCase().contains(query) ||
          b.serviceName.toLowerCase().contains(query);
    }).toList();

    matching.sort(
      (a, b) => filter.soonestFirst
          ? a.startAt.compareTo(b.startAt)
          : b.startAt.compareTo(a.startAt),
    );
    return matching;
  });
});

/// Looked up once per customer and kept, so a long list does not re-read.
final customerPhoneProvider =
    FutureProvider.family<String?, String>((ref, userId) {
  return ref.watch(adminBookingRepositoryProvider).getCustomerPhone(userId);
});

/// Status changes. Returns whether it worked and leaves any failure in
/// [state] for the screen to show.
class BookingAdminController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> changeStatus(Booking booking, BookingStatus to) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminBookingRepositoryProvider).changeStatus(booking, to),
    );
    return !state.hasError;
  }
}

final bookingAdminControllerProvider =
    AsyncNotifierProvider<BookingAdminController, void>(
  BookingAdminController.new,
);
