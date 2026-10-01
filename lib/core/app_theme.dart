import 'package:flutter/material.dart';

/// Brand palette, taken from the Royal Marble logo (gold on charcoal).
class AppColors {
  static const gold = Color(0xFFC2A64A);
  static const goldDeep = Color(0xFF9C8233);
  static const charcoal = Color(0xFF23221C);
  static const ink = Color(0xFF3A382F);
  static const surface = Color(0xFFF8F6F0);
  static const card = Colors.white;
  static const line = Color(0xFFE6E1D3);

  static const ok = Color(0xFF2E7D4F);
  static const okSoft = Color(0xFFE3F2E8);
  static const warn = Color(0xFFB7791F);
  static const warnSoft = Color(0xFFFCF1DC);
  static const bad = Color(0xFFC0392B);
  static const badSoft = Color(0xFFFBE4E1);
  static const muted = Color(0xFF8A877C);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.charcoal,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.charcoal,
      surface: AppColors.surface,
      error: AppColors.bad,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.25),
      ),
    );
  }
}
