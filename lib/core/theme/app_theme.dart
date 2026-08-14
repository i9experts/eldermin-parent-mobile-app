import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Exact palette from the approved mockup (eldermin_parent_app_v2.html),
/// not an approximation - every hex here matches a CSS var in that file.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF10253A);
  static const Color muted = Color(0xFF6C7D8E);
  static const Color faint = Color(0xFF94A3B2);
  static const Color line = Color(0xFFE6EDF3);
  static const Color canvas = Color(0xFFEEF4F8);

  static const Color navy = Color(0xFF0A3158);
  static const Color blue = Color(0xFF1768AA);
  static const Color sky = Color(0xFF4C98D2);
  static const Color pale = Color(0xFFE9F4FC);
  static const Color amber = Color(0xFFF5A623);
  static const Color amberBg = Color(0xFFFFF3DC);
  static const Color amberText = Color(0xFFB86C00);

  static const Color green = Color(0xFF25A878);
  static const Color greenBg = Color(0xFFE7F8F1);
  static const Color greenText = Color(0xFF18835C);
  static const Color red = Color(0xFFE35A65);
  static const Color redBg = Color(0xFFFEECEF);
  static const Color redText = Color(0xFFC83E4D);
  static const Color purple = Color(0xFF7A63D2);
  static const Color purpleBg = Color(0xFFF0EDFF);

  static const List<Color> heroGradient = [navy, Color(0xFF155D96), Color(0xFF237FBD)];

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5F8FB);
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 13;
  static const double lg = 19;
  static const double xl = 23;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

/// Semantic color pairs (foreground + tinted background) for badges/tags,
/// matching the mockup's .tag / .tag.amber / .tag.green / .tag.red classes.
class TagStyle {
  final Color fg;
  final Color bg;
  const TagStyle(this.fg, this.bg);

  static const info = TagStyle(AppColors.blue, AppColors.pale);
  static const amber = TagStyle(AppColors.amberText, AppColors.amberBg);
  static const green = TagStyle(AppColors.greenText, AppColors.greenBg);
  static const red = TagStyle(AppColors.redText, AppColors.redBg);
  static const neutral = TagStyle(AppColors.muted, AppColors.line);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -1),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 23, letterSpacing: -0.75),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.navy, fontSize: 18),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.navy, fontSize: 14),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 13),
      bodyLarge: GoogleFonts.inter(color: AppColors.ink, fontSize: 15),
      bodyMedium: GoogleFonts.inter(color: AppColors.muted, fontSize: 12.5),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.navy,
        secondary: AppColors.amber,
        error: AppColors.red,
        surface: AppColors.surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.blue)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.red)),
        hintStyle: const TextStyle(color: AppColors.faint),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.faint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
