import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../domain/booking.dart';

class BookingRepository {
  final FirebaseFirestore _firestore;

  BookingRepository(this._firestore);

  String _slotId(String artistId, DateTime startAt) =>
      '${artistId}_${dateKey(startAt)}${startAt.hour.toString().padLeft(2, '0')}'
      '${startAt.minute.toString().padLeft(2, '0')}';

  /// The customer's bookings, newest first. Sorted here rather than in the
  /// query so no composite Firestore index is needed.
  Stream<List<Booking>> watchUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map(_fromDoc).toList()
        ..sort((a, b) => b.startAt.compareTo(a.startAt));
      return bookings;
    });
  }

  Booking _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    return Booking(
      id: doc.id,
      artistId: (map['artistId'] ?? '').toString(),
      artistName: (map['artistName'] ?? '').toString(),
      serviceName: (map['serviceName'] ?? '').toString(),
      mode: ServiceMode.fromName(map['mode']?.toString()) ?? ServiceMode.studio,
      address: map['address'] as String?,
      startAt: (map['startAt'] as Timestamp).toDate(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.requested,
      ),
    );
  }

  /// Marks the booking cancelled and frees its slot, atomically.
  Future<void> cancelBooking(Booking booking) {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('bookings').doc(booking.id), {
      'status': BookingStatus.cancelled.name,
    });
    batch.delete(
      _firestore
          .collection('bookingSlots')
          .doc(_slotId(booking.artistId, booking.startAt)),
    );
    return batch.commit();
  }

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
