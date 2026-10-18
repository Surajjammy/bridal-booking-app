/// Route paths for the admin panel. Use these instead of string literals.
class AdminRoutes {
  AdminRoutes._();

  static const String splash = '/loading';
  static const String login = '/login';
  static const String notAuthorised = '/not-authorised';
  static const String artists = '/artists';
  static const String newArtist = '/artists/new';
  static const String bookings = '/bookings';

  /// Where an admin lands after signing in: requests waiting for a decision.
  static const String home = bookings;

  static String editArtist(String id) => '/artists/$id';
}
