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
  /// Filtered in the query, as the security rules require. Prototype
  /// documents without `isActive` are therefore hidden until re-entered
  /// through the admin panel.
  Future<List<Artist>> getArtists() async {
    final snapshot = await _firestore
        .collection('artists')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.map(ArtistModel.fromDoc).toList();
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
