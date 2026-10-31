import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/booking/domain/booking_quote.dart';
import 'package:makeup_booking_app/features/booking/domain/cancellation_policy.dart';

const _haircut = ArtistService(
  id: 'cut',
  name: 'Haircut',
  price: 800,
  durationMinutes: 60,
);
const _massage = ArtistService(
  id: 'massage',
  name: 'Head massage',
  price: 300,
  durationMinutes: 30,
  kind: ServiceKind.addOn,
);
const _family = ArtistService(
  id: 'family',
  name: 'Family member makeup',
  price: 2500,
  durationMinutes: 45,
  kind: ServiceKind.addOn,
  maxQuantity: 3,
);

const _artist = Artist(
  id: 'a1',
  name: 'Priya',
  bio: '',
  city: '',
  imageUrl: '',
  rating: 0,
  reviewCount: 0,
  serviceModes: ServiceMode.values,
  services: [_haircut, _massage, _family],
  isActive: true,
  bufferMinutes: 15,
  travelBufferMinutes: 60,
);

BookingQuote _quote({
  List<SelectedAddOn> addOns = const [],
  ServiceMode mode = ServiceMode.studio,
}) {
  return BookingQuote(
    artist: _artist,
    mainService: _haircut,
    addOns: addOns,
    mode: mode,
  );
}

void main() {
  group('BookingQuote', () {
    test('a plain booking is just the main service', () {
      final quote = _quote();
      expect(quote.durationMinutes, 60);
      expect(quote.totalPrice, 800);
      expect(quote.summary, 'Haircut');
    });

    test('add-ons add their time and price, times the quantity', () {
      final quote = _quote(addOns: const [
        SelectedAddOn(_massage, 1),
        SelectedAddOn(_family, 2),
      ]);

      expect(quote.durationMinutes, 60 + 30 + 2 * 45);
      expect(quote.totalPrice, 800 + 300 + 2 * 2500);
      expect(quote.summary, 'Haircut + 2 add-ons');
      expect(quote.items.where((i) => i.isAddOn), hasLength(2));
    });

    test('an add-on with quantity zero is ignored', () {
      final quote = _quote(addOns: const [SelectedAddOn(_massage, 0)]);
      expect(quote.durationMinutes, 60);
      expect(quote.summary, 'Haircut');
    });

    test('the buffer depends on where the service happens', () {
      expect(_quote(mode: ServiceMode.studio).bufferMinutes, 15);
      expect(_quote(mode: ServiceMode.home).bufferMinutes, 60);
    });

    test('blocked time rounds up to whole steps', () {
      // 60 + 15 = 75 minutes -> three 30 minute steps -> 90 minutes.
      final start = DateTime(2026, 10, 19, 12);
      final quote = _quote();
      expect(quote.blockedUntil(start), DateTime(2026, 10, 19, 13, 30));
      expect(quote.endAt(start), DateTime(2026, 10, 19, 13));
    });
  });

  group('CancellationPolicy.refundShare', () {
    final start = DateTime(2026, 11, 20, 12);

    double refund(Duration before, {bool byArtist = false}) {
      return CancellationPolicy.refundShare(
        startAt: start,
        cancelledAt: start.subtract(before),
        cancelledByArtist: byArtist,
      );
    }

    test('full refund 7 days or more before', () {
      expect(refund(const Duration(days: 10)), 1);
      expect(refund(const Duration(days: 7)), 1);
    });

    test('half refund between 7 days and 48 hours before', () {
      expect(refund(const Duration(days: 6, hours: 23)), 0.5);
      expect(refund(const Duration(days: 3)), 0.5);
      expect(refund(const Duration(hours: 48)), 0.5);
    });

    test('no refund within 48 hours, or after the start', () {
      expect(refund(const Duration(hours: 47, minutes: 59)), 0);
      expect(refund(const Duration(hours: 2)), 0);
      expect(refund(const Duration(hours: -1)), 0);
    });

    test('the artist cancelling always refunds everything', () {
      expect(refund(const Duration(hours: 1), byArtist: true), 1);
    });
  });
}
