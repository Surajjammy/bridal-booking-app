import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

/// Admin-only details about an artist. Stored apart from the public artist
/// document, so customers can never read them.
class ArtistPrivateDetails {
  final String contactPhone;
  final String instagram;
  final String notes;

  const ArtistPrivateDetails({
    this.contactPhone = '',
    this.instagram = '',
    this.notes = '',
  });
}

/// Everything the admin enters in the artist form.
class ArtistDraft {
  final String name;
  final String bio;
  final String city;
  final Set<ServiceMode> serviceModes;
  final List<ArtistService> services;
  final bool isActive;

  /// Share of each booking kept by the platform, as a fraction (0.15 = 15%).
  final double commissionRate;
  final ArtistPrivateDetails privateDetails;

  const ArtistDraft({
    required this.name,
    required this.bio,
    required this.city,
    required this.serviceModes,
    required this.services,
    required this.isActive,
    required this.commissionRate,
    required this.privateDetails,
  });

  /// Builds the public [Artist]. System-managed fields (rating, review count)
  /// are not part of a draft.
  Artist toArtist({
    required String id,
    required String imageUrl,
    required String providerId,
  }) {
    return Artist(
      id: id,
      name: name.trim(),
      bio: bio.trim(),
      city: city.trim(),
      imageUrl: imageUrl,
      rating: 0,
      reviewCount: 0,
      serviceModes: serviceModes.toList(),
      services: services,
      isActive: isActive,
      providerId: providerId,
    );
  }
}

/// An existing artist loaded for editing.
class ArtistEditorData {
  final Artist artist;
  final ArtistPrivateDetails privateDetails;
  final double commissionRate;

  const ArtistEditorData({
    required this.artist,
    required this.privateDetails,
    required this.commissionRate,
  });
}
