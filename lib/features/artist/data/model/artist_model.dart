import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/artist.dart';

/// Single place that knows how an [Artist] is stored in Firestore. Both the
/// customer app (reads) and the admin panel (writes) go through it.
class ArtistModel {
  /// Parses an `artists/{id}` document. Tolerates the original prototype
  /// schema (`image`, `price`, string-only `services`) so old documents keep
  /// loading.
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
      providerId: (map['providerId'] ?? '').toString(),
    );
  }

  /// The fields an admin edits. `rating` and `reviewCount` are deliberately
  /// excluded: they are maintained by the review system, and writing them
  /// here would overwrite it.
  static Map<String, dynamic> toEditableMap(Artist artist) {
    return {
      'name': artist.name,
      'bio': artist.bio,
      'city': artist.city,
      'imageUrl': artist.imageUrl,
      'serviceModes': artist.serviceModes.map((m) => m.name).toList(),
      'services': artist.services.map(serviceToMap).toList(),
      'isActive': artist.isActive,
      'providerId': artist.providerId,
    };
  }

  static Map<String, dynamic> serviceToMap(ArtistService service) {
    return {
      'id': service.id,
      'name': service.name,
      'price': service.price,
      'durationMinutes': service.durationMinutes,
    };
  }
}
