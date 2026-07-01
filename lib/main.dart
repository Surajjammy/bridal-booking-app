import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/artist/presentation/screen/artist_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔥 IMPORTANT

  await Firebase.initializeApp();
  runApp(
    const ProviderScope(
      // 🔥 THIS IS REQUIRED
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          fontFamily: 'Poppins'),
      home: const ArtistListScreen(),
    );
  }
}
