import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/core/theme/app_theme.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:makeup_booking_app/features/booking/data/booking_repository.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';
import 'package:makeup_booking_app/features/booking/presentation/provider/booking_provider.dart';
import 'package:makeup_booking_app/features/booking/presentation/screen/booking_screen.dart';

// 8 AM on a Monday, so today's 10 AM opening is still ahead.
final _now = DateTime(2026, 10, 19, 8);

const _artist = Artist(
  id: 'a1',
  name: 'Priya',
  bio: '',
  city: 'Kochi',
  imageUrl: '',
  rating: 0,
  reviewCount: 0,
  serviceModes: [ServiceMode.studio],
  isActive: true,
  services: [
    ArtistService(
      id: 'cut',
      name: 'Haircut',
      price: 800,
      durationMinutes: 60,
    ),
    ArtistService(
      id: 'massage',
      name: 'Head massage',
      price: 300,
      durationMinutes: 30,
      kind: ServiceKind.addOn,
    ),
  ],
);

/// Records what the screen asks it to book, instead of touching Firestore.
class _RecordingRepository implements BookingRepository {
  BookingRequest? request;

  @override
  Future<String> createBooking(BookingRequest request) async {
    this.request = request;
    return 'b1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<_RecordingRepository> _pump(
  WidgetTester tester, {
  Set<DateTime> taken = const {},
}) async {
  final repository = _RecordingRepository();
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => _now),
        currentUserIdProvider.overrideWithValue('user-1'),
        bookedSlotsProvider.overrideWith((ref, query) async => taken),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const BookingScreen(artist: _artist),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _chooseToday(WidgetTester tester) async {
  await tester.tap(find.text('Choose date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a service plus an add-on is booked as one longer appointment',
      (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Haircut'));
    await tester.tap(find.text('Head massage'));
    await tester.pumpAndSettle();
    await _chooseToday(tester);

    // 60 + 30 minutes of service, then a 15 minute buffer.
    await tester.tap(find.text('10:00 AM'));
    await tester.pumpAndSettle();

    expect(find.text('₹1,100'), findsOneWidget); // 800 + 300
    expect(find.textContaining('10:00 AM – 11:30 AM'), findsOneWidget);
    expect(find.textContaining('1 h 30 min'), findsOneWidget);
    expect(find.textContaining('50% refund'), findsOneWidget);

    await tester.tap(find.text('Request Booking'));
    await tester.pumpAndSettle();

    final quote = repository.request!.quote;
    expect(repository.request!.userId, 'user-1');
    expect(repository.request!.startAt, DateTime(2026, 10, 19, 10));
    expect(quote.durationMinutes, 90);
    expect(quote.totalPrice, 1100);
    expect(quote.items.where((i) => i.isAddOn), hasLength(1));
  });

  testWidgets('times that clash with an existing booking are not offered',
      (tester) async {
    // Someone holds the 10:30 step, so a 60 + 15 minute booking cannot start
    // at 10:00 (needs 10:00, 10:30, 11:00) or at 10:30.
    await _pump(tester, taken: {DateTime(2026, 10, 19, 10, 30)});

    await tester.tap(find.text('Haircut'));
    await tester.pumpAndSettle();
    await _chooseToday(tester);

    expect(find.text('10:00 AM'), findsNothing);
    expect(find.text('10:30 AM'), findsNothing);
    expect(find.text('11:00 AM'), findsOneWidget);
  });

  testWidgets('adding an add-on after picking a time clears the time',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Haircut'));
    await tester.pumpAndSettle();
    await _chooseToday(tester);
    await tester.tap(find.text('10:00 AM'));
    await tester.pumpAndSettle();
    expect(find.text('Total'), findsOneWidget);

    // The booking got longer, so the old time may no longer fit.
    await tester.tap(find.text('Head massage'));
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsNothing);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Request Booking'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a message when the service does not fit that day',
      (tester) async {
    final repository = await _pump(tester);
    expect(repository.request, isNull);

    // Every step of the working day is taken.
    final allDay = {
      for (var m = 10 * 60; m < 18 * 60; m += 30)
        DateTime(2026, 10, 19, m ~/ 60, m % 60),
    };
    await _pump(tester, taken: allDay);

    await tester.tap(find.text('Haircut'));
    await tester.pumpAndSettle();
    await _chooseToday(tester);

    expect(find.textContaining('No times left on this day'), findsOneWidget);
  });
}
