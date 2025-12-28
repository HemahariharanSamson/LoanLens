import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  // Light Theme Colors - Minimalist & Subtle
  static const Color lightPrimary = Color(0xFF6B9BD2); // Soft blue
  static const Color lightPrimaryDark = Color(0xFF5A8BC4);
  static const Color lightBackground = Color(0xFFFAFAFA); // Very light gray
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFE57373); // Soft red
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF424242); // Soft dark gray
  static const Color lightOnSurface = Color(0xFF424242);
  
  // Accent Colors - Subtle pastels
  static const Color successColor = Color(0xFF81C784); // Soft green
  static const Color warningColor = Color(0xFFFFB74D); // Soft orange
  static const Color infoColor = Color(0xFF64B5F6); // Soft blue
  static const Color purpleAccent = Color(0xFFBA68C8); // Soft purple
  static const Color tealAccent = Color(0xFF4DB6AC); // Soft teal
  static const Color pinkAccent = Color(0xFFF48FB1); // Soft pink
  static const Color amberAccent = Color(0xFFFFD54F); // Soft amber
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        primaryContainer: lightPrimaryDark,
        secondary: Color(0xFF03DAC6),
        error: lightError,
        surface: lightSurface,
        onPrimary: lightOnPrimary,
        onSecondary: Color(0xFF000000),
        onError: Color(0xFFFFFFFF),
        onSurface: lightOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: lightSurface,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        titleTextStyle: TextStyle(
          color: lightOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: lightPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
      ),
    );
  }
  
}

