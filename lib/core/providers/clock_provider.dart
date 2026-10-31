import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now", as a function so tests can fix the time instead of racing the clock.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
