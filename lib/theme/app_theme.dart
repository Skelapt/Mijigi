import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MijigiColors {
  static const background = Color(0xFF060610);
  static const surface = Color(0xFF101020);
  static const surfaceLight = Color(0xFF1A1A2E);
  static const surfaceBright = Color(0xFF242440);
  static const primary = Color(0xFF7C6AFF);
  static const primaryLight = Color(0xFF9D8FFF);
  static const accent = Color(0xFF00D4AA);
  static const accentLight = Color(0xFF33EABB);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFFF5252);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C0);
  static const textTertiary = Color(0xFF6A6A80);
  static const border = Color(0xFF1E1E35);
  static const borderLight = Color(0xFF2A2A45);
  static const shimmer = Color(0xFF2A2A45);

  static const categoryReceipt = Color(0xFF4CAF50);
  static const categoryDocument = Color(0xFF2196F3);
  static const categoryMedical = Color(0xFFE91E63);
  static const categoryFinancial = Color(0xFFFF9800);
  static const categoryTravel = Color(0xFF00BCD4);
  static const categoryWork = Color(0xFF9C27B0);
  static const categoryPersonal = Color(0xFFFF5722);
  static const categoryFood = Color(0xFFCDDC39);
  static const categoryShopping = Color(0xFFE040FB);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: MijigiColors.background,
      colorScheme: const ColorScheme.dark(
        surface: MijigiColors.surface,
        primary: MijigiColors.primary,
        secondary: MijigiColors.accent,
        error: MijigiColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: MijigiColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MijigiColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: MijigiColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MijigiColors.surface,
        selectedItemColor: MijigiColors.primary,
        unselectedItemColor: MijigiColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: MijigiColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MijigiColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MijigiColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MijigiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MijigiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MijigiColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MijigiColors.textTertiary,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: MijigiColors.textPrimary,
        displayColor: MijigiColors.textPrimary,
      ),
      dividerColor: MijigiColors.border,
      dialogTheme: DialogThemeData(
        backgroundColor: MijigiColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
