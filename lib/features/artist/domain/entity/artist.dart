/// Where the service is delivered. Artists can offer one or both.
enum ServiceMode {
  home('Home visit'),
  studio('Studio');

  final String label;
  const ServiceMode(this.label);

  static ServiceMode? fromName(String? name) {
    for (final mode in values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}

class ArtistService {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;

  const ArtistService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
  });
}

class Artist {
  final String id;
  final String name;
  final String bio;
  final String city;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final List<ServiceMode> serviceModes;
  final List<ArtistService> services;
  final bool isActive;

  const Artist({
    required this.id,
    required this.name,
    required this.bio,
    required this.city,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.serviceModes,
    required this.services,
    required this.isActive,
  });

  /// Lowest service price, shown on list cards as "From ₹X".
  double? get startingPrice {
    if (services.isEmpty) return null;
    return services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
  }
}
