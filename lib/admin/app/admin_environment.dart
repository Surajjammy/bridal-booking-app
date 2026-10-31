/// Build-time switch that sends every Firebase call to the local emulators
/// instead of the real project:
/// `flutter run -t lib/admin/main_admin.dart -d chrome --dart-define=USE_EMULATOR=true`
/// Off by default, so a normal build always uses the real project.
class AdminEnvironment {
  AdminEnvironment._();

  static const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

  // Ports match the `emulators` block in firebase.json.
  static const String emulatorHost = 'localhost';
  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int storagePort = 9199;
}
