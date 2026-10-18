/// The default cancellation rule for every booking.
///
/// Free cancellation until 7 days before, a partial refund until 48 hours
/// before, nothing after that. If the artist cancels or declines, the customer
/// always gets everything back. This only calculates the share to refund;
/// money moves once online payments exist.
class CancellationPolicy {
  CancellationPolicy._();

  static const Duration fullRefundUntil = Duration(days: 7);
  static const Duration noRefundWithin = Duration(hours: 48);

  /// Share of the advance refunded between the two windows.
  static const double partialRefundShare = 0.5;

  /// Shown to the customer when they book.
  static const String summary =
      'Free cancellation until 7 days before. 50% refund up to 48 hours '
      'before. No refund after that. If the artist cancels, you get a full '
      'refund.';

  /// Share of the advance to refund, from 0 (nothing) to 1 (everything).
  static double refundShare({
    required DateTime startAt,
    required DateTime cancelledAt,
    bool cancelledByArtist = false,
  }) {
    if (cancelledByArtist) return 1;

    final untilStart = startAt.difference(cancelledAt);
    if (untilStart >= fullRefundUntil) return 1;
    if (untilStart >= noRefundWithin) return partialRefundShare;
    return 0;
  }
}
