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

/// Reusable gradient helpers for premium card backgrounds.
class MijigiGradients {
  /// Subtle dark card gradient (top-left to bottom-right).
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF111820),
      Color(0xFF0A0F16),
    ],
  );

  /// Slightly elevated card gradient for hover / active states.
  static const cardElevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF161D28),
      Color(0xFF0D1219),
    ],
  );

  /// Hero gradient for primary CTAs and scanner cards.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A3158),
      Color(0xFF0D192E),
      Color(0xFF081220),
    ],
  );

  /// Frosted glass effect decoration for bottom sheets.
  static BoxDecoration frostedSheet({double opacity = 0.92}) {
    return BoxDecoration(
      color: MijigiColors.surface.withValues(alpha: opacity),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      border: const Border(
        top: BorderSide(color: Color(0xFF1E2530), width: 0.5),
      ),
    );
  }

  /// Primary button gradient.
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A90F7),
      Color(0xFF2563EB),
      Color(0xFF1D4FCC),
    ],
  );
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
          fontWeight: FontWeight.w500,
          color: MijigiColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: MijigiColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MijigiColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MijigiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MijigiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: MijigiColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MijigiColors.textTertiary,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: MijigiColors.surface.withValues(alpha: 0.92),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MijigiColors.surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
