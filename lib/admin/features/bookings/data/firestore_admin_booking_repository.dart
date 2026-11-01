import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:makeup_booking_app/core/constants/firestore_paths.dart';
import 'package:makeup_booking_app/features/booking/data/booking_slots.dart';
import 'package:makeup_booking_app/features/booking/data/model/booking_model.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';
import 'package:makeup_booking_app/features/booking/domain/booking_transitions.dart';

import '../domain/admin_booking_repository.dart';

class FirestoreAdminBookingRepository implements AdminBookingRepository {
  /// More than a pilot will ever have; keeps the screen quick. Paging comes
  /// when volume needs it.
  static const int _listLimit = 300;

  final FirebaseFirestore _firestore;
  final BookingSlots _slots;

  FirestoreAdminBookingRepository(this._firestore)
      : _slots = BookingSlots(_firestore);

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestorePaths.bookings);

  @override
  Stream<List<Booking>> watchBookings() {
    return _bookings
        .orderBy('startAt', descending: true)
        .limit(_listLimit)
        .snapshots()
        .map((snapshot) {
      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        try {
          bookings.add(BookingModel.fromDoc(doc));
        } catch (error) {
          // One malformed document must not hide every other booking.
          debugPrint('Skipping unreadable booking ${doc.id}: $error');
        }
      }
      return bookings;
    });
  }

  @override
  Future<void> changeStatus(Booking booking, BookingStatus to) async {
    if (!BookingTransitions.isAllowed(booking, to, DateTime.now())) {
      throw StateError(
        'A ${booking.status.name} booking cannot become ${to.name}.',
      );
    }

    final ref = _bookings.doc(booking.id);

    await _firestore.runTransaction((tx) async {
      // Reads first: is the booking still as the admin saw it?
      final current = (await tx.get(ref)).data()?['status'];
      if (current != booking.status.name) throw const BookingChangedException();

      tx.update(ref, {'status': to.name});

      if (BookingTransitions.freesCalendar(to)) {
        for (final lock in _slots.refsForBooking(booking)) {
          tx.delete(lock);
        }
      }
    });
  }

  @override
  Future<String?> getCustomerPhone(String userId) async {
    if (userId.isEmpty) return null;
    final doc =
        await _firestore.collection(FirestorePaths.users).doc(userId).get();
    final phone = doc.data()?['phone'];
    return phone is String && phone.isNotEmpty ? phone : null;
  }
}
