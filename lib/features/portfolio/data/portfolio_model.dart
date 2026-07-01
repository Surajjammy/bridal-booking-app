import 'package:makeup_booking_app/features/portfolio/domain/portfolio_entity.dart';

class PortfolioModel extends PortfolioEntity {
  PortfolioModel({
    required super.id,
    required super.image,
    required super.title,
    required super.category,
  });

  factory PortfolioModel.fromMap(Map<String, dynamic> map) {
    return PortfolioModel(
        image: map['image'] ?? '',
        title: map['title'] ?? '',
        category: map['category'] ?? '',
        id: map['id'] ?? '');
  }
}
