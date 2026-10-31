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

The seed adds a test admin, a non-admin user, three artists, two customers and
six bookings in every state (with the calendar locks the active ones hold), so
the Bookings page has something to show.

**Check Firebase's own red "Running in emulator mode" banner at the bottom of
the page.** That is the proof the page is using the sandbox. The orange
**EMULATOR** ribbon is only this app's own label and does not prove it. In
emulator mode the app clears the browser's saved Firebase logins on start-up, so
you sign in again after every reload; a stale saved login would otherwise make
Firebase contact the real project before the emulator connection applied.

Emulator data is wiped when the emulators stop; run the seed script again after
each start.

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
  features/bookings/         bookings page: tabs, search, confirm/decline/cancel
```

## Bookings page

Opens first after sign-in. Tabs: **Needs action** (requests waiting), Upcoming,
Past, Declined or cancelled, All, each with a count, plus search by artist or
service. Each booking shows the customer's phone, when and where, the amount and
the platform's commission at the rate recorded on the booking.

What an admin may do is decided in one place, `BookingTransitions`:

| Booking is | Admin can |
|---|---|
| Requested (time still ahead) | Confirm, Decline |
| Requested (time already passed) | Decline |
| Confirmed | Cancel, and Mark completed once it has ended |
| Declined, cancelled, completed | nothing further |

**Declining or cancelling frees the artist's calendar** (every locked 30-minute
step is deleted) in the same transaction as the status change, after asking for
confirmation. The change also re-checks that nobody else (for example the
customer cancelling) changed the booking first, and says so if they did.
