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

/// A main service is what the customer books (bridal makeup, haircut). An
/// add-on is an extra offered alongside it (head massage, extra family member).
enum ServiceKind {
  main,
  addOn;

  static ServiceKind fromName(String? name) =>
      name == addOn.name ? addOn : main;
}

class ArtistService {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final ServiceKind kind;

  /// Add-ons only: the most of this add-on one booking can include
  /// (e.g. 3 extra family members).
  final int maxQuantity;

  /// Add-ons only: whether the artist can add it at the chair, after the
  /// booking was made. Some are only practical when planned ahead.
  final bool allowOnSpot;

  const ArtistService({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.kind = ServiceKind.main,
    this.maxQuantity = 1,
    this.allowOnSpot = true,
  });

  bool get isAddOn => kind == ServiceKind.addOn;
}

/// The hours an artist takes bookings, as minutes after midnight.
class WorkingHours {
  final int startMinute;
  final int endMinute;

  const WorkingHours({required this.startMinute, required this.endMinute});

  /// Used for artists who have not set their own hours yet.
  static const WorkingHours standard =
      WorkingHours(startMinute: 10 * 60, endMinute: 18 * 60);
}

class Artist {
  /// Gap kept free after every studio booking, for overruns and set-up.
  static const int defaultBufferMinutes = 15;

  /// Gap kept after a home visit, which includes travel.
  static const int defaultTravelBufferMinutes = 60;

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

  /// The business that gets paid for this artist's bookings. For an
  /// individual artist it is a provider with a single artist.
  final String providerId;

  final WorkingHours workingHours;

  /// Weekdays the artist does not work, using [DateTime.weekday] (Monday = 1).
  final Set<int> weeklyOffDays;
  final int bufferMinutes;
  final int travelBufferMinutes;

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
    this.providerId = '',
    this.workingHours = WorkingHours.standard,
    this.weeklyOffDays = const {},
    this.bufferMinutes = defaultBufferMinutes,
    this.travelBufferMinutes = defaultTravelBufferMinutes,
  });

  List<ArtistService> get mainServices =>
      services.where((s) => !s.isAddOn).toList();

  List<ArtistService> get addOns => services.where((s) => s.isAddOn).toList();

  /// Time kept free after a booking delivered in [mode].
  int bufferFor(ServiceMode mode) =>
      mode == ServiceMode.home ? travelBufferMinutes : bufferMinutes;

  /// Lowest main-service price, shown on list cards as "From ₹X".
  double? get startingPrice {
    final main = mainServices;
    if (main.isEmpty) return null;
    return main.map((s) => s.price).reduce((a, b) => a < b ? a : b);
  }
}
