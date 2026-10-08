import 'package:flutter/material.dart';

import 'admin_colors.dart';

class AdminTheme {
  AdminTheme._();

  static const String fontFamily = 'Inter';
  static const double radius = 12;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AdminColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AdminColors.primary,
      onPrimary: Colors.white,
      secondary: AdminColors.roseGold,
      surface: AdminColors.surface,
      onSurface: AdminColors.textPrimary,
      surfaceContainerHighest: const Color(0xFFF1EBE5),
      outline: AdminColors.border,
      error: AdminColors.danger,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AdminColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminColors.pageBackground,
      dividerColor: AdminColors.border,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AdminColors.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AdminColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AdminColors.textSecondary),
        hintStyle: const TextStyle(color: AdminColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: shape,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: AdminColors.border),
          shape: shape,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.primary,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.surface,
        selectedColor: AdminColors.primary.withValues(alpha: 0.12),
        side: const BorderSide(color: AdminColors.border),
        shape: shape,
        labelStyle: _textTheme.bodyMedium,
        checkmarkColor: AdminColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AdminColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AdminColors.success
              : AdminColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdminColors.sidebar,
        contentTextStyle: _textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: shape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AdminColors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.surface,
        shape: shape,
      ),
    );
  }

  static final TextTheme _textTheme = const TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: AdminColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AdminColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AdminColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AdminColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AdminColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AdminColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AdminColors.textPrimary,
    ),
  ).apply(fontFamily: fontFamily);
}
