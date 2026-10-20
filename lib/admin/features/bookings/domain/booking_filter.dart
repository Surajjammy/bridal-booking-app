import 'package:makeup_booking_app/features/booking/domain/booking.dart';

/// The tabs on the admin Bookings page.
enum BookingFilter {
  needsAction('Needs action'),
  upcoming('Upcoming'),
  past('Past'),
  closed('Declined or cancelled'),
  all('All');

  final String label;
  const BookingFilter(this.label);

  bool matches(Booking booking, DateTime now) {
    switch (this) {
      case BookingFilter.needsAction:
        return booking.status == BookingStatus.requested;
      case BookingFilter.upcoming:
        return booking.status == BookingStatus.confirmed &&
            booking.endAt.isAfter(now);
      case BookingFilter.past:
        return booking.status == BookingStatus.completed ||
            (booking.status == BookingStatus.confirmed &&
                !booking.endAt.isAfter(now));
      case BookingFilter.closed:
        return booking.status == BookingStatus.declined ||
            booking.status == BookingStatus.cancelled;
      case BookingFilter.all:
        return true;
    }
  }

  /// Soonest first for things still to come or to be dealt with, newest first
  /// for history.
  bool get soonestFirst =>
      this == BookingFilter.needsAction || this == BookingFilter.upcoming;
}
