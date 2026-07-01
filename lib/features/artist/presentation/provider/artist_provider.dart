import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasource/artist_datasource.dart';
import '../../domain/entity/artist.dart';

/// 🔥 Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// 🔥 Datasource provider (dependency injection)
final artistDatasourceProvider = Provider<ArtistDatasource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ArtistDatasource(firestore: firestore);
});

/// 🔥 Artist list provider (main provider)
final artistProvider = FutureProvider<List<Artist>>((ref) async {
  final datasource = ref.watch(artistDatasourceProvider);

  final result = await datasource.getArtists();

  return result; // Model extends Entity → safe return
});
