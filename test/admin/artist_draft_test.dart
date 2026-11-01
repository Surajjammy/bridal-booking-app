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
        ArtistService(
          id: 's2',
          name: 'Family member makeup',
          price: 2500,
          durationMinutes: 45,
          kind: ServiceKind.addOn,
          maxQuantity: 3,
          allowOnSpot: false,
        ),
      ],
      isActive: true,
      workingHours: WorkingHours(startMinute: 5 * 60, endMinute: 21 * 60),
      weeklyOffDays: {DateTime.sunday},
      bufferMinutes: 20,
      travelBufferMinutes: 90,
      commissionRate: 0.15,
      repeatCommissionRate: 0.05,
      privateDetails: ArtistPrivateDetails(contactPhone: '9876543210'),
    );

Artist _artist() => _draft().toArtist(
      id: 'a1',
      imageUrl: 'https://example.com/p.jpg',
      providerId: 'p1',
    );

void main() {
  group('ArtistDraft.toArtist', () {
    test('trims text and carries ids', () {
      final artist = _artist();

      expect(artist.name, 'Priya');
      expect(artist.bio, 'Bridal specialist');
      expect(artist.city, 'Kochi');
      expect(artist.id, 'a1');
      expect(artist.providerId, 'p1');
      expect(artist.serviceModes, hasLength(2));
    });

    test('carries availability', () {
      final artist = _artist();

      expect(artist.workingHours.startMinute, 300);
      expect(artist.weeklyOffDays, {DateTime.sunday});
      expect(artist.bufferFor(ServiceMode.studio), 20);
      expect(artist.bufferFor(ServiceMode.home), 90);
    });

    test('separates services from add-ons', () {
      final artist = _artist();

      expect(artist.mainServices.map((s) => s.id), ['s1']);
      expect(artist.addOns.map((s) => s.id), ['s2']);
      expect(artist.startingPrice, 15000);
    });
  });

  group('ArtistModel.toEditableMap', () {
    final map = ArtistModel.toEditableMap(_artist());

    test('leaves system-managed fields out', () {
      expect(map.containsKey('rating'), isFalse);
      expect(map.containsKey('reviewCount'), isFalse);
    });

    test('stores modes by name and services as maps', () {
      expect(map['serviceModes'], containsAll(['home', 'studio']));
      expect(map['services'], [
        {
          'id': 's1',
          'name': 'Bridal',
          'price': 15000.0,
          'durationMinutes': 180,
          'kind': 'main',
          'maxQuantity': 1,
          'allowOnSpot': true,
        },
        {
          'id': 's2',
          'name': 'Family member makeup',
          'price': 2500.0,
          'durationMinutes': 45,
          'kind': 'addOn',
          'maxQuantity': 3,
          'allowOnSpot': false,
        },
      ]);
      expect(map['providerId'], 'p1');
      expect(map['isActive'], isTrue);
    });

    test('stores availability', () {
      expect(map['workingHours'], {'startMinute': 300, 'endMinute': 1260});
      expect(map['weeklyOffDays'], [DateTime.sunday]);
      expect(map['bufferMinutes'], 20);
      expect(map['travelBufferMinutes'], 90);
    });
  });

  group('ArtistModel.fromMap', () {
    test('round-trips what the admin saves', () {
      final original = _artist();
      final stored = ArtistModel.toEditableMap(original);

      final loaded = ArtistModel.fromMap('a1', stored);

      expect(loaded.name, original.name);
      expect(loaded.workingHours.endMinute, original.workingHours.endMinute);
      expect(loaded.weeklyOffDays, original.weeklyOffDays);
      expect(loaded.bufferMinutes, 20);
      expect(loaded.travelBufferMinutes, 90);
      expect(loaded.addOns.single.maxQuantity, 3);
      expect(loaded.addOns.single.allowOnSpot, isFalse);
      expect(loaded.mainServices.single.price, 15000);
    });

    test('documents saved before availability existed get sensible defaults',
        () {
      final loaded = ArtistModel.fromMap('old', {
        'name': 'Old artist',
        'services': [
          {'id': 's1', 'name': 'Bridal', 'price': 9000, 'durationMinutes': 120},
        ],
      });

      expect(loaded.workingHours.startMinute, 10 * 60);
      expect(loaded.workingHours.endMinute, 18 * 60);
      expect(loaded.weeklyOffDays, isEmpty);
      expect(loaded.bufferMinutes, Artist.defaultBufferMinutes);
      expect(loaded.travelBufferMinutes, Artist.defaultTravelBufferMinutes);
      expect(loaded.mainServices.single.kind, ServiceKind.main);
    });

    test('the very first prototype format still loads', () {
      final loaded = ArtistModel.fromMap('proto', {
        'name': 'Prototype',
        'price': 1500,
        'services': ['Bridal', 'Party'],
      });

      expect(loaded.mainServices, hasLength(2));
      expect(loaded.mainServices.first.price, 1500);
    });
  });
}
