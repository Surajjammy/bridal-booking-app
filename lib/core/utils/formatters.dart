import 'package:intl/intl.dart';

final _rupees =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String formatRupees(num amount) => _rupees.format(amount);

String formatDate(DateTime date) => DateFormat('EEE, d MMM yyyy').format(date);

String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

/// Minutes after midnight as a clock time, e.g. 330 -> "5:30 AM".
String formatMinuteOfDay(int minutes) =>
    formatTime(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

/// A length of time for people: 90 -> "1 h 30 min", 120 -> "2 h", 45 -> "45 min".
String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

/// A moment for people: "18 Oct, 3:20 PM".
String formatDateTime(DateTime date) => DateFormat('d MMM, h:mm a').format(date);

/// A fraction as a percentage, without a pointless ".0": 0.15 -> "15%",
/// 0.125 -> "12.5%".
String formatPercent(double fraction) => '${formatPercentNumber(fraction)}%';

/// Same, without the percent sign, for form fields: 0.15 -> "15".
String formatPercentNumber(double fraction) {
  final percent = fraction * 100;
  return percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1);
}

/// Sortable key used to group slots by day, e.g. `20261006`.
String dateKey(DateTime date) => DateFormat('yyyyMMdd').format(date);
