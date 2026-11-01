import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../../core/data/firebase_photo_storage.dart';
import '../../../../core/data/image_picker_service.dart';
import '../../../../core/domain/picked_image.dart';
import '../../data/firestore_admin_artist_repository.dart';
import '../../domain/admin_artist_repository.dart';
import '../../domain/artist_draft.dart';

final adminArtistRepositoryProvider = Provider<AdminArtistRepository>((ref) {
  return FirestoreAdminArtistRepository(
    FirebaseFirestore.instance,
    FirebasePhotoStorage(FirebaseStorage.instance),
  );
});

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

final adminArtistsProvider = StreamProvider<List<Artist>>((ref) {
  return ref.watch(adminArtistRepositoryProvider).watchArtists();
});

class ArtistSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final artistSearchQueryProvider =
    NotifierProvider<ArtistSearchQuery, String>(ArtistSearchQuery.new);

/// The artist list narrowed by the search box (name or city).
final filteredAdminArtistsProvider = Provider<AsyncValue<List<Artist>>>((ref) {
  final query = ref.watch(artistSearchQueryProvider).trim().toLowerCase();

  return ref.watch(adminArtistsProvider).whenData((artists) {
    if (query.isEmpty) return artists;
    return artists
        .where((a) =>
            a.name.toLowerCase().contains(query) ||
            a.city.toLowerCase().contains(query))
        .toList();
  });
});

final artistEditorDataProvider =
    FutureProvider.autoDispose.family<ArtistEditorData?, String>((ref, id) {
  return ref.watch(adminArtistRepositoryProvider).getEditorData(id);
});

/// Writes from the artist screens. Each method returns whether it worked, and
/// leaves the failure in [state] for the screen to show.
class ArtistAdminController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    String? artistId,
    required ArtistDraft draft,
    PickedImage? profilePhoto,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminArtistRepositoryProvider).saveArtist(
            artistId: artistId,
            draft: draft,
            profilePhoto: profilePhoto,
          ),
    );
    if (artistId != null) ref.invalidate(artistEditorDataProvider(artistId));
    return !state.hasError;
  }

  Future<bool> setActive(String artistId, {required bool isActive}) async {
    state = await AsyncValue.guard(
      () => ref
          .read(adminArtistRepositoryProvider)
          .setActive(artistId, isActive: isActive),
    );
    return !state.hasError;
  }
}

final artistAdminControllerProvider =
    AsyncNotifierProvider<ArtistAdminController, void>(
  ArtistAdminController.new,
);
