import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6C63FF);
  static const _accentColor = Color(0xFF00D9FF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: const Color(0xFFF8F9FA),
        onSurface: const Color(0xFF1A1A2E),
        surfaceContainer: const Color(0xFFEEEEEE),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF4A4A6A),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B6B8B),
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: _outlinedBorder,
        enabledBorder: _outlinedBorder,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _focusedErrorBorder,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B6B8B),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFA0A0C0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: const Color(0xFF121218),
        onSurface: const Color(0xFFE8E8F0),
        surfaceContainer: const Color(0xFF1E1E2A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A12),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8E8F0),
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8E8F0),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8E8F0),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8E8F0),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFA0A0C0),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF7B7B9B),
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E2A),
        border: _darkOutlinedBorder,
        enabledBorder: _darkOutlinedBorder,
        focusedBorder: _darkFocusedBorder,
        errorBorder: _darkErrorBorder,
        focusedErrorBorder: _darkFocusedErrorBorder,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF7B7B9B),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF4A4A6A),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static const _outlinedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: Color(0xFFE0E0E8),
      width: 1.5,
    ),
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: _primaryColor,
      width: 2,
    ),
  );

  static const _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: Color(0xFFE53935),
      width: 1.5,
    ),
  );

  static const _focusedErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: Color(0xFFE53935),
      width: 2,
    ),
  );

  static const _darkOutlinedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: Color(0xFF2E2E3E),
      width: 1.5,
    ),
  );

  static const _darkFocusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: _primaryColor,
      width: 2,
    ),
  );

  static const _darkErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: Color(0xFFEF5350),
      width: 1.5,
    ),
  );

  static const _darkFocusedErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(
      color: Color(0xFFEF5350),
      width: 2,
    ),
  );
}
