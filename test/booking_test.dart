import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';

Booking _booking({
  required BookingStatus status,
  required DateTime startAt,
}) =>
    Booking(
      id: 'b1',
      artistId: 'a1',
      artistName: 'Test',
      serviceName: 'Bridal',
      mode: ServiceMode.studio,
      address: null,
      startAt: startAt,
      amount: 1000,
      status: status,
    );

void main() {
  final future = DateTime.now().add(const Duration(days: 2));
  final past = DateTime.now().subtract(const Duration(days: 2));

  group('Booking.canCancel', () {
    test('allowed for upcoming requested and confirmed bookings', () {
      expect(
        _booking(status: BookingStatus.requested, startAt: future).canCancel,
        isTrue,
      );
      expect(
        _booking(status: BookingStatus.confirmed, startAt: future).canCancel,
        isTrue,
      );
    });

    test('not allowed once the time has passed', () {
      expect(
        _booking(status: BookingStatus.confirmed, startAt: past).canCancel,
        isFalse,
      );
    });

    test('not allowed for declined, cancelled or completed bookings', () {
      for (final status in [
        BookingStatus.declined,
        BookingStatus.cancelled,
        BookingStatus.completed,
      ]) {
        expect(_booking(status: status, startAt: future).canCancel, isFalse);
      }
    });
  });
}
