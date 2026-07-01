import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/features/portfolio/data/data_source/portfolio_datasource.dart'
    show PortfolioDatasource;
import 'package:makeup_booking_app/features/portfolio/data/portfolio_repository.dart';

final portfolioProvider = FutureProvider.family((ref, String artistId) async {
  final datasource = PortfolioDatasource(
    FirebaseFirestore.instance,
  );

  final repository = PortfolioRepositoryImpl(datasource);
  return repository.getPortfolio(artistId);
});
