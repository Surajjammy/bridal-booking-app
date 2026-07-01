import 'package:makeup_booking_app/features/portfolio/data/portfolio_model.dart';

import '../../domain/entity/artist.dart';

class ArtistModel extends Artist {
  const ArtistModel({
    required super.name,
    required super.price,
    required super.rating,
    required super.image,
    required super.services,
    required super.portfolio,
  });

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      rating: (map['rating'] as num).toDouble(),
      image: map['image'] ?? '',
      services: List<String>.from(map['services'] ?? []).toList(),
      portfolio: (map['portfolio'] as List<dynamic>?)
              ?.map(
                (e) => PortfolioModel.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
    );
  }
}
