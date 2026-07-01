import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/artist_model.dart';

class ArtistDatasource {
  final FirebaseFirestore firestore;

  ArtistDatasource({required this.firestore});

  Future<List<ArtistModel>> getArtists() async {
    final snapshot = await firestore.collection('artists').get();

    return snapshot.docs
        .map((doc) => ArtistModel.fromMap(doc.data()))
        .toList();
  }
}