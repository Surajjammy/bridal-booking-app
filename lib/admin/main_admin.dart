import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_firebase_options.dart';
import 'app/admin_app.dart';
import 'app/admin_environment.dart';
import 'core/web/saved_logins.dart';

/// Entry point of the admin web app:
/// `flutter run -t lib/admin/main_admin.dart -d chrome`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Before Firebase starts, so no stale login can make it contact the real
  // project ahead of the emulator connection.
  if (AdminEnvironment.useEmulator) await clearSavedFirebaseLogins();

  await Firebase.initializeApp(options: adminFirebaseOptions);

  if (AdminEnvironment.useEmulator) {
    try {
      await _connectToEmulators();
    } catch (error) {
      // Never fall back to the real project when emulators were requested.
      runApp(_EmulatorFailureApp(error));
      return;
    }
  }

  debugPrint(
    '[admin] backend: ${AdminEnvironment.useEmulator ? 'EMULATOR' : 'REAL PROJECT'}',
  );
  runApp(const ProviderScope(child: AdminApp()));
}

Future<void> _connectToEmulators() async {
  const host = AdminEnvironment.emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(host, AdminEnvironment.authPort);
  FirebaseFirestore.instance
      .useFirestoreEmulator(host, AdminEnvironment.firestorePort);
  await FirebaseStorage.instance
      .useStorageEmulator(host, AdminEnvironment.storagePort);
}

class _EmulatorFailureApp extends StatelessWidget {
  final Object error;

  const _EmulatorFailureApp(this.error);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not connect to the Firebase emulators, so the app did not '
              'start (it will not fall back to the real project).\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
