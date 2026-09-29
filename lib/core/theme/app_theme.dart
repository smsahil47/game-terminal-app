import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF05070E);
  static const surface = Color(0xFF0E1421);
  static const accent = Color(0xFF6074FF);
  static const success = Color(0xFF35D399);
  static const warning = Color(0xFFE0A93F);

  static ThemeData get dark {
    final colors =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ).copyWith(
          surface: surface,
          primary: accent,
          onSurface: const Color(0xFFEDF1FA),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF222C41)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
      ),
    );
  }
}
