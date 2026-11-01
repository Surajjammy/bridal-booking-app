import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/features/bookings/domain/booking_filter.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';
import 'package:makeup_booking_app/features/booking/domain/booking_transitions.dart';

final _now = DateTime(2026, 10, 19, 12);

Booking _booking(
  BookingStatus status, {
  Duration startsIn = const Duration(days: 2),
  Duration lasts = const Duration(hours: 2),
}) {
  final start = _now.add(startsIn);
  return Booking(
    id: 'b',
    userId: 'u',
    artistId: 'a',
    artistName: 'Priya',
    serviceName: 'Bridal',
    mode: ServiceMode.studio,
    address: null,
    startAt: start,
    endAt: start.add(lasts),
    blockedUntil: start.add(lasts + const Duration(minutes: 30)),
    amount: 10000,
    commissionRate: 0.15,
    status: status,
  );
}

void main() {
  group('BookingTransitions.adminActions', () {
    test('a future request can be confirmed or declined', () {
      expect(
        BookingTransitions.adminActions(_booking(BookingStatus.requested), _now),
        [BookingStatus.confirmed, BookingStatus.declined],
      );
    });

    test('a request whose time has passed can only be declined', () {
      final stale = _booking(
        BookingStatus.requested,
        startsIn: const Duration(days: -1),
      );
      expect(
        BookingTransitions.adminActions(stale, _now),
        [BookingStatus.declined],
      );
    });

    test('a confirmed booking can be cancelled, and completed only after it ends',
        () {
      final upcoming = _booking(BookingStatus.confirmed);
      expect(
        BookingTransitions.adminActions(upcoming, _now),
        [BookingStatus.cancelled],
      );

      final finished = _booking(
        BookingStatus.confirmed,
        startsIn: const Duration(hours: -5),
      );
      expect(
        BookingTransitions.adminActions(finished, _now),
        [BookingStatus.completed, BookingStatus.cancelled],
      );
    });

    test('finished bookings offer nothing further', () {
      for (final status in [
        BookingStatus.declined,
        BookingStatus.cancelled,
        BookingStatus.completed,
      ]) {
        expect(BookingTransitions.adminActions(_booking(status), _now), isEmpty);
      }
    });

    test('isAllowed rejects a jump the rules do not permit', () {
      final requested = _booking(BookingStatus.requested);
      expect(
        BookingTransitions.isAllowed(requested, BookingStatus.completed, _now),
        isFalse,
      );
      expect(
        BookingTransitions.isAllowed(requested, BookingStatus.confirmed, _now),
        isTrue,
      );
    });
  });

  group('BookingTransitions.freesCalendar', () {
    test('only declining and cancelling give the time back', () {
      expect(BookingTransitions.freesCalendar(BookingStatus.declined), isTrue);
      expect(BookingTransitions.freesCalendar(BookingStatus.cancelled), isTrue);
      expect(BookingTransitions.freesCalendar(BookingStatus.confirmed), isFalse);
      expect(BookingTransitions.freesCalendar(BookingStatus.completed), isFalse);
    });
  });

  group('BookingFilter', () {
    final requested = _booking(BookingStatus.requested);
    final upcoming = _booking(BookingStatus.confirmed);
    final finishedConfirmed = _booking(
      BookingStatus.confirmed,
      startsIn: const Duration(hours: -5),
    );
    final completed = _booking(BookingStatus.completed);
    final declined = _booking(BookingStatus.declined);
    final cancelled = _booking(BookingStatus.cancelled);

    List<Booking> pick(BookingFilter filter) => [
          requested,
          upcoming,
          finishedConfirmed,
          completed,
          declined,
          cancelled,
        ].where((b) => filter.matches(b, _now)).toList();

    test('needs action is only open requests', () {
      expect(pick(BookingFilter.needsAction), [requested]);
    });

    test('upcoming is confirmed bookings that have not ended', () {
      expect(pick(BookingFilter.upcoming), [upcoming]);
    });

    test('past is completed, plus confirmed ones that already ended', () {
      expect(pick(BookingFilter.past), [finishedConfirmed, completed]);
    });

    test('closed is declined and cancelled', () {
      expect(pick(BookingFilter.closed), [declined, cancelled]);
    });

    test('all matches everything', () {
      expect(pick(BookingFilter.all), hasLength(6));
    });
  });

  test('commission is the amount times the rate recorded on the booking', () {
    expect(_booking(BookingStatus.requested).commission, 1500);
  });
}
