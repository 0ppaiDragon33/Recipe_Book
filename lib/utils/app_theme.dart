// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Dark Bistro Palette ────────────────────────────────────────────────────
  static const Color background = Color(0xFF141210);
  static const Color surface = Color(0xFF1E1B18);
  static const Color surfaceAlt = Color(0xFF252119);
  static const Color primary = Color(0xFFC8773A);
  static const Color primaryDim = Color(0xFF7A4420);
  static const Color secondary = Color(0xFF8BA888);
  static const Color accent = Color(0xFFD4A853);
  static const Color cream = Color(0xFFF2EBD9);
  static const Color textDark = Color(0xFFF2EBD9);
  static const Color textMid = Color(0xFFBDB5A6);
  static const Color textLight = Color(0xFF7A7168);
  static const Color divider = Color(0xFF2C2720);
  static const Color border = Color(0xFF38332D);
  static const Color error = Color(0xFFCF5A50);
  static const Color cardShadow = Color(0x40000000);

  // ── Light Palette (warm parchment feel) ────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F3EC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0EBE0);
  static const Color lightTextDark = Color(0xFF2A2118);
  static const Color lightTextMid = Color(0xFF5C4A38);
  static const Color lightTextLight = Color(0xFF9E8B78);
  static const Color lightBorder = Color(0xFFDDD4C5);
  static const Color lightDivider = Color(0xFFEBE3D8);

  // ── Dark theme builder ─────────────────────────────────────────────────────
  static ThemeData buildDark([double fontScale = 1.0]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(
          ThemeData.dark().textTheme, cream, textMid, textLight, fontScale),
      appBarTheme: _buildAppBarTheme(background, cream, textMid),
      inputDecorationTheme: _buildInputTheme(
          surfaceAlt, border, primary, error, textLight, cream, fontScale),
      elevatedButtonTheme: _buildButtonTheme(primary, cream),
      navigationBarTheme: _buildNavBarTheme(surface, primary, textLight),
    );
  }

  // ── Light theme builder ────────────────────────────────────────────────────
  static ThemeData buildLight([double fontScale = 1.0]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
        error: error,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: _buildTextTheme(ThemeData.light().textTheme, lightTextDark,
          lightTextMid, lightTextLight, fontScale),
      appBarTheme:
          _buildAppBarTheme(lightBackground, lightTextDark, lightTextMid),
      inputDecorationTheme: _buildInputTheme(lightSurfaceAlt, lightBorder,
          primary, error, lightTextLight, lightTextDark, fontScale),
      elevatedButtonTheme: _buildButtonTheme(primary, Colors.white),
      navigationBarTheme:
          _buildNavBarTheme(lightSurface, primary, lightTextLight),
    );
  }

  static TextTheme _buildTextTheme(
      TextTheme base, Color heading, Color body, Color muted, double scale) {
    return GoogleFonts.loraTextTheme(base).copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 52 * scale, fontWeight: FontWeight.w600, color: heading),
      displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 40 * scale, fontWeight: FontWeight.w600, color: heading),
      displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 30 * scale, fontWeight: FontWeight.w600, color: heading),
      headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 24 * scale, fontWeight: FontWeight.w600, color: heading),
      headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 20 * scale, fontWeight: FontWeight.w500, color: heading),
      titleLarge: GoogleFonts.dmSans(
          fontSize: 16 * scale, fontWeight: FontWeight.w600, color: heading),
      bodyLarge:
          GoogleFonts.lora(fontSize: 16 * scale, color: body, height: 1.75),
      bodyMedium:
          GoogleFonts.lora(fontSize: 14 * scale, color: body, height: 1.65),
      labelLarge: GoogleFonts.dmSans(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: heading),
      labelMedium: GoogleFonts.dmSans(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: muted),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color bg, Color title, Color icon) =>
      AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cormorantGaramond(
            fontSize: 22, fontWeight: FontWeight.w600, color: title),
        iconTheme: IconThemeData(color: icon),
      );

  static InputDecorationTheme _buildInputTheme(Color fill, Color borderCol,
          Color focus, Color err, Color hint, Color textColor, double scale) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderCol)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderCol)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focus, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: err, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: err, width: 1.5)),
        hintStyle: GoogleFonts.lora(color: hint, fontSize: 14 * scale),
        labelStyle: GoogleFonts.dmSans(color: hint, fontSize: 13 * scale),
        suffixIconColor: hint,
        prefixIconColor: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );

  static ElevatedButtonThemeData _buildButtonTheme(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation: 0,
        ),
      );

  static NavigationBarThemeData _buildNavBarTheme(
          Color bg, Color selected, Color unselected) =>
      NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: selected.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w500, color: unselected),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: selected);
          }
          return IconThemeData(color: unselected);
        }),
      );

  // Convenience getters (always returns dark values for hardcoded color refs)
  static ThemeData get dark => buildDark();
  static ThemeData get light => buildLight();
}
