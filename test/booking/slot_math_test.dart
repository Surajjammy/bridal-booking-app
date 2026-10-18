import 'package:flutter_test/flutter_test.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/booking/domain/slot_math.dart';

// A Monday.
final _monday = DateTime(2026, 10, 19);
final _longBefore = DateTime(2026, 1, 1);

DateTime _at(int hour, [int minute = 0]) =>
    DateTime(_monday.year, _monday.month, _monday.day, hour, minute);

List<DateTime> _open({
  WorkingHours hours = WorkingHours.standard,
  Set<int> off = const {},
  required int duration,
  int buffer = 0,
  Set<DateTime> taken = const {},
  DateTime? now,
  DateTime? day,
}) {
  return SlotMath.openStarts(
    day: day ?? _monday,
    hours: hours,
    weeklyOffDays: off,
    durationMinutes: duration,
    bufferMinutes: buffer,
    taken: taken,
    now: now ?? _longBefore,
  );
}

void main() {
  test('the test date really is a Monday', () {
    expect(_monday.weekday, DateTime.monday);
  });

  group('stepsFor', () {
    test('rounds up to whole 30-minute steps', () {
      expect(SlotMath.stepsFor(1), 1);
      expect(SlotMath.stepsFor(30), 1);
      expect(SlotMath.stepsFor(31), 2);
      expect(SlotMath.stepsFor(90), 3);
      expect(SlotMath.stepsFor(105), 4);
    });
  });

  group('lockSteps and blockedUntil', () {
    test('a 90 minute service with a 15 minute buffer blocks four steps', () {
      final steps = SlotMath.lockSteps(_at(12), 105);
      expect(steps, [_at(12), _at(12, 30), _at(13), _at(13, 30)]);
      expect(SlotMath.blockedUntil(_at(12), 105), _at(14));
    });
  });

  group('openStarts', () {
    test('offers every half hour the service still fits before closing', () {
      final starts = _open(duration: 60); // 10:00-18:00
      expect(starts.first, _at(10));
      expect(starts.last, _at(17)); // 17:00 + 60 min = 18:00
      expect(starts, hasLength(15));
    });

    test('a booked step removes every start that would overlap it', () {
      final starts = _open(duration: 60, taken: {_at(12)});

      // 11:30 would need the 12:00 step; 12:00 is the step itself.
      expect(starts, isNot(contains(_at(11, 30))));
      expect(starts, isNot(contains(_at(12))));
      expect(starts, contains(_at(11)));
      expect(starts, contains(_at(12, 30)));
    });

    test('the buffer is blocked too', () {
      final starts = _open(duration: 60, buffer: 30, taken: {_at(12, 30)});

      // 11:30 needs 11:30, 12:00 and 12:30 once the buffer is counted.
      expect(starts, isNot(contains(_at(11, 30))));
      expect(starts, contains(_at(11)));
    });

    test('the buffer may run past closing time, the service may not', () {
      final starts = _open(duration: 60, buffer: 60);
      expect(starts.last, _at(17));
    });

    test('nothing on a weekly day off', () {
      expect(_open(duration: 60, off: {DateTime.monday}), isEmpty);
      expect(_open(duration: 60, off: {DateTime.tuesday}), isNotEmpty);
    });

    test('never offers a time that has already passed', () {
      final starts = _open(duration: 60, now: _at(12));
      expect(starts.first, _at(12, 30));
    });

    test('a service longer than the working day cannot be booked', () {
      expect(_open(duration: 480), [_at(10)]); // exactly the 8 hour day
      expect(_open(duration: 510), isEmpty);
    });

    test('a bridal package can start before the usual opening time', () {
      final starts = _open(
        hours: const WorkingHours(startMinute: 5 * 60, endMinute: 21 * 60),
        duration: 270,
        buffer: 60,
      );
      expect(starts.first, _at(5));
      expect(starts.last, _at(16, 30)); // 16:30 + 4.5 h = 21:00
    });

    test('two bookings can sit back to back when no buffer is needed', () {
      // First booking 10:00-11:00 occupies steps 10:00 and 10:30.
      final starts = _open(duration: 60, taken: {_at(10), _at(10, 30)});
      expect(starts.first, _at(11));
    });
  });
}
