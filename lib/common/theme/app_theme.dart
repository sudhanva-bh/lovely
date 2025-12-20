import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Romantic palette
  static const primaryColor = Color(0xFFEC407A); // Rose Pink
  static const secondaryColor = Color(0xFFF8BBD0); // Soft Blush
  static const accentColor = Color(0xFF8E2456); // Deep Wine
  static const lightBackground = Color(0xFFFFF5F8); // Creamy pink
  static const darkBackground = Color(0xFF1A0F14); // Plum black

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.black87,
      tertiary: accentColor,
      onTertiary: Colors.white,
      background: lightBackground,
      onBackground: Colors.black87,
      surface: Colors.white,
      onSurface: Colors.black87,
      error: Colors.redAccent,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: lightBackground,

    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w600,
      ),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: primaryColor,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shadowColor: primaryColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,

      // Romantic accents
      primary: Color(0xFFEC407A), // Rose pink
      onPrimary: Colors.white,
      secondary: Color(0xFFF48FB1), // Muted blush
      onSecondary: Colors.black,

      // Deep accent
      tertiary: Color(0xFF8E2456), // Wine
      onTertiary: Colors.white,

      // TRUE darks
      background: Color(0xFF0D060A), // Almost black plum
      onBackground: Color(0xFFEDEDED),
      surface: Color(0xFF1A0D14), // Dark plum surface
      onSurface: Color(0xFFE0E0E0),

      error: Colors.redAccent,
      onError: Colors.black,
    ),

    scaffoldBackgroundColor: const Color(0xFF0D060A),

    textTheme:
        GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: const TextStyle(
            color: Color(0xFFE0E0E0),
          ),
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
