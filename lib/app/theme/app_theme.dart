import 'package:flutter/material.dart';

class AppTheme {
  // Colores modernos
  static const Color primaryBlue = Color(0xFF2196F3); // Azul moderno
  static const Color lightBlue = Color(0xFFE3F2FD); // Celeste suave
  static const Color softGreen = Color(0xFF4CAF50); // Verde suave
  static const Color softRed = Color(0xFFF44336); // Rojo suave
  static const Color backgroundGrey = Color(0xFFF5F5F5); // Gris de fondo suave

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
      ),
      scaffoldBackgroundColor: const Color(0xFFE3F2FD), // Celeste suave
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8E8E8),
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
        ),
      ),
      textTheme: const TextTheme(
        // Tipografía moderna y clara
        displayLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
