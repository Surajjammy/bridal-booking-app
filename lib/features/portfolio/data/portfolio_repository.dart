import 'package:makeup_booking_app/features/portfolio/data/data_source/portfolio_datasource.dart';
import 'package:makeup_booking_app/features/portfolio/domain/portfolio_entity.dart';

abstract class PortfolioRepository {
  Future<List<PortfolioEntity>> getPortfolio(String artistId);
}

class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioDatasource datasource;

  PortfolioRepositoryImpl(this.datasource);

  @override
  Future<List<PortfolioEntity>> getPortfolio(String artistId) {
    return datasource.getPortfolio(artistId);
  }
}
