import 'package:intl/intl.dart';

final _rupees =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String formatRupees(num amount) => _rupees.format(amount);

String formatDate(DateTime date) => DateFormat('EEE, d MMM yyyy').format(date);

String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

/// Sortable key used to group slots by day, e.g. `20261006`.
String dateKey(DateTime date) => DateFormat('yyyyMMdd').format(date);
