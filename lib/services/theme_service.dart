import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar el tema de la app (dark/light mode)
class ThemeService {
  static const String _keyThemeMode = 'theme_mode';
  static const int _lightMode = 0;
  static const int _darkMode = 1;
  static const int _systemMode = 2;

  // Colores del tema light
  static const Color primaryColor = Color(0xFF004B49);
  static const Color secondaryColor = Color(0xFF20C997);
  static const Color backgroundLight = Color(0xFFF4F6F7);
  static const Color surfaceLight = Colors.white;
  static const Color textLight = Color(0xFF1A1A1A);

  // Colores del tema dark
  static const Color primaryColorDark = Color(0xFF20C997);
  static const Color secondaryColorDark = Color(0xFF004B49);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFF5F5F5);

  /// Obtener tema actual
  static ThemeMode get currentMode {
    final prefs = SharedPreferences.getInstance();
    final mode = prefs.then((p) => p.getInt(_keyThemeMode) ?? _systemMode);
    return _intToThemeMode(mode);
  }

  /// Cambiar tema
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, _themeModeToInt(mode));
  }

  /// Theme mode como int
  static int _themeModeToInt(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return _lightMode;
      case ThemeMode.dark: return _darkMode;
      case ThemeMode.system: return _systemMode;
    }
  }

  /// Int a ThemeMode
  static ThemeMode _intToThemeMode(int value) {
    switch (value) {
      case _lightMode: return ThemeMode.light;
      case _darkMode: return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  /// Obtener tema light
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceLight,
        background: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardColor: surfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textLight),
        titleLarge: TextStyle(color: textLight),
        titleMedium: TextStyle(color: textLight),
      ),
    );
  }

  /// Obtener tema dark
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColorDark,
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        surface: surfaceDark,
        background: backgroundDark,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorDark,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        titleLarge: TextStyle(color: textDark),
        titleMedium: TextStyle(color: textDark),
      ),
    );
  }

  /// Alternar entre dark y light
  static Future<void> toggleTheme() async {
    final current = await currentMode;
    switch (current) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  /// Obtener modo actual como string
  static Future<String> getModeName() async {
    final mode = await currentMode;
    switch (mode) {
      case ThemeMode.light: return 'Claro';
      case ThemeMode.dark: return 'Oscuro';
      case ThemeMode.system: return 'Sistema';
    }
  }
}
