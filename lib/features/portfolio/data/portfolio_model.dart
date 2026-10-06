import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/portfolio_entity.dart';

class PortfolioModel {
  /// Parses an `artists/{artistId}/portfolio/{id}` document.
  static PortfolioEntity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return PortfolioEntity(
      id: doc.id,
      imageUrl: (map['imageUrl'] ?? map['image'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
    );
  }
}
