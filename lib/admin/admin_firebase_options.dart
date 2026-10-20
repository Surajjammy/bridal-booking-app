import 'package:firebase_core/firebase_core.dart';

/// Web configuration for the admin panel. These values identify the project
/// to the browser SDK and are safe to commit; access is enforced by the
/// Firebase security rules, not by keeping them secret. Restrict the API key
/// to the admin site's domain in the Google Cloud console.
const FirebaseOptions adminFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyDu8KEh1isuFf_aWmTYTgA5Z5aeaIa0uLk',
  appId: '1:585733318764:web:4a189c7ac6980a61551049',
  messagingSenderId: '585733318764',
  projectId: 'makeupartistbooking-3d2da',
  authDomain: 'makeupartistbooking-3d2da.firebaseapp.com',
  storageBucket: 'makeupartistbooking-3d2da.firebasestorage.app',
);
