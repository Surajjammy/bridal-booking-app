import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/admin_theme.dart';
import 'admin_environment.dart';
import 'admin_router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Makeup Artist Booking · Admin',
      theme: AdminTheme.light,
      routerConfig: ref.watch(adminRouterProvider),
      builder: (context, child) {
        // A visible ribbon makes it impossible to mistake the sandbox for the
        // real project.
        if (child == null) return const SizedBox.shrink();
        if (!AdminEnvironment.useEmulator) return child;
        return Banner(
          message: 'EMULATOR',
          location: BannerLocation.topEnd,
          color: Colors.deepOrange,
          child: child,
        );
      },
    );
  }
}
