import 'package:flutter/material.dart';

/// Colour tokens for the admin panel. Change a value here and the whole
/// panel follows; nothing else hardcodes a colour.
class AdminColors {
  AdminColors._();

  // Surfaces
  static const Color pageBackground = Color(0xFFFAF7F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sidebar = Color(0xFF1C1C1E);
  static const Color border = Color(0xFFE8E0D8);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B6460);
  static const Color textOnSidebar = Color(0xFFD9D2CA);

  // Brand (shared with the customer app)
  static const Color champagne = Color(0xFFE8C9A0);
  static const Color roseGold = Color(0xFFB76E79);

  /// Darker rose gold for buttons and links: passes 4.5:1 contrast with
  /// white text, which [roseGold] does not.
  static const Color primary = Color(0xFF9E5560);

  // Status
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFC0392B);
  static const Color neutral = Color(0xFF6B6460);
}
