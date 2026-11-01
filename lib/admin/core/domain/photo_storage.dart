import 'picked_image.dart';

/// Uploads photos and returns their public download URL.
abstract class PhotoStorage {
  /// Replaces the artist's profile photo.
  Future<String> uploadArtistProfile(String artistId, PickedImage image);
}
