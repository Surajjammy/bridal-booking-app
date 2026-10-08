import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/core/constants/firestore_paths.dart';
import 'package:makeup_booking_app/features/artist/data/model/artist_model.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../core/domain/photo_storage.dart';
import '../../../core/domain/picked_image.dart';
import '../domain/admin_artist_repository.dart';
import '../domain/artist_draft.dart';

class ArtistSaveFailure implements Exception {
  final String message;
  const ArtistSaveFailure(this.message);

  @override
  String toString() => message;
}

class FirestoreAdminArtistRepository implements AdminArtistRepository {
  /// Phase 1 only onboards individual artists. Salons come later and reuse
  /// the same `providers` collection with another type.
  static const String _individualProviderType = 'individual';

  final FirebaseFirestore _firestore;
  final PhotoStorage _photoStorage;

  FirestoreAdminArtistRepository(this._firestore, this._photoStorage);

  CollectionReference<Map<String, dynamic>> get _artists =>
      _firestore.collection(FirestorePaths.artists);
  CollectionReference<Map<String, dynamic>> get _providers =>
      _firestore.collection(FirestorePaths.providers);
  CollectionReference<Map<String, dynamic>> get _private =>
      _firestore.collection(FirestorePaths.artistPrivate);

  @override
  Stream<List<Artist>> watchArtists() {
    return _artists
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ArtistModel.fromDoc).toList());
  }

  @override
  Future<ArtistEditorData?> getEditorData(String artistId) async {
    final artistDoc = await _artists.doc(artistId).get();
    if (!artistDoc.exists) return null;
    final artist = ArtistModel.fromDoc(artistDoc);

    final privateDoc = await _private.doc(artistId).get();
    final privateMap = privateDoc.data() ?? {};

    var commissionRate = AppConfig.commissionRate;
    if (artist.providerId.isNotEmpty) {
      final providerDoc = await _providers.doc(artist.providerId).get();
      commissionRate =
          (providerDoc.data()?['commissionRate'] as num?)?.toDouble() ??
              commissionRate;
    }

    return ArtistEditorData(
      artist: artist,
      privateDetails: ArtistPrivateDetails(
        contactPhone: (privateMap['contactPhone'] ?? '').toString(),
        instagram: (privateMap['instagram'] ?? '').toString(),
        notes: (privateMap['notes'] ?? '').toString(),
      ),
      commissionRate: commissionRate,
    );
  }

  @override
  Future<String> saveArtist({
    String? artistId,
    required ArtistDraft draft,
    PickedImage? profilePhoto,
  }) async {
    final artistRef = artistId == null ? _artists.doc() : _artists.doc(artistId);
    final existing = artistId == null
        ? null
        : ArtistModel.fromDoc(await artistRef.get());

    if (existing == null && profilePhoto == null) {
      throw const ArtistSaveFailure('A profile photo is required.');
    }

    // Upload first: if it fails nothing has been written, so no artist is
    // left without a photo.
    final imageUrl = profilePhoto != null
        ? await _photoStorage.uploadArtistProfile(artistRef.id, profilePhoto)
        : existing!.imageUrl;

    final hasProvider = existing != null && existing.providerId.isNotEmpty;
    final providerRef = hasProvider
        ? _providers.doc(existing.providerId)
        : _providers.doc();

    final artist = draft.toArtist(
      id: artistRef.id,
      imageUrl: imageUrl,
      providerId: providerRef.id,
    );
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();

    if (existing == null) {
      batch.set(artistRef, {
        ...ArtistModel.toEditableMap(artist),
        'rating': 0,
        'reviewCount': 0,
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      batch.update(artistRef, {
        ...ArtistModel.toEditableMap(artist),
        'updatedAt': now,
      });
    }

    batch.set(
      providerRef,
      {
        'type': _individualProviderType,
        'name': artist.name,
        'city': artist.city,
        'commissionRate': draft.commissionRate,
        if (!hasProvider) 'createdAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    batch.set(
      _private.doc(artistRef.id),
      {
        'contactPhone': draft.privateDetails.contactPhone.trim(),
        'instagram':
            draft.privateDetails.instagram.trim().replaceFirst('@', ''),
        'notes': draft.privateDetails.notes.trim(),
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return artistRef.id;
  }

  @override
  Future<void> setActive(String artistId, {required bool isActive}) {
    return _artists.doc(artistId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
