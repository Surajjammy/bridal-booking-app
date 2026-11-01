import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/core/constants/firestore_paths.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';

import '../domain/booking.dart';
import '../domain/slot_math.dart';

/// The calendar lock documents. A booking owns one per 30-minute step from
/// its start until [Booking.blockedUntil]; deleting them frees the time.
/// Creating, cancelling and declining all go through here, so the document
/// naming and the step maths exist in exactly one place.
class BookingSlots {
  final FirebaseFirestore _firestore;

  BookingSlots(this._firestore);

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection(FirestorePaths.bookingSlots);

  /// The lock for [artistId] at the step starting at [step].
  DocumentReference<Map<String, dynamic>> ref(String artistId, DateTime step) {
    final time = '${step.hour.toString().padLeft(2, '0')}'
        '${step.minute.toString().padLeft(2, '0')}';
    return collection.doc('${artistId}_${dateKey(step)}$time');
  }

  /// Every step a booking of [blockedMinutes] from [start] locks.
  List<DocumentReference<Map<String, dynamic>>> refsFor(
    String artistId,
    DateTime start,
    int blockedMinutes,
  ) {
    return [
      for (final step in SlotMath.lockSteps(start, blockedMinutes))
        ref(artistId, step),
    ];
  }

  /// The locks an existing booking holds.
  List<DocumentReference<Map<String, dynamic>>> refsForBooking(
    Booking booking,
  ) {
    final blockedMinutes =
        booking.blockedUntil.difference(booking.startAt).inMinutes;
    return refsFor(booking.artistId, booking.startAt, blockedMinutes);
  }
}
