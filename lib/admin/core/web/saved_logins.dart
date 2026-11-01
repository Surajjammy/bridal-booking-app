import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Deletes the browser's saved Firebase logins for this site.
///
/// Used only in emulator mode. A login saved by an earlier sandbox session (or
/// by the real project) makes Firebase contact its servers during start-up,
/// which happens before the emulator connection is applied, so the page would
/// quietly keep talking to the real project. Starting with no saved login
/// removes that race. It also suits a sandbox, whose data is wiped on restart.
Future<void> clearSavedFirebaseLogins() {
  // The database the Firebase web SDK keeps its signed-in user in.
  const databaseName = 'firebaseLocalStorageDb';

  final done = Completer<void>();
  void finish(web.Event _) {
    if (!done.isCompleted) done.complete();
  }

  final request = web.window.indexedDB.deleteDatabase(databaseName);
  request.onsuccess = finish.toJS;
  request.onerror = finish.toJS;
  request.onblocked = finish.toJS;

  // Never hold up start-up for long if the browser is slow to answer.
  return done.future.timeout(const Duration(seconds: 3), onTimeout: () {});
}
