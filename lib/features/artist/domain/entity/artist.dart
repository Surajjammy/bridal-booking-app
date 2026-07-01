import 'package:makeup_booking_app/features/portfolio/domain/portfolio_entity.dart';

class Artist {
  final String name;
  final double price;
  final double rating;
  final String image;
  final List<String> services;
  final List<PortfolioEntity> portfolio;

  const Artist({
    required this.name,
    required this.price,
    required this.rating,
    required this.image,
    required this.services,
    required this.portfolio,
  });
}
