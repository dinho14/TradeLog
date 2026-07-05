import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0C10);
  static const Color surface = Color(0xFF111318);
  static const Color surfaceAlt = Color(0xFF161A22);
  static const Color border = Color(0xFF1E2330);
  static const Color borderLight = Color(0xFF252C3A);

  static const Color accent = Color(0xFF00D4AA); // teal — profit
  static const Color accentDim = Color(0xFF00A882);
  static const Color red = Color(0xFFFF4757); // loss
  static const Color redDim = Color(0xFFCC3344);
  static const Color amber = Color(0xFFFFB422); // breakeven / warning
  static const Color blue = Color(0xFF4A9EFF); // info / long
  static const Color purple = Color(0xFFA78BFA); // short

  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF7A8199);
  static const Color textMuted = textPrimary;

  // ── Text Styles ──────────────────────────────────────────────────────────────
  static TextStyle get displayFont =>
      GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w700);

  static TextStyle get monoFont =>
      GoogleFonts.jetBrainsMono(color: textPrimary);

  static TextStyle get bodyFont => GoogleFonts.inter(color: textPrimary);

  // ── Theme ────────────────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: blue,
        error: red,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: displayFont.copyWith(fontSize: 32),
            displayMedium: displayFont.copyWith(fontSize: 24),
            titleLarge: displayFont.copyWith(fontSize: 18),
            titleMedium: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 15),
            bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 13),
            labelSmall: GoogleFonts.jetBrainsMono(
              color: textMuted,
              fontSize: 11,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: displayFont.copyWith(fontSize: 18, color: textPrimary),
        iconTheme: const IconThemeData(color: textSecondary),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: accent.withValues(),
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static Color pnlColor(double pnl) {
    if (pnl > 0) return accent;
    if (pnl < 0) return red;
    return amber;
  }

  static Color outcomeColor(String outcome) {
    switch (outcome) {
      case 'win':
        return accent;
      case 'loss':
        return red;
      default:
        return amber;
    }
  }
}
