import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/admin/core/theme/admin_theme.dart';
import 'package:makeup_booking_app/admin/features/bookings/domain/admin_booking_repository.dart';
import 'package:makeup_booking_app/admin/features/bookings/presentation/provider/admin_booking_providers.dart';
import 'package:makeup_booking_app/admin/features/bookings/presentation/screen/bookings_screen.dart';
import 'package:makeup_booking_app/core/providers/clock_provider.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';

final _now = DateTime(2026, 10, 19, 12);

Booking _booking(
  String id,
  String artist,
  BookingStatus status, {
  required Duration startsIn,
  double amount = 15000,
}) {
  final start = _now.add(startsIn);
  return Booking(
    id: id,
    userId: 'user-$id',
    artistId: 'a-$id',
    artistName: artist,
    serviceName: 'Bridal makeup',
    mode: ServiceMode.studio,
    address: null,
    startAt: start,
    endAt: start.add(const Duration(hours: 3)),
    blockedUntil: start.add(const Duration(hours: 3, minutes: 30)),
    amount: amount,
    commissionRate: 0.15,
    status: status,
    createdAt: _now.subtract(const Duration(hours: 5)),
  );
}

class _FakeRepository implements AdminBookingRepository {
  final List<Booking> bookings;
  final Map<String, String> phones;
  final List<(String, BookingStatus)> changes = [];
  Object? failWith;

  _FakeRepository(this.bookings, {this.phones = const {}});

  @override
  Stream<List<Booking>> watchBookings() => Stream.value(bookings);

  @override
  Future<void> changeStatus(Booking booking, BookingStatus to) async {
    if (failWith != null) throw failWith!;
    changes.add((booking.id, to));
  }

  @override
  Future<String?> getCustomerPhone(String userId) async => phones[userId];
}

final _requested = _booking(
  'r',
  'Priya Nair',
  BookingStatus.requested,
  startsIn: const Duration(days: 2),
);
final _confirmed = _booking(
  'c',
  'Anjali Menon',
  BookingStatus.confirmed,
  startsIn: const Duration(days: 3),
);
final _completed = _booking(
  'd',
  'Meera Iyer',
  BookingStatus.completed,
  startsIn: const Duration(days: -4),
);
final _cancelled = _booking(
  'x',
  'Divya Rao',
  BookingStatus.cancelled,
  startsIn: const Duration(days: 5),
);

Future<_FakeRepository> _pump(
  WidgetTester tester, {
  List<Booking>? bookings,
}) async {
  final repository = _FakeRepository(
    bookings ?? [_requested, _confirmed, _completed, _cancelled],
    phones: {'user-r': '+919000000001'},
  );
  await tester.binding.setSurfaceSize(const Size(1200, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminBookingRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp(
        theme: AdminTheme.light,
        home: const Scaffold(body: BookingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('opens on the requests that need a decision', (tester) async {
    await _pump(tester);

    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Anjali Menon'), findsNothing);
    expect(find.text('Needs action (1)'), findsOneWidget);
    expect(find.text('1 waiting for a decision'), findsOneWidget);
  });

  testWidgets('shows the facts needed to decide', (tester) async {
    await _pump(tester);

    expect(find.text('Bridal makeup'), findsOneWidget);
    expect(find.textContaining('Studio'), findsOneWidget);
    expect(find.text('+919000000001'), findsOneWidget);
    // 15% of 15,000, with the rate that was in force when it was booked.
    expect(find.textContaining('₹2,250'), findsOneWidget);
    expect(find.textContaining('(15%)'), findsOneWidget);
  });

  testWidgets('tabs list the right bookings with their counts', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Upcoming (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Anjali Menon'), findsOneWidget);
    expect(find.text('Priya Nair'), findsNothing);

    await tester.tap(find.text('Past (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Meera Iyer'), findsOneWidget);

    await tester.tap(find.text('Declined or cancelled (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Divya Rao'), findsOneWidget);

    await tester.tap(find.text('All (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Divya Rao'), findsOneWidget);
  });

  testWidgets('search narrows by artist name', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('All (4)'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'anj');
    await tester.pumpAndSettle();

    expect(find.text('Anjali Menon'), findsOneWidget);
    expect(find.text('Priya Nair'), findsNothing);
  });

  testWidgets('confirming changes the status straight away', (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(repository.changes, [('r', BookingStatus.confirmed)]);
    expect(find.text('Booking confirmed'), findsOneWidget);
  });

  testWidgets('declining asks first, and only acts if the admin agrees',
      (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Decline this request?'), findsOneWidget);
    expect(find.textContaining('frees Priya Nair'), findsOneWidget);

    // Backing out changes nothing.
    await tester.tap(find.text('Keep as is'));
    await tester.pumpAndSettle();
    expect(repository.changes, isEmpty);

    // Going through with it does.
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();
    expect(repository.changes, [('r', BookingStatus.declined)]);
  });

  testWidgets('a booking changed by someone else shows a clear message',
      (tester) async {
    final repository = await _pump(tester);
    repository.failWith = const BookingChangedException();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.textContaining('just changed by someone else'), findsOneWidget);
    expect(repository.changes, isEmpty);
  });

  testWidgets('finished bookings offer no actions', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Declined or cancelled (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Decline'), findsNothing);
    expect(find.text('Cancel booking'), findsNothing);
  });

  testWidgets('says so when nothing needs a decision', (tester) async {
    await _pump(tester, bookings: [_confirmed]);

    expect(find.text('No requests waiting for a decision.'), findsOneWidget);
    expect(find.text('Nothing is waiting for a decision'), findsOneWidget);
  });
}
