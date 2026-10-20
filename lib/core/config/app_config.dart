class AppConfig {
  /// Platform commission taken from each booking amount.
  /// PLACEHOLDER: confirm the real rate before launch. It is stored on every
  /// booking, so changing it later never rewrites past bookings.
  static const double commissionRate = 0.15;

  /// Daily start times offered for booking. Per-artist availability replaces
  /// this once artists can manage their own calendar.
  static const List<int> defaultSlotHours = [10, 12, 14, 16, 18];
}
