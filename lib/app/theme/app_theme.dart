import 'package:flutter/material.dart';

class AppTheme {
  // Colores modernos
  static const Color primaryBlue = Color(0xFF2196F3); // Azul moderno
  static const Color lightBlue = Color(0xFFD9EDF7); // Celeste verdoso
  /// Borde superior de cards: tono suave que hace juego con el fondo celeste.
  static const Color cardTopAccentBlue = Color(0xFF7AB5D6);
  static const Color cardTopAccentBlueDark = Color(0xFF6B9BB3);
  /// Variación: tonos suaves para UX (menos “neón” que Bootstrap; legibles sobre card clara).
  /// Verde tirando a teal; rojo tipo coral/ladrillo apagado.
  static const Color softGreen = Color(0xFF1A8B73);
  static const Color softRed = Color(0xFFC75C5C);
  /// Sin variación (≈0%): barra superior y coherencia con indicadores.
  static const Color variationNeutral = Color(0xFF8B9BAA);
  static const Color backgroundGrey = Color(0xFFF5F5F5); // Gris de fondo suave

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
      ),
      scaffoldBackgroundColor: const Color(0xFFD9EDF7), // Celeste verdoso
      appBarTheme: const AppBarTheme(
        backgroundColor:
            Color(0xFFD9EDF7), // Celeste verdoso (mismo que el fondo)
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
      cardTheme: CardTheme(
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212), // Negro profundo
      appBarTheme: const AppBarTheme(
        backgroundColor:
            Color(0xFF121212), // Negro profundo (mismo que el fondo)
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C), // Gris oscuro para divisores
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E), // Gris muy oscuro para cards
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Color(0xFFB0B0B0), // Gris claro para texto secundario
        ),
      ),
    );
  }
}
