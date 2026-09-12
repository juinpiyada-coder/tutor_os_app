import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global Theme Mode State
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeModeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  // Brand Colors (TutorOS Mobile Admin)
  static const Color primaryNavy = Color(0xFF000318);
  static const Color primaryContainer = Color(0xFF0D1B44);
  static const Color electricCobalt = Color(0xFF0051D5);
  
  // Light Surface Colors
  static const Color canvasBackground = Color(0xFFF8F9FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFEFF4FF);
  static const Color borderSubtle = Color(0xFFC6C6D0);

  // Dark Surface Colors
  static const Color darkCanvasBackground = Color(0xFF090D16);
  static const Color darkSurfaceCard = Color(0xFF111827);
  static const Color darkSurfaceSubtle = Color(0xFF1F2937);
  static const Color darkBorderSubtle = Color(0xFF374151);

  // Text Colors (Light)
  static const Color textHeading = Color(0xFF0B1C30);
  static const Color textBody = Color(0xFF45464E);
  static const Color textMuted = Color(0xFF76767F);
  static const Color textPrimary = textHeading;
  static const Color textSecondary = textMuted;
  static const Color textTertiary = textMuted;
  static const Color textDark = textHeading;

  // Text Colors (Dark)
  static const Color darkTextHeading = Color(0xFFF8FAFC);
  static const Color darkTextBody = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextPrimary = darkTextHeading;
  static const Color darkTextSecondary = darkTextMuted;

  // Status Colors (Semantic)
  static const Color successText = Color(0xFF047857);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color darkSuccessBg = Color(0xFF064E3B);
  
  static const Color warningText = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color darkWarningBg = Color(0xFF78350F);
  
  static const Color urgentText = Color(0xFFB91C1C);
  static const Color urgentBg = Color(0xFFFEF2F2);
  static const Color darkUrgentBg = Color(0xFF7F1D1D);
  
  static const Color academicText = Color(0xFF4338CA);
  static const Color academicBg = Color(0xFFEEF2FF);
  static const Color darkAcademicBg = Color(0xFF312E81);

  static const Color batchText = Color(0xFF6D28D9);
  static const Color batchBg = Color(0xFFF5F3FF);
  static const Color darkBatchBg = Color(0xFF4C1D95);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasBackground,
      primaryColor: primaryNavy,
      cardColor: surfaceWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        secondary: electricCobalt,
        surface: surfaceWhite,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.48,
          height: 32 / 24,
          color: textHeading,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.27,
          height: 24 / 18,
          color: textHeading,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.44,
          height: 28 / 22,
          color: textHeading,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          height: 20 / 15,
          color: textHeading,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 18 / 13,
          color: textBody,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 16 / 12,
          color: textBody,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
          letterSpacing: 0.12,
          color: textHeading,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 14 / 11,
          letterSpacing: 0.22,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryNavy),
        titleTextStyle: TextStyle(color: textHeading),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricCobalt, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvasBackground,
      primaryColor: electricCobalt,
      cardColor: darkSurfaceCard,
      colorScheme: const ColorScheme.dark(
        primary: electricCobalt,
        secondary: Color(0xFF6366F1),
        surface: darkSurfaceCard,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.48,
          height: 32 / 24,
          color: darkTextHeading,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.27,
          height: 24 / 18,
          color: darkTextHeading,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.44,
          height: 28 / 22,
          color: darkTextHeading,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          height: 20 / 15,
          color: darkTextHeading,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 18 / 13,
          color: darkTextBody,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 16 / 12,
          color: darkTextBody,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
          letterSpacing: 0.12,
          color: darkTextHeading,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 14 / 11,
          letterSpacing: 0.22,
          color: darkTextMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCanvasBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextHeading),
        titleTextStyle: TextStyle(color: darkTextHeading),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceCard,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: darkTextMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1),
        ),
      ),
    );
  }

  // Elevation BoxShadows (SaaS Minimalist)
  static List<BoxShadow> get level1Shadow => [
    const BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    const BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 8,
      spreadRadius: -2,
      offset: Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get level2Shadow => [
    const BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
    const BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 4,
      spreadRadius: -1,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get level3Shadow => [
    const BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];
}

