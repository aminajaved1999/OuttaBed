import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFFFF8F3);
  static const blush = Color(0xFFFFE8EE);
  static const lavender = Color(0xFFF0E8FF);
  static const peach = Color(0xFFFFD6A5);
  static const coral = Color(0xFFFF8FAB);
  static const rose = Color(0xFFFF6B9D);
  static const violet = Color(0xFFB8A9E8);
  static const plum = Color(0xFF4A3F55);
  static const plumSoft = Color(0xFF7A6B8A);
  static const white = Color(0xFFFFFFFF);
  static const nightTop = Color(0xFF2D1B4E);
  static const nightBottom = Color(0xFF5B2C6F);
}

class AppTheme {
  static const _fontFamily = 'Nunito';

  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w200),
        displayMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w300),
        displaySmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w300),
        headlineMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800),
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.light(
        primary: AppColors.coral,
        onPrimary: AppColors.white,
        secondary: AppColors.violet,
        onSecondary: AppColors.white,
        surface: AppColors.cream,
        onSurface: AppColors.plum,
        surfaceContainerHighest: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: _textTheme,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.plum,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.plum,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.coral,
        inactiveTrackColor: AppColors.blush,
        thumbColor: AppColors.rose,
        overlayColor: AppColors.coral.withValues(alpha: 0.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.blush, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.coral, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.plumSoft,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.plum,
      ),
    );
  }
}

class AppGradients {
  static const home = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF5F7), Color(0xFFF3EEFF), Color(0xFFFFF8F0)],
    stops: [0.0, 0.55, 1.0],
  );

  static const ring = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.nightTop, AppColors.nightBottom, Color(0xFF8E3A6F)],
    stops: [0.0, 0.5, 1.0],
  );

  static const cardAccent = LinearGradient(
    colors: [AppColors.coral, AppColors.rose],
  );

  static const fab = LinearGradient(
    colors: [Color(0xFFFF8FAB), Color(0xFFFF6B9D)],
  );
}
