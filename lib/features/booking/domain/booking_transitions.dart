import 'booking.dart';

/// Which status changes are allowed. One rulebook for the admin panel today
/// and the artist app later.
///
///   requested -> confirmed | declined
///   confirmed -> completed (once the service has finished) | cancelled
///   declined, cancelled, completed -> nothing further
class BookingTransitions {
  BookingTransitions._();

  /// What an admin can do next with [booking] at [now].
  static List<BookingStatus> adminActions(Booking booking, DateTime now) {
    switch (booking.status) {
      case BookingStatus.requested:
        return [
          // A request whose time has passed can only be turned down.
          if (booking.startAt.isAfter(now)) BookingStatus.confirmed,
          BookingStatus.declined,
        ];
      case BookingStatus.confirmed:
        return [
          if (!now.isBefore(booking.endAt)) BookingStatus.completed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.declined:
      case BookingStatus.cancelled:
      case BookingStatus.completed:
        return const [];
    }
  }

  static bool isAllowed(Booking booking, BookingStatus to, DateTime now) =>
      adminActions(booking, now).contains(to);

  /// Declining or cancelling gives the artist's time back; the other changes
  /// keep it locked.
  static bool freesCalendar(BookingStatus to) =>
      to == BookingStatus.declined || to == BookingStatus.cancelled;
}
