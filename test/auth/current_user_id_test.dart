import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/features/auth/data/auth_repository.dart';
import 'package:makeup_booking_app/features/auth/presentation/provider/auth_provider.dart';

/// Stands in for Firebase: knows who is signed in, and lets a test decide
/// when (or whether) the auth stream says anything.
class _FakeAuthRepository implements AuthRepository {
  final String? restoredUid;
  final StreamController<User?> stream = StreamController<User?>();

  _FakeAuthRepository({this.restoredUid});

  @override
  String? get currentUserId => restoredUid;

  @override
  Stream<User?> authStateChanges() => stream.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProviderContainer _container(_FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(() {
    container.dispose();
    repository.stream.close();
  });
  return container;
}

void main() {
  group('currentUserIdProvider', () {
    test('knows a restored login before the auth stream has said anything',
        () {
      // The bug: right after a restart the stream is still silent, yet the
      // saved session is already there. Booking read "nobody" and refused.
      final container = _container(_FakeAuthRepository(restoredUid: 'user-1'));

      expect(container.read(currentUserIdProvider), 'user-1');
    });

    test('is null when nobody is logged in and the stream is silent', () {
      final container = _container(_FakeAuthRepository());

      expect(container.read(currentUserIdProvider), isNull);
    });

    test('is null once the stream reports that the user signed out',
        () async {
      final repository = _FakeAuthRepository(restoredUid: 'user-1');
      final container = _container(repository);
      container.listen(currentUserIdProvider, (_, __) {});

      repository.stream.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserIdProvider), isNull);
    });
  });
}
