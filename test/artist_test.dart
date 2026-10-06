import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

Artist _artist(List<ArtistService> services) => Artist(
      id: 'a1',
      name: 'Test',
      bio: '',
      city: '',
      imageUrl: '',
      rating: 0,
      reviewCount: 0,
      serviceModes: ServiceMode.values,
      services: services,
      isActive: true,
    );

void main() {
  group('Artist.startingPrice', () {
    test('is the lowest service price', () {
      final artist = _artist(const [
        ArtistService(id: '1', name: 'Bridal', price: 15000, durationMinutes: 180),
        ArtistService(id: '2', name: 'Party', price: 4500, durationMinutes: 90),
      ]);
      expect(artist.startingPrice, 4500);
    });

    test('is null without services', () {
      expect(_artist(const []).startingPrice, isNull);
    });
  });

  group('formatters', () {
    test('formatRupees uses Indian grouping without decimals', () {
      expect(formatRupees(150000), '₹1,50,000');
      expect(formatRupees(1500.0), '₹1,500');
    });

    test('dateKey is sortable yyyyMMdd', () {
      expect(dateKey(DateTime(2026, 10, 6, 14)), '20261006');
    });
  });
}
