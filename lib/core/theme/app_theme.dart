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
  static const Color primaryNavy = Color(0xFF0F3A88);
  static const Color primaryContainer = Color(0xFF133B9C);
  static const Color electricCobalt = Color(0xFF0B5AE6);
  static const Color deepBlue = Color(0xFF0A2E75);
  static const Color softBlue = Color(0xFFEAF1FF);
  static const Color accentAqua = Color(0xFF14C5D7);

  // Light Surface Colors
  static const Color canvasBackground = Color(0xFFF5F2ED);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFEAF0F6);
  static const Color borderSubtle = Color(0xFFD9E1EC);

  // Dark Surface Colors
  static const Color darkCanvasBackground = Color(0xFF090D16);
  static const Color darkSurfaceCard = Color(0xFF111827);
  static const Color darkSurfaceSubtle = Color(0xFF1F2937);
  static const Color darkBorderSubtle = Color(0xFF374151);

  // Text Colors (Light)
  static const Color textHeading = Color(0xFF10213D);
  static const Color textBody = Color(0xFF3E4658);
  static const Color textMuted = Color(0xFF72809C);
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
  static const Color successText = Color(0xFF0E9F68);
  static const Color successBg = Color(0xFFE8FFF5);
  static const Color darkSuccessBg = Color(0xFF064E3B);

  static const Color warningText = Color(0xFFE3A200);
  static const Color warningBg = Color(0xFFFFF2D9);
  static const Color darkWarningBg = Color(0xFF78350F);

  static const Color urgentText = Color(0xFFE45757);
  static const Color urgentBg = Color(0xFFFDEAEA);
  static const Color darkUrgentBg = Color(0xFF7F1D1D);
  
  static const Color academicText = Color(0xFF4338CA);
  static const Color academicBg = Color(0xFFEEF2FF);
  static const Color darkAcademicBg = Color(0xFF312E81);

  static const Color batchText = Color(0xFF6D28D9);
  static const Color batchBg = Color(0xFFF5F3FF);
  static const Color darkBatchBg = Color(0xFF4C1D95);

  // Dynamic Theme-Aware Getters (Context-based)
  static Color getCanvasBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCanvasBackground : canvasBackground;

  static Color getSurfaceCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceCard : surfaceWhite;

  static Color getSurfaceSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceSubtle : surfaceSubtle;

  static Color getBorderSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorderSubtle : borderSubtle;

  static Color getTextHeading(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextHeading : textHeading;

  static Color getTextBody(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextBody : textBody;

  static Color getTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : textMuted;

  static Color getSuccessBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSuccessBg : successBg;

  static Color getWarningBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkWarningBg : warningBg;

  static Color getUrgentBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkUrgentBg : urgentBg;

  static Color getAcademicBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkAcademicBg : academicBg;

  static Color getBatchBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBatchBg : batchBg;

  static List<BoxShadow> getCardShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? [
              const BoxShadow(
                color: Color(0x40000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ]
          : level1Shadow;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasBackground,
      primaryColor: primaryNavy,
      cardColor: surfaceWhite,
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textHeading,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textBody,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        modalBackgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceWhite,
        textStyle: GoogleFonts.inter(color: textHeading, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1),
      iconTheme: const IconThemeData(color: primaryNavy),
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        onPrimary: Colors.white,
        primaryContainer: softBlue,
        onPrimaryContainer: primaryNavy,
        secondary: electricCobalt,
        onSecondary: Colors.white,
        surface: surfaceWhite,
        onSurface: textHeading,
        surfaceContainer: surfaceWhite,
        surfaceContainerHighest: surfaceSubtle,
        error: urgentText,
        onError: Colors.white,
        outline: borderSubtle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: borderSubtle, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electricCobalt,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electricCobalt,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryNavy,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electricCobalt,
        linearTrackColor: softBlue,
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
        titleTextStyle: TextStyle(color: textHeading, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textMuted,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: electricCobalt,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: textMuted,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: urgentText,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricCobalt, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: urgentText, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: urgentText, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvasBackground,
      primaryColor: electricCobalt,
      cardColor: darkSurfaceCard,
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkTextHeading,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: darkTextBody,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceCard,
        modalBackgroundColor: darkSurfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurfaceCard,
        textStyle: GoogleFonts.inter(color: darkTextHeading, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(color: darkBorderSubtle, thickness: 1),
      iconTheme: const IconThemeData(color: darkTextHeading),
      colorScheme: const ColorScheme.dark(
        primary: electricCobalt,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1E3A8A),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF6366F1),
        onSecondary: Colors.white,
        surface: darkSurfaceCard,
        onSurface: darkTextHeading,
        surfaceContainer: darkSurfaceCard,
        surfaceContainerHighest: darkSurfaceSubtle,
        error: urgentText,
        onError: Colors.white,
        outline: darkBorderSubtle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: darkBorderSubtle, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electricCobalt,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electricCobalt,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceCard,
        contentTextStyle: GoogleFonts.inter(color: darkTextHeading, fontSize: 13, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: electricCobalt,
        linearTrackColor: Color(0xFF1E293B),
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
        titleTextStyle: TextStyle(color: darkTextHeading, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceCard,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: darkTextMuted,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: electricCobalt,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: darkTextMuted,
        ),
        prefixIconColor: darkTextMuted,
        suffixIconColor: darkTextMuted,
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: urgentText,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricCobalt, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: urgentText, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: urgentText, width: 1.5),
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

