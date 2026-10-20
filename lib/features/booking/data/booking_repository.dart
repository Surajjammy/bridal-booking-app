import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';

import '../domain/booking.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository(this._firestore);

  String _slotId(String artistId, DateTime startAt) =>
      '${artistId}_${dateKey(startAt)}${startAt.hour.toString().padLeft(2, '0')}'
      '${startAt.minute.toString().padLeft(2, '0')}';

  /// Start times already taken for [artistId] on [day].
  Future<Set<DateTime>> getBookedSlots(String artistId, DateTime day) async {
    final snapshot = await _firestore
        .collection('bookingSlots')
        .where('artistId', isEqualTo: artistId)
        .where('dateKey', isEqualTo: dateKey(day))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['startAt'] as Timestamp).toDate())
        .toSet();
  }

  /// Creates a `requested` booking and locks its slot in one transaction so
  /// two customers can never hold the same artist and time.
  Future<String> createBooking(BookingRequest request) async {
    final bookingRef = _firestore.collection('bookings').doc();
    final slotRef = _firestore
        .collection('bookingSlots')
        .doc(_slotId(request.artist.id, request.startAt));

    await _firestore.runTransaction((tx) async {
      final slot = await tx.get(slotRef);
      if (slot.exists) throw const SlotUnavailableException();

      final startAt = Timestamp.fromDate(request.startAt);

      tx.set(slotRef, {
        'artistId': request.artist.id,
        'bookingId': bookingRef.id,
        'userId': request.userId,
        'dateKey': dateKey(request.startAt),
        'startAt': startAt,
      });

      tx.set(bookingRef, {
        'userId': request.userId,
        'artistId': request.artist.id,
        'artistName': request.artist.name,
        'serviceId': request.service.id,
        'serviceName': request.service.name,
        'durationMinutes': request.service.durationMinutes,
        'mode': request.mode.name,
        'address': request.address,
        'startAt': startAt,
        'amount': request.service.price,
        'commissionRate': AppConfig.commissionRate,
        'status': BookingStatus.requested.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }
}
