import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/features/artists/domain/artist_draft.dart';
import 'package:makeup_booking_app/features/artist/data/model/artist_model.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

ArtistDraft _draft() => const ArtistDraft(
      name: '  Priya  ',
      bio: ' Bridal specialist ',
      city: ' Kochi ',
      serviceModes: {ServiceMode.home, ServiceMode.studio},
      services: [
        ArtistService(
          id: 's1',
          name: 'Bridal',
          price: 15000,
          durationMinutes: 180,
        ),
      ],
      isActive: true,
      commissionRate: 0.15,
      privateDetails: ArtistPrivateDetails(contactPhone: '9876543210'),
    );

void main() {
  group('ArtistDraft.toArtist', () {
    test('trims text and carries ids', () {
      final artist = _draft().toArtist(
        id: 'a1',
        imageUrl: 'https://example.com/p.jpg',
        providerId: 'p1',
      );

      expect(artist.name, 'Priya');
      expect(artist.bio, 'Bridal specialist');
      expect(artist.city, 'Kochi');
      expect(artist.id, 'a1');
      expect(artist.providerId, 'p1');
      expect(artist.serviceModes, hasLength(2));
    });
  });

  group('ArtistModel.toEditableMap', () {
    final artist = _draft().toArtist(
      id: 'a1',
      imageUrl: 'https://example.com/p.jpg',
      providerId: 'p1',
    );
    final map = ArtistModel.toEditableMap(artist);

    test('leaves system-managed fields out', () {
      expect(map.containsKey('rating'), isFalse);
      expect(map.containsKey('reviewCount'), isFalse);
    });

    test('stores modes by name and services as maps', () {
      expect(map['serviceModes'], containsAll(['home', 'studio']));
      expect(map['services'], [
        {'id': 's1', 'name': 'Bridal', 'price': 15000.0, 'durationMinutes': 180},
      ]);
      expect(map['providerId'], 'p1');
      expect(map['isActive'], isTrue);
    });
  });
}
