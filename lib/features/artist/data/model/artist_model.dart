import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/artist.dart';

class ArtistModel {
  /// Parses an `artists/{id}` document. Tolerates the original prototype
  /// schema (`image`, `price`, string-only `services`) so existing dev data
  /// keeps loading while it is migrated through the admin panel.
  static Artist fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    final legacyPrice = (map['price'] as num?)?.toDouble() ?? 0;

    final services = <ArtistService>[];
    final rawServices = map['services'] as List<dynamic>? ?? [];
    for (var i = 0; i < rawServices.length; i++) {
      final raw = rawServices[i];
      if (raw is Map) {
        services.add(ArtistService(
          id: (raw['id'] ?? 'svc$i').toString(),
          name: (raw['name'] ?? '').toString(),
          price: (raw['price'] as num?)?.toDouble() ?? legacyPrice,
          durationMinutes: (raw['durationMinutes'] as num?)?.toInt() ?? 120,
        ));
      } else if (raw is String) {
        services.add(ArtistService(
          id: 'svc$i',
          name: raw,
          price: legacyPrice,
          durationMinutes: 120,
        ));
      }
    }

    final modes = (map['serviceModes'] as List<dynamic>? ?? [])
        .map((e) => ServiceMode.fromName(e?.toString()))
        .whereType<ServiceMode>()
        .toList();

    return Artist(
      id: doc.id,
      name: (map['name'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? map['image'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      serviceModes: modes.isEmpty ? ServiceMode.values : modes,
      services: services,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
