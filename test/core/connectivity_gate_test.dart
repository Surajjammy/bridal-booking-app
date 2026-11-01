import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/core/providers/connectivity_provider.dart';
import 'package:makeup_booking_app/core/widgets/connectivity_gate.dart';

class _FakeConnectivity implements Connectivity {
  List<ConnectivityResult> current;
  final changes = StreamController<List<ConnectivityResult>>.broadcast();

  _FakeConnectivity(this.current);

  void set(List<ConnectivityResult> results) {
    current = results;
    changes.add(results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

const _wifi = [ConnectivityResult.wifi];
const _none = [ConnectivityResult.none];

Widget _app(_FakeConnectivity connectivity, Widget home) {
  return ProviderScope(
    overrides: [connectivityProvider.overrideWithValue(connectivity)],
    child: MaterialApp(
      builder: (context, child) => ConnectivityGate(child: child!),
      home: home,
    ),
  );
}

/// A screen with state, to prove it survives going offline and back.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => taps++),
          child: Text('taps: $taps'),
        ),
      ),
    );
  }
}

void main() {
  group('isOnlineProvider', () {
    test('starts with the current connection state', () async {
      final container = ProviderContainer(overrides: [
        connectivityProvider.overrideWithValue(_FakeConnectivity(_none)),
      ]);
      addTearDown(container.dispose);
      // Riverpod 3 pauses a provider nobody listens to.
      container.listen(isOnlineProvider, (_, __) {});

      expect(await container.read(isOnlineProvider.future), isFalse);
    });

    test('treats any network except none as online', () async {
      final container = ProviderContainer(overrides: [
        connectivityProvider.overrideWithValue(
          _FakeConnectivity([ConnectivityResult.mobile]),
        ),
      ]);
      addTearDown(container.dispose);
      container.listen(isOnlineProvider, (_, __) {});

      expect(await container.read(isOnlineProvider.future), isTrue);
    });
  });

  group('ConnectivityGate', () {
    testWidgets('shows nothing extra while online', (tester) async {
      await tester.pumpWidget(_app(_FakeConnectivity(_wifi), const _Counter()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No internet connection'), findsNothing);
      expect(find.text('taps: 0'), findsOneWidget);
    });

    testWidgets('covers the app while offline and removes the cover when back',
        (tester) async {
      final connectivity = _FakeConnectivity(_wifi);
      await tester.pumpWidget(_app(connectivity, const _Counter()));
      await tester.pump();

      connectivity.set(_none);
      await tester.pump(); // event delivered
      await tester.pump(offlineGracePeriod + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400)); // fade in

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      connectivity.set(_wifi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // fade out

      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('the screen underneath keeps its state', (tester) async {
      final connectivity = _FakeConnectivity(_wifi);
      await tester.pumpWidget(_app(connectivity, const _Counter()));
      await tester.pump();

      await tester.tap(find.text('taps: 0'));
      await tester.pump();
      await tester.tap(find.text('taps: 1'));
      await tester.pump();
      expect(find.text('taps: 2'), findsOneWidget);

      connectivity.set(_none);
      await tester.pump();
      await tester.pump(offlineGracePeriod + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('No internet connection'), findsOneWidget);

      connectivity.set(_wifi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('taps: 2'), findsOneWidget);
    });

    testWidgets('a brief drop that recovers never shows the screen',
        (tester) async {
      final connectivity = _FakeConnectivity(_wifi);
      await tester.pumpWidget(_app(connectivity, const _Counter()));
      await tester.pump();

      connectivity.set(_none);
      await tester.pump();
      // Back on another network before the grace period ends.
      connectivity.current = const [ConnectivityResult.mobile];
      await tester.pump(offlineGracePeriod + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('blocks taps on the app while offline', (tester) async {
      final connectivity = _FakeConnectivity(_none);
      await tester.pumpWidget(_app(connectivity, const _Counter()));
      await tester.pump();
      await tester.pump(offlineGracePeriod + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('taps: 0'), warnIfMissed: false);
      await tester.pump();

      connectivity.set(_wifi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('taps: 0'), findsOneWidget);
    });
  });
}
