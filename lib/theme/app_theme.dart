import 'package:flutter/material.dart';

abstract final class AppColors {
  static const voidBlack = Color(0xFF07070D);
  static const ink = Color(0xFF0F0F18);
  static const surface = Color(0xFF161622);
  static const lime = Color(0xFFD4FF00);
  static const limeDim = Color(0x99D4FF00);
  static const hotPink = Color(0xFFFF006B);
  static const pinkGlow = Color(0xFFFF4D9E);
  static const electric = Color(0xFF00F0FF);
  static const white = Color(0xFFF8F8FF);
  static const muted = Color(0xFF8B8B9E);
  static const stroke = Color(0xFF2A2A3C);

  // legacy aliases used in some widgets
  static const cream = voidBlack;
  static const blush = surface;
  static const lavender = surface;
  static const peach = lime;
  static const coral = hotPink;
  static const rose = pinkGlow;
  static const violet = electric;
  static const plum = white;
  static const plumSoft = muted;
  static const nightTop = voidBlack;
  static const nightBottom = ink;
}

class AppTheme {
  static TextStyle display(double size, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(fontSize: size, fontWeight: weight, height: 1.15, letterSpacing: 0);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.muted,
        height: 1.4,
        letterSpacing: 0,
      );

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lime,
        onPrimary: AppColors.voidBlack,
        secondary: AppColors.hotPink,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.white,
      ),
      textTheme: TextTheme(
        displayLarge: display(72, weight: FontWeight.w700),
        displayMedium: display(56, weight: FontWeight.w700),
        displaySmall: display(44, weight: FontWeight.w600),
        headlineLarge: display(32, weight: FontWeight.w600),
        headlineMedium: display(26, weight: FontWeight.w600),
        headlineSmall: display(22, weight: FontWeight.w600),
        titleLarge: body(18, weight: FontWeight.w600, color: AppColors.white),
        titleMedium: body(16, weight: FontWeight.w500, color: AppColors.white),
        bodyLarge: body(16),
        bodyMedium: body(14),
        bodySmall: body(12),
        labelLarge: body(14, weight: FontWeight.w600, color: AppColors.lime),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        titleTextStyle: display(20, weight: FontWeight.w600).copyWith(color: AppColors.white),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lime,
        inactiveTrackColor: AppColors.stroke,
        thumbColor: AppColors.hotPink,
        overlayColor: AppColors.lime.withValues(alpha: 0.12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.stroke, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.stroke, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lime, width: 2),
        ),
        labelStyle: body(14, color: AppColors.muted),
        hintStyle: body(14, color: AppColors.muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        contentTextStyle: body(14, color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.stroke),
        ),
      ),
    );
  }
}

class AppGradients {
  static const chaos = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF07070D), Color(0xFF12081A), Color(0xFF0A1020)],
  );

  static const ring = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF07070D), Color(0xFF1A0028), Color(0xFF3D0040)],
  );

  static const cardAccent = LinearGradient(
    colors: [AppColors.lime, Color(0xFFB8E600)],
  );

  static const pinkAccent = LinearGradient(
    colors: [AppColors.hotPink, AppColors.pinkGlow],
  );

  static const fab = LinearGradient(
    colors: [AppColors.lime, Color(0xFFA8E000)],
  );

  static const home = chaos;
}
