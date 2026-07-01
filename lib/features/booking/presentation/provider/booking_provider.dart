import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasource/booking_datasource.dart';

final bookingDatasourceProvider = Provider<BookingDatasource>((ref) {
  final firestore = FirebaseFirestore.instance;
  return BookingDatasource(firestore: firestore);
});
