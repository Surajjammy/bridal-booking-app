import 'package:makeup_booking_app/features/booking/domain/booking.dart';

/// Thrown when a booking was changed by someone else (the customer cancelling,
/// another admin) after the admin loaded it.
class BookingChangedException implements Exception {
  const BookingChangedException();

  @override
  String toString() =>
      'This booking was just changed by someone else. The list has been '
      'refreshed, please check it and try again.';
}

abstract class AdminBookingRepository {
  /// The most recent bookings, newest first, kept live.
  Stream<List<Booking>> watchBookings();

  /// Moves [booking] to [to] if the rules allow it. Declining or cancelling
  /// also frees the artist's calendar, in the same step. Throws
  /// [BookingChangedException] if the booking is no longer in the state the
  /// admin saw.
  Future<void> changeStatus(Booking booking, BookingStatus to);

  /// The customer's phone number from their profile, or null if unknown.
  Future<String?> getCustomerPhone(String userId);
}
