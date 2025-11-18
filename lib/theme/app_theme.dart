import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color backgroundColor = Color(0xFF1C1C1E);
  static const Color scaffoldBackgroundColor = Color(0xFF1C1C1E);
  static const Color primaryColor = Color(0xFF0A84FF);
  static const Color cardColor = Color(0xFF2C2C2E);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,

    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      surface: cardColor,
    ),

    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.normal, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.white70),
        labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      iconTheme: IconThemeData(color: primaryColor),
    ),

    cardTheme: CardThemeData(  // Changed from CardTheme to CardThemeData
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryColor;
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return Colors.grey;
      }),
    ),
  );
}
