import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import 'booking_quote.dart';

/// requested -> confirmed | declined (by artist); requested/confirmed ->
/// cancelled (by customer or artist); confirmed -> completed (after service).
enum BookingStatus { requested, confirmed, declined, cancelled, completed }

class Booking {
  final String id;

  /// The customer who made the booking.
  final String userId;
  final String artistId;
  final String artistName;

  /// Short label such as "Bridal makeup + 2 add-ons".
  final String serviceName;
  final ServiceMode mode;
  final String? address;
  final DateTime startAt;

  /// When the service itself finishes.
  final DateTime endAt;

  /// When the artist is free again: [endAt] plus the buffer, in whole steps.
  /// The calendar is locked from [startAt] until here.
  final DateTime blockedUntil;
  final double amount;

  /// Platform share in force when the booking was made (0.15 = 15%).
  final double commissionRate;
  final BookingStatus status;

  /// When the request was made; null only while the server timestamp is
  /// still being written.
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.artistId,
    required this.artistName,
    required this.serviceName,
    required this.mode,
    required this.address,
    required this.startAt,
    required this.endAt,
    required this.blockedUntil,
    required this.amount,
    this.commissionRate = 0,
    required this.status,
    this.createdAt,
  });

  /// What the platform keeps from this booking.
  double get commission => amount * commissionRate;

  /// Customers can cancel until the service has happened.
  bool get canCancel =>
      (status == BookingStatus.requested ||
          status == BookingStatus.confirmed) &&
      startAt.isAfter(DateTime.now());
}

class BookingRequest {
  final String userId;
  final BookingQuote quote;
  final String? address;
  final DateTime startAt;

  const BookingRequest({
    required this.userId,
    required this.quote,
    required this.address,
    required this.startAt,
  });
}

class SlotUnavailableException implements Exception {
  const SlotUnavailableException();

  @override
  String toString() => 'That time was just booked. Please pick another.';
}
