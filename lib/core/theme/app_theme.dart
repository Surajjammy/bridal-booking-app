import 'package:flutter/material.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: ColorResource.colorRoseGoldCTA,
      brightness: Brightness.dark,
    ).copyWith(
      primary: ColorResource.colorRoseGoldCTA,
      secondary: ColorResource.colorPrimaryAccent,
      surface: ColorResource.colorCards,
      onSurface: ColorResource.colorSoftText,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: scheme,
      scaffoldBackgroundColor: ColorResource.colorBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorResource.colorBg,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorResource.colorRoseGoldCTA,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              ColorResource.colorRoseGoldCTA.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorResource.colorCards,
        selectedColor: ColorResource.colorRoseGoldCTA,
        disabledColor: ColorResource.colorCards.withValues(alpha: 0.5),
        side: BorderSide(
          color: ColorResource.colorPrimaryAccent.withValues(alpha: 0.2),
        ),
        labelStyle: const TextStyle(color: ColorResource.colorSoftText),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        checkmarkColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorResource.colorCards,
        hintStyle: TextStyle(
          color: ColorResource.colorSoftText.withValues(alpha: 0.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorResource.colorPrimaryAccent,
      ),
    );
  }
}
