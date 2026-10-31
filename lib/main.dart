import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/theme/app_theme.dart';
import 'package:makeup_booking_app/features/artist/presentation/screen/artist_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (kDebugMode) {
    // An emulator has no Google Play services or real browser, so Firebase's
    // device check (Play Integrity / reCAPTCHA) can never finish there. This
    // skips it, and only works with the fictional test numbers added in the
    // Firebase console. Debug builds only: release builds always verify.
    await FirebaseAuth.instance
        .setSettings(appVerificationDisabledForTesting: true);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Makeup Artist Booking',
      theme: AppTheme.dark,
      home: const ArtistListScreen(),
    );
  }
}
