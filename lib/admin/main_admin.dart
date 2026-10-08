import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_firebase_options.dart';
import 'app/admin_app.dart';

/// Entry point of the admin web app:
/// `flutter run -t lib/admin/main_admin.dart -d chrome`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: adminFirebaseOptions);
  runApp(const ProviderScope(child: AdminApp()));
}
