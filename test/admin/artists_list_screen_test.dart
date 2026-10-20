import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/core/domain/picked_image.dart';
import 'package:makeup_booking_app/admin/core/theme/admin_theme.dart';
import 'package:makeup_booking_app/admin/features/artists/domain/admin_artist_repository.dart';
import 'package:makeup_booking_app/admin/features/artists/domain/artist_draft.dart';
import 'package:makeup_booking_app/admin/features/artists/presentation/provider/admin_artist_providers.dart';
import 'package:makeup_booking_app/admin/features/artists/presentation/screen/artists_list_screen.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

Artist _artist(String id, String name, String city, {bool active = true}) {
  return Artist(
    id: id,
    name: name,
    bio: '',
    city: city,
    imageUrl: '',
    rating: 0,
    reviewCount: 0,
    serviceModes: ServiceMode.values,
    services: const [
      ArtistService(id: 's', name: 'Bridal', price: 4500, durationMinutes: 120),
    ],
    isActive: active,
  );
}

class _FakeRepository implements AdminArtistRepository {
  final List<Artist> artists;
  final List<(String, bool)> activations = [];

  _FakeRepository(this.artists);

  @override
  Stream<List<Artist>> watchArtists() => Stream.value(artists);

  @override
  Future<void> setActive(String artistId, {required bool isActive}) async {
    activations.add((artistId, isActive));
  }

  @override
  Future<ArtistEditorData?> getEditorData(String artistId) =>
      throw UnimplementedError();

  @override
  Future<String> saveArtist({
    String? artistId,
    required ArtistDraft draft,
    PickedImage? profilePhoto,
  }) =>
      throw UnimplementedError();
}

Future<_FakeRepository> _pump(WidgetTester tester, List<Artist> artists) async {
  final repository = _FakeRepository(artists);
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminArtistRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AdminTheme.light,
        home: const Scaffold(body: ArtistsListScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists every artist with its city', (tester) async {
    await _pump(tester, [
      _artist('1', 'Priya', 'Kochi'),
      _artist('2', 'Anjali', 'Chennai', active: false),
    ]);

    expect(find.text('Priya'), findsOneWidget);
    expect(find.text('Anjali'), findsOneWidget);
    expect(find.text('Kochi'), findsOneWidget);
    expect(find.text('2 in total'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('search narrows by name or city', (tester) async {
    await _pump(tester, [
      _artist('1', 'Priya', 'Kochi'),
      _artist('2', 'Anjali', 'Chennai'),
    ]);

    await tester.enterText(find.byType(TextField), 'chen');
    await tester.pumpAndSettle();

    expect(find.text('Anjali'), findsOneWidget);
    expect(find.text('Priya'), findsNothing);
  });

  testWidgets('shows an empty state when nothing matches', (tester) async {
    await _pump(tester, [_artist('1', 'Priya', 'Kochi')]);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No artists match your search.'), findsOneWidget);
  });

  testWidgets('the switch hides an artist from customers', (tester) async {
    final repository = await _pump(tester, [_artist('1', 'Priya', 'Kochi')]);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repository.activations, [('1', false)]);
  });
}
