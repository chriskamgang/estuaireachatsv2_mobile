import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Couleurs du logo
  static const primary = Color(0xFFE82328);    // Rouge du logo "Estuaire"
  static const primaryLight = Color(0xFFFF3338);
  static const secondary = Color(0xFF4A90D9);  // Bleu du logo "Achats"
  static const secondaryLight = Color(0xFF6AABEF);

  // Legacy alias
  static const orange = primary;
  static const red = primary;
  static const blue = secondary;

  static const green = Color(0xFF00A06A);
  static const dark = Color(0xFF191919);
  static const gray1 = Color(0xFF333333);
  static const gray2 = Color(0xFF666666);
  static const gray3 = Color(0xFF999999);
  static const gray4 = Color(0xFFCCCCCC);
  static const gray5 = Color(0xFFE8E8E8);
  static const gray6 = Color(0xFFF5F5F5);
  static const white = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.white,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray3,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark,
          side: const BorderSide(color: AppColors.gray4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.gray3, fontSize: 14),
      ),
      dividerColor: AppColors.gray5,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: AppColors.white,
      ),
    );
  }
}
