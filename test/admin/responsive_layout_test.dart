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
