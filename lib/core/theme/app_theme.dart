import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF05070E);
  static const surface = Color(0xFF0A0E1A);
  static const surface2 = Color(0xFF0E1421);
  static const surface3 = Color(0xFF141B2B);
  static const border = Color(0xFF19202F);
  static const border2 = Color(0xFF222C41);
  static const accent = Color(0xFF4F63F0);
  static const brand = Color(0xFF2563EB);
  static const text = Color(0xFFEDF1FA);
  static const textSecondary = Color(0xFF93A0BA);
  static const textMuted = Color(0xFF64718C);
  static const success = Color(0xFF35D399);
  static const warning = Color(0xFFE0A93F);
  static const danger = Color(0xFFF0656A);

  static ThemeData get dark {
    final colors =
        ColorScheme.fromSeed(
          seedColor: brand,
          brightness: Brightness.dark,
        ).copyWith(
          surface: surface,
          primary: brand,
          onPrimary: Colors.white,
          onSurface: text,
          outline: border2,
          error: danger,
        );
    const rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: border),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      fontFamily: 'Geist',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, height: 1.45, color: textMuted),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: border)),
        toolbarHeight: 60,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 5),
        shape: rounded,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        iconColor: textSecondary,
        textColor: text,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface2,
        shape: rounded,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 40),
          side: const BorderSide(color: border2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          minimumSize: const Size(0, 36),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: brand.withValues(alpha: .18),
        side: const BorderSide(color: border2),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: const PopupMenuThemeData(color: surface2),
      drawerTheme: const DrawerThemeData(backgroundColor: surface, width: 236),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand),
    );
  }
}
