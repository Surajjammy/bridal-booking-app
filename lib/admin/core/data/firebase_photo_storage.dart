import 'package:firebase_storage/firebase_storage.dart';

import '../domain/photo_storage.dart';
import '../domain/picked_image.dart';

class FirebasePhotoStorage implements PhotoStorage {
  final FirebaseStorage _storage;

  FirebasePhotoStorage(this._storage);

  @override
  Future<String> uploadArtistProfile(String artistId, PickedImage image) async {
    // A timestamped name means a replaced photo gets a new URL, so browsers
    // and the customer app's image cache never show the old one.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('artists/$artistId/profile_$stamp.jpg');

    await ref.putData(
      image.bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }
}
