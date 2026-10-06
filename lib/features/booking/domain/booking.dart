import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

/// requested -> confirmed | declined (by artist); requested/confirmed ->
/// cancelled (by customer or artist); confirmed -> completed (after service).
enum BookingStatus { requested, confirmed, declined, cancelled, completed }

class Booking {
  final String id;
  final String artistId;
  final String artistName;
  final String serviceName;
  final ServiceMode mode;
  final String? address;
  final DateTime startAt;
  final double amount;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.serviceName,
    required this.mode,
    required this.address,
    required this.startAt,
    required this.amount,
    required this.status,
  });

  /// Customers can cancel until the service has happened.
  bool get canCancel =>
      (status == BookingStatus.requested ||
          status == BookingStatus.confirmed) &&
      startAt.isAfter(DateTime.now());
}

class BookingRequest {
  final String userId;
  final Artist artist;
  final ArtistService service;
  final ServiceMode mode;
  final String? address;
  final DateTime startAt;

  const BookingRequest({
    required this.userId,
    required this.artist,
    required this.service,
    required this.mode,
    required this.address,
    required this.startAt,
  });
}

class SlotUnavailableException implements Exception {
  const SlotUnavailableException();

  @override
  String toString() => 'That time slot was just booked. Please pick another.';
}
