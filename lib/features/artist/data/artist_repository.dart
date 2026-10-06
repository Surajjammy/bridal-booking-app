import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/features/portfolio/data/portfolio_model.dart';
import 'package:makeup_booking_app/features/portfolio/domain/portfolio_entity.dart';

import '../domain/entity/artist.dart';
import 'model/artist_model.dart';

class ArtistRepository {
  final FirebaseFirestore _firestore;

  ArtistRepository(this._firestore);

  /// Active artists only; admins deactivate an artist instead of deleting it.
  ///
  /// TODO: once every artist doc has `isActive`, filter in the query
  /// (`.where('isActive', isEqualTo: true)`) and have the rules require it.
  /// Filtering client-side for now because prototype docs lack the field.
  Future<List<Artist>> getArtists() async {
    final snapshot = await _firestore.collection('artists').get();
    return snapshot.docs
        .map(ArtistModel.fromDoc)
        .where((artist) => artist.isActive)
        .toList();
  }

  Future<List<PortfolioEntity>> getPortfolio(String artistId) async {
    final snapshot = await _firestore
        .collection('artists')
        .doc(artistId)
        .collection('portfolio')
        .get();
    return snapshot.docs.map(PortfolioModel.fromDoc).toList();
  }
}
