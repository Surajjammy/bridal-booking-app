import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../core/domain/picked_image.dart';
import 'artist_draft.dart';

abstract class AdminArtistRepository {
  /// Every artist, active or not, kept live.
  Stream<List<Artist>> watchArtists();

  /// Null when the artist no longer exists.
  Future<ArtistEditorData?> getEditorData(String artistId);

  /// Creates a new artist (with its provider) when [artistId] is null,
  /// otherwise updates the existing one. A new artist needs [profilePhoto].
  /// Returns the artist's id.
  Future<String> saveArtist({
    String? artistId,
    required ArtistDraft draft,
    PickedImage? profilePhoto,
  });

  /// Shows or hides an artist in the customer app. Nothing is deleted.
  Future<void> setActive(String artistId, {required bool isActive});
}
