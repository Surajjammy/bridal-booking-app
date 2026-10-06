import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/portfolio/domain/portfolio_entity.dart';

import '../../data/artist_repository.dart';
import '../../domain/entity/artist.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepository(ref.watch(firestoreProvider));
});

final artistsProvider = FutureProvider<List<Artist>>((ref) {
  return ref.watch(artistRepositoryProvider).getArtists();
});

final portfolioProvider =
    FutureProvider.family<List<PortfolioEntity>, String>((ref, artistId) {
  return ref.watch(artistRepositoryProvider).getPortfolio(artistId);
});
