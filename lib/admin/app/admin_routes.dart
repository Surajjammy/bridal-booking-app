/// Route paths for the admin panel. Use these instead of string literals.
class AdminRoutes {
  AdminRoutes._();

  static const String splash = '/loading';
  static const String login = '/login';
  static const String notAuthorised = '/not-authorised';
  static const String artists = '/artists';
  static const String newArtist = '/artists/new';

  static String editArtist(String id) => '/artists/$id';
}
