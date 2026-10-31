import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/artist.dart';

/// Single place that knows how an [Artist] is stored in Firestore. Both the
/// customer app (reads) and the admin panel (writes) go through it.
class ArtistModel {
  static Artist fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data() ?? {});
  }

  /// Parses an `artists/{id}` document. Tolerates the original prototype
  /// schema (`image`, `price`, string-only `services`) and documents written
  /// before availability existed, so old data keeps loading.
  static Artist fromMap(String id, Map<String, dynamic> map) {
    final legacyPrice = (map['price'] as num?)?.toDouble() ?? 0;

    final services = <ArtistService>[];
    final rawServices = map['services'] as List<dynamic>? ?? [];
    for (var i = 0; i < rawServices.length; i++) {
      final raw = rawServices[i];
      if (raw is Map) {
        services.add(_serviceFromMap(raw, i, legacyPrice));
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

    final hours = map['workingHours'];

    return Artist(
      id: id,
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
      workingHours: hours is Map
          ? WorkingHours(
              startMinute: (hours['startMinute'] as num?)?.toInt() ??
                  WorkingHours.standard.startMinute,
              endMinute: (hours['endMinute'] as num?)?.toInt() ??
                  WorkingHours.standard.endMinute,
            )
          : WorkingHours.standard,
      weeklyOffDays: (map['weeklyOffDays'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toSet(),
      bufferMinutes: (map['bufferMinutes'] as num?)?.toInt() ??
          Artist.defaultBufferMinutes,
      travelBufferMinutes: (map['travelBufferMinutes'] as num?)?.toInt() ??
          Artist.defaultTravelBufferMinutes,
    );
  }

  static ArtistService _serviceFromMap(Map raw, int index, double legacyPrice) {
    return ArtistService(
      id: (raw['id'] ?? 'svc$index').toString(),
      name: (raw['name'] ?? '').toString(),
      price: (raw['price'] as num?)?.toDouble() ?? legacyPrice,
      durationMinutes: (raw['durationMinutes'] as num?)?.toInt() ?? 120,
      kind: ServiceKind.fromName(raw['kind']?.toString()),
      maxQuantity: (raw['maxQuantity'] as num?)?.toInt() ?? 1,
      allowOnSpot: raw['allowOnSpot'] as bool? ?? true,
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
      'workingHours': {
        'startMinute': artist.workingHours.startMinute,
        'endMinute': artist.workingHours.endMinute,
      },
      'weeklyOffDays': artist.weeklyOffDays.toList()..sort(),
      'bufferMinutes': artist.bufferMinutes,
      'travelBufferMinutes': artist.travelBufferMinutes,
    };
  }

  static Map<String, dynamic> serviceToMap(ArtistService service) {
    return {
      'id': service.id,
      'name': service.name,
      'price': service.price,
      'durationMinutes': service.durationMinutes,
      'kind': service.kind.name,
      'maxQuantity': service.maxQuantity,
      'allowOnSpot': service.allowOnSpot,
    };
  }
}
