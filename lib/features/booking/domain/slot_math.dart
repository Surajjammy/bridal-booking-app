import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

/// Pure scheduling rules, with no Firebase in sight so they are easy to test.
///
/// The calendar is cut into steps of [AppConfig.slotStepMinutes]. A booking
/// blocks every step from its start until its end plus the artist's buffer.
class SlotMath {
  SlotMath._();

  static const int _step = AppConfig.slotStepMinutes;

  /// How many steps [minutes] occupy, rounded up.
  static int stepsFor(int minutes) => (minutes + _step - 1) ~/ _step;

  /// The start of every step a booking of [blockedMinutes] blocks from
  /// [start]. Each one becomes a lock document, so the same artist and time
  /// can never be booked twice, even by overlapping bookings of different
  /// lengths.
  static List<DateTime> lockSteps(DateTime start, int blockedMinutes) {
    return List.generate(
      stepsFor(blockedMinutes),
      (i) => start.add(Duration(minutes: i * _step)),
    );
  }

  /// When the blocked time ends: [start] plus whole steps.
  static DateTime blockedUntil(DateTime start, int blockedMinutes) {
    return start.add(Duration(minutes: stepsFor(blockedMinutes) * _step));
  }

  /// Start times on [day] that fit a service of [durationMinutes] plus the
  /// artist's [bufferMinutes]:
  ///  - the service itself finishes within working hours,
  ///  - it is not on a weekly day off,
  ///  - it starts in the future,
  ///  - and none of the steps it needs are in [taken].
  static List<DateTime> openStarts({
    required DateTime day,
    required WorkingHours hours,
    required Set<int> weeklyOffDays,
    required int durationMinutes,
    required int bufferMinutes,
    required Set<DateTime> taken,
    required DateTime now,
  }) {
    final date = DateTime(day.year, day.month, day.day);
    if (weeklyOffDays.contains(date.weekday)) return const [];

    final opening = date.add(Duration(minutes: hours.startMinute));
    final closing = date.add(Duration(minutes: hours.endMinute));
    final blockedMinutes = durationMinutes + bufferMinutes;

    final starts = <DateTime>[];
    for (var start = opening;
        !start.add(Duration(minutes: durationMinutes)).isAfter(closing);
        start = start.add(const Duration(minutes: _step))) {
      if (!start.isAfter(now)) continue;
      final clashes = lockSteps(start, blockedMinutes).any(taken.contains);
      if (!clashes) starts.add(start);
    }
    return starts;
  }
}
