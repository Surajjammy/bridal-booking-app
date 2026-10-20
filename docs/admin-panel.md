# Admin panel

A Flutter Web app in the same repo as the customer app. Entry point:
`lib/admin/main_admin.dart`. State management is Riverpod; each feature is
split into `domain` (entities and repository interfaces), `data` (Firestore
and Storage) and `presentation` (providers and screens).

## Try it safely: local emulator sandbox

Nothing here touches the real Firebase project.

1. Install **JDK 21 or newer** (the Firebase emulators need it) and make sure
   it is the `java` on your PATH.
2. Start the emulators from the project root:
   `firebase emulators:start --only auth,firestore,storage`
3. In a second terminal, add a test admin and fake artists:
   `node tool/seed_emulator.mjs` (the test logins are listed at the top of
   that file; they exist only inside the emulator).
4. Run the panel against the emulators:
   `flutter run -t lib/admin/main_admin.dart -d chrome --dart-define=USE_EMULATOR=true`

You will see an orange **EMULATOR** ribbon, Firebase's own emulator banner and
`[admin] backend: EMULATOR` in the browser console. If you do not, you are not
in the sandbox. Emulator data is wiped when the emulators stop; run the seed
script again after each start.

If you build with `flutter build web --dart-define=USE_EMULATOR=true`, add
`--pwa-strategy=none` so the browser never serves a stale cached build.

## Use it for real

Without `--dart-define=USE_EMULATOR=true` the panel talks to the real project
(`makeupartistbooking-3d2da`). Before the first sign-in:

1. Firebase console, Authentication: enable **Email/Password**.
2. Authentication, Users: add your admin user and copy its **User UID**.
3. Firestore: create the collection `admins` with a document whose ID is that
   UID (any field, e.g. `email`).
4. Storage: click Get started (pick the bucket location carefully; it cannot
   be changed).

Deploy the rules (`firebase deploy --only firestore:rules,storage`) only after
the admin document exists, or you will lock yourself out.

## Layout

```
lib/admin/
  main_admin.dart            entry point, emulator switch
  app/                       router, shell (sidebar), environment, app widget
  core/                      theme, shared widgets, validators, photo upload
  features/auth/             admin sign-in and the admins-list check
  features/artists/          list, add/edit form, services editor, photo field
```
