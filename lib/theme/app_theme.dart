import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MijigiColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF0D1117);
  static const surfaceLight = Color(0xFF161B22);
  static const surfaceBright = Color(0xFF1C2333);
  static const primary = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFF60A5FA);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFF93C5FD);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textTertiary = Color(0xFF484F58);
  static const border = Color(0xFF21262D);
  static const borderLight = Color(0xFF30363D);

  // File type colors
  static const filePdf = Color(0xFFEF4444);
  static const fileDoc = Color(0xFF3B82F6);
  static const fileSheet = Color(0xFF22C55E);
  static const fileNote = Color(0xFF8B5CF6);
  static const fileClipboard = Color(0xFFF59E0B);

  // Category colors
  static const categoryReceipt = Color(0xFF22C55E);
  static const categoryDocument = Color(0xFF3B82F6);
  static const categoryMedical = Color(0xFFEC4899);
  static const categoryFinancial = Color(0xFFF59E0B);
  static const categoryTravel = Color(0xFF06B6D4);
  static const categoryWork = Color(0xFF8B5CF6);
  static const categoryPersonal = Color(0xFFF97316);
  static const categoryFood = Color(0xFFA3E635);
  static const categoryShopping = Color(0xFFD946EF);
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
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MijigiColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: MijigiColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MijigiColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MijigiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MijigiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: MijigiColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MijigiColors.textTertiary,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: MijigiColors.textPrimary,
        displayColor: MijigiColors.textPrimary,
      ),
      dividerColor: MijigiColors.border,
      dialogTheme: DialogThemeData(
        backgroundColor: MijigiColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MijigiColors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MijigiColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
