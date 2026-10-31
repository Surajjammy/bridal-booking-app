import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider/auth_provider.dart';
import 'screen/login_screen.dart';

/// Browsing is open to everyone; call this before an action that needs an
/// account (booking, viewing bookings). Returns true if the user is, or just
/// became, signed in.
Future<bool> ensureLoggedIn(BuildContext context, WidgetRef ref) async {
  if (ref.read(authRepositoryProvider).currentUser != null) return true;

  final loggedIn = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return loggedIn ?? false;
}
