/// Collection names. Keep in sync with `firestore.rules` and
/// `docs/firestore-schema.md`.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String admins = 'admins';
  static const String providers = 'providers';
  static const String artists = 'artists';
  static const String artistPrivate = 'artistPrivate';
  static const String portfolio = 'portfolio';
  static const String bookings = 'bookings';
  static const String bookingSlots = 'bookingSlots';
}
