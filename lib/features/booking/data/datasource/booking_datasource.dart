import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDatasource {
  final FirebaseFirestore firestore;

  BookingDatasource({required this.firestore});

  Future<void> saveBooking({
    required String artistName,
    required String date,
    required String time,
  }) async {
    await firestore.collection('bookings').add({
      'artist_name': artistName,
      'date': date,
      'time': time,
      'createdAt': DateTime.now(),
    });
  }
}
