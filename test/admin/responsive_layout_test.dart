import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/app/admin_shell.dart';
import 'package:makeup_booking_app/admin/core/theme/admin_theme.dart';
import 'package:makeup_booking_app/admin/features/artists/presentation/widgets/artist_form.dart';
import 'package:makeup_booking_app/admin/features/auth/domain/admin_auth_repository.dart';
import 'package:makeup_booking_app/admin/features/auth/presentation/provider/admin_auth_provider.dart';

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminUserProvider.overrideWith(
          (ref) => Stream.value(
            const AdminUser(uid: 'u1', email: 'admin@example.test'),
          ),
        ),
      ],
      child: MaterialApp(theme: AdminTheme.light, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminShell', () {
    const page = Center(child: Text('page body'));

    testWidgets('shows a permanent sidebar on wide screens', (tester) async {
      await _pump(
        tester,
        const Size(1200, 800),
        const AdminShell(location: '/artists', child: page),
      );

      expect(find.text('Admin panel'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('page body'), findsOneWidget);
    });

    testWidgets('collapses the sidebar into a drawer on narrow screens',
        (tester) async {
      await _pump(
        tester,
        const Size(500, 800),
        const AdminShell(location: '/artists', child: page),
      );

      // Sidebar content is hidden until the drawer opens.
      expect(find.text('Admin panel'), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Admin panel'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
    });
  });

  group('ArtistForm layout', () {
    for (final width in [360.0, 700.0, 1400.0]) {
      testWidgets('renders without overflow at ${width.toInt()}px',
          (tester) async {
        await _pump(
          tester,
          Size(width, 1400),
          const Scaffold(body: ArtistForm()),
        );

        expect(find.text('Add artist'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Services'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('rejects contact details in the public text fields',
        (tester) async {
      await _pump(
        tester,
        const Size(1200, 1600),
        const Scaffold(body: ArtistForm()),
      );

      // Fields in order: name, city, about, then the service name.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Priya');
      await tester.enterText(fields.at(1), 'Kochi');
      await tester.enterText(fields.at(2), 'Call me on 98765 43210');
      await tester.enterText(fields.at(3), 'Bridal @priya.makeup');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("don't add phone numbers"),
        findsNWidgets(2),
      );
    });

    testWidgets('repeat commission cannot exceed the new-customer rate',
        (tester) async {
      await _pump(
        tester,
        const Size(1200, 2000),
        const Scaffold(body: ArtistForm()),
      );

      // Defaults are 15% and 5%; make the repeat rate higher than the first.
      final repeat = find.widgetWithText(
        TextFormField,
        'Commission, repeat customers',
      );
      await tester.enterText(repeat, '20');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Must not be higher than the new-customer rate'),
        findsOneWidget,
      );
    });

    testWidgets('empty form reports every missing field', (tester) async {
      await _pump(
        tester,
        const Size(1200, 1600),
        const Scaffold(body: ArtistForm()),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('City is required'), findsOneWidget);
      expect(find.text('Add a profile photo'), findsOneWidget);
      expect(find.text('Service name is required'), findsOneWidget);
    });
  });
}
