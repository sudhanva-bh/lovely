import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Constants ---

  // Pink Palette (Female / Default)
  static const pinkPrimary = Color(0xFFEC407A); // Rose Pink
  static const pinkSecondary = Color(0xFFF8BBD0); // Soft Blush
  static const pinkAccent = Color(0xFF8E2456); // Deep Wine
  static const pinkBackground = Color(0xFFFFF5F8); // Creamy pink

  // Blue Palette (Male)
  static const bluePrimary = Color(0xFF42A5F5); // Soft Blue
  static const blueSecondary = Color(0xFFBBDEFB); // Pale Blue
  static const blueAccent = Color(0xFF1565C0); // Deep Blue
  static const blueBackground = Color(0xFFF0F7FF); // Alice Blue

  // Black/Monochrome Palette (Other)
  static const blackPrimary = Color(0xFF212121); // Almost Black
  static const blackSecondary = Color(0xFF9E9E9E); // Grey
  static const blackAccent = Color(0xFF000000); // Pure Black
  static const blackBackground = Color(0xFFFAFAFA); // Off White (Crisp)

  // --- Dynamic Theme Generator ---
  static ThemeData getThemeForGender(String? gender) {
    if (gender == 'Male') {
      return _buildTheme(
        primary: bluePrimary,
        secondary: blueSecondary,
        tertiary: blueAccent,
        background: blueBackground,
        surface: Colors.white,
      );
    } else if (gender == 'Other') {
      return _buildTheme(
        primary: blackPrimary,
        secondary: blackSecondary,
        tertiary: blackAccent,
        background: blackBackground,
        surface: Colors.white,
      );
    } else {
      // Default / Female
      return lightTheme;
    }
  }

  // --- Theme Builders ---

  static final lightTheme = _buildTheme(
    primary: pinkPrimary,
    secondary: pinkSecondary,
    tertiary: pinkAccent,
    background: pinkBackground,
    surface: Colors.white,
  );

  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Color background,
    required Color surface,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.black87,
        tertiary: tertiary,
        onTertiary: Colors.white,
        background: background,
        onBackground: Colors.black87,
        surface: surface,
        onSurface: Colors.black87,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      
      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w600,
          color: primary, 
        ),
      ),

      // Component Themes
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        shadowColor: primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Input Decoration (used in Setup)
      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: primary,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  // Keep existing dark theme as is, or updated if needed. 
  // (Currently not used by main.dart but good to keep for reference)
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFEC407A),
      onPrimary: Colors.white,
      secondary: Color(0xFFF48FB1),
      onSecondary: Colors.black,
      tertiary: Color(0xFF8E2456),
      onTertiary: Colors.white,
      background: Color(0xFF0D060A),
      onBackground: Color(0xFFEDEDED),
      surface: Color(0xFF1A0D14),
      onSurface: Color(0xFFE0E0E0),
      error: Colors.redAccent,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D060A),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: const TextStyle(color: Color(0xFFE0E0E0)),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1F1018),
      elevation: 4,
      shadowColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFEC407A),
      foregroundColor: Colors.white,
    ),
    dividerColor: const Color(0xFF2A1620),
  );
}