import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/core/constants/firestore_paths.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';

import '../domain/booking.dart';
import '../domain/booking_quote.dart';
import '../domain/slot_math.dart';
import 'booking_slots.dart';
import 'model/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;
  final BookingSlots _slots;

  BookingRepository(this._firestore) : _slots = BookingSlots(_firestore);

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestorePaths.bookings);

  /// The customer's bookings, newest first. Sorted here rather than in the
  /// query so no composite Firestore index is needed.
  Stream<List<Booking>> watchUserBookings(String userId) {
    return _bookings
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map(BookingModel.fromDoc).toList()
        ..sort((a, b) => b.startAt.compareTo(a.startAt));
      return bookings;
    });
  }

  /// Marks the booking cancelled and frees every step it locked, atomically.
  Future<void> cancelBooking(Booking booking) {
    final batch = _firestore.batch();

    batch.update(_bookings.doc(booking.id), {
      'status': BookingStatus.cancelled.name,
    });
    for (final lock in _slots.refsForBooking(booking)) {
      batch.delete(lock);
    }
    return batch.commit();
  }

  /// Calendar steps already taken for [artistId] on [day].
  Future<Set<DateTime>> getBookedSlots(String artistId, DateTime day) async {
    final snapshot = await _slots.collection
        .where('artistId', isEqualTo: artistId)
        .where('dateKey', isEqualTo: dateKey(day))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['startAt'] as Timestamp).toDate())
        .toSet();
  }

  Map<String, dynamic> _itemToMap(BookingItem item) => {
        'serviceId': item.serviceId,
        'name': item.name,
        'price': item.price,
        'durationMinutes': item.durationMinutes,
        'quantity': item.quantity,
        'isAddOn': item.isAddOn,
      };

  /// Creates a `requested` booking and locks every calendar step it needs in
  /// one transaction, so two customers can never overlap on the same artist.
  Future<String> createBooking(BookingRequest request) async {
    final quote = request.quote;
    final artist = quote.artist;
    final steps = SlotMath.lockSteps(request.startAt, quote.blockedMinutes);
    final lockRefs = _slots.refsFor(
      artist.id,
      request.startAt,
      quote.blockedMinutes,
    );
    final bookingRef = _bookings.doc();

    await _firestore.runTransaction((tx) async {
      // All reads come before any write.
      for (final ref in lockRefs) {
        if ((await tx.get(ref)).exists) throw const SlotUnavailableException();
      }

      for (var i = 0; i < steps.length; i++) {
        tx.set(lockRefs[i], {
          'artistId': artist.id,
          'bookingId': bookingRef.id,
          'userId': request.userId,
          'dateKey': dateKey(steps[i]),
          'startAt': Timestamp.fromDate(steps[i]),
        });
      }

      tx.set(bookingRef, {
        'userId': request.userId,
        'artistId': artist.id,
        'artistName': artist.name,
        'serviceId': quote.mainService.id,
        'serviceName': quote.summary,
        'items': quote.items.map(_itemToMap).toList(),
        'durationMinutes': quote.durationMinutes,
        'bufferMinutes': quote.bufferMinutes,
        'mode': quote.mode.name,
        'address': request.address,
        'startAt': Timestamp.fromDate(request.startAt),
        'endAt': Timestamp.fromDate(quote.endAt(request.startAt)),
        'blockedUntil': Timestamp.fromDate(quote.blockedUntil(request.startAt)),
        'amount': quote.totalPrice,
        // Placeholder: money rules move to the server with payments.
        'commissionRate': AppConfig.commissionRate,
        'status': BookingStatus.requested.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }
}
