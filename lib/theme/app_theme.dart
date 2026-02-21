import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pastel Color Palette
  static const Color primaryPastel = Color(0xFF6C9EEB);
  static const Color secondaryPastel = Color(0xFFA78BFA);
  static const Color successPastel = Color(0xFF6FCF97);
  static const Color warningPastel = Color(0xFFF2C94C);
  static const Color dangerPastel = Color(0xFFEB5757);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPastel,
      primary: primaryPastel,
      secondary: secondaryPastel,
      surface: backgroundLight,
      error: dangerPastel,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
      bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPastel,
      primary: primaryPastel,
      secondary: secondaryPastel,
      surface: backgroundDark,
      error: dangerPastel,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
      bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF1E293B),
    ),
  );
}
