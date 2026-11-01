import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../domain/booking.dart';
import '../../domain/slot_math.dart';

/// The one place that knows how a [Booking] is read from Firestore. The
/// customer app and the admin panel both use it.
class BookingModel {
  static Booking fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data() ?? {});
  }

  static Booking fromMap(String id, Map<String, dynamic> map) {
    final startAt = (map['startAt'] as Timestamp).toDate();
    final duration = (map['durationMinutes'] as num?)?.toInt() ??
        AppConfig.slotStepMinutes;

    return Booking(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      artistId: (map['artistId'] ?? '').toString(),
      artistName: (map['artistName'] ?? '').toString(),
      serviceName: (map['serviceName'] ?? '').toString(),
      mode: ServiceMode.fromName(map['mode']?.toString()) ?? ServiceMode.studio,
      address: map['address'] as String?,
      startAt: startAt,
      // Bookings made before durations were tracked fall back to one step.
      endAt: (map['endAt'] as Timestamp?)?.toDate() ??
          startAt.add(Duration(minutes: duration)),
      blockedUntil: (map['blockedUntil'] as Timestamp?)?.toDate() ??
          SlotMath.blockedUntil(startAt, duration),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.requested,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
