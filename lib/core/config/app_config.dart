class AppConfig {
  /// Platform commission taken from each booking amount.
  /// PLACEHOLDER: confirm the real rate before launch. It is stored on every
  /// booking, so changing it later never rewrites past bookings.
  static const double commissionRate = 0.15;

  /// Lower rate on a customer who has booked this provider before, so
  /// providers have no reason to move regulars off the app. PLACEHOLDER like
  /// [commissionRate]; each provider can be given its own in the admin panel.
  static const double repeatCommissionRate = 0.05;

  /// Granularity of the booking calendar. Every booking blocks whole steps,
  /// rounded up, so a 50-minute service blocks two 30-minute steps.
  static const int slotStepMinutes = 30;
}
