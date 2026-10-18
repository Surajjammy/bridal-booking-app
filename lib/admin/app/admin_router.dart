import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/artists/presentation/screen/artist_editor_screen.dart';
import '../features/bookings/presentation/screen/bookings_screen.dart';
import '../features/artists/presentation/screen/artists_list_screen.dart';
import '../features/auth/domain/admin_auth_repository.dart';
import '../features/auth/presentation/provider/admin_auth_provider.dart';
import '../features/auth/presentation/screen/admin_login_screen.dart';
import '../features/auth/presentation/screen/not_authorised_screen.dart';
import 'admin_routes.dart';
import 'admin_shell.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the signed-in/admin state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(adminAccessProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AdminRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) => _guard(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: AdminRoutes.splash,
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AdminRoutes.login,
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AdminRoutes.notAuthorised,
        builder: (_, __) => const NotAuthorisedScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.bookings,
            builder: (_, __) => const BookingsScreen(),
          ),
          GoRoute(
            path: AdminRoutes.artists,
            builder: (_, __) => const ArtistsListScreen(),
            routes: [
              // `new` is declared before `:id` so it is not read as an id.
              GoRoute(
                path: 'new',
                builder: (_, __) => const ArtistEditorScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ArtistEditorScreen(artistId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Sends people to the right place for their access level. Returning null
/// means "stay where you are".
String? _guard(Ref ref, String location) {
  final access = ref.read(adminAccessProvider);

  if (!access.hasValue) return AdminRoutes.splash;

  switch (access.requireValue) {
    case AdminAccess.signedOut:
      return location == AdminRoutes.login ? null : AdminRoutes.login;
    case AdminAccess.notAdmin:
      return location == AdminRoutes.notAuthorised
          ? null
          : AdminRoutes.notAuthorised;
    case AdminAccess.admin:
      final isEntryPage = location == AdminRoutes.login ||
          location == AdminRoutes.notAuthorised ||
          location == AdminRoutes.splash;
      return isEntryPage ? AdminRoutes.home : null;
  }
}
