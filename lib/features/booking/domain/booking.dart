import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

/// requested -> confirmed | declined (by artist); requested/confirmed ->
/// cancelled (by customer or artist); confirmed -> completed (after service).
enum BookingStatus { requested, confirmed, declined, cancelled, completed }

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
