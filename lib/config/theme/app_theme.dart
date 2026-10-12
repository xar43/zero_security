import 'package:flutter/material.dart';

abstract class AppTheme {
  static const Color _primary = Color(0xFF14532d);
  static const Color _secondary = Color(0xFF22c55e);
  static const Color _error = Color(0xFFB00020);
  static const Color _kAppSurface = Color(0xFF111219);
  static const Color _kAppSurfaceContainer = Color(0xFFFFFFFF);
  static const Color _kAppOnPrimary = Color(0xFFFFFFFF);
  static const Color _kAppOnSecondary = Color(0xFFFFFFFF);
  static const Color _kAppOnError = Color(0xFFFFFFFF);
  static const Color _kAppOnSurface = Color(0xFFFFFFFF);
  static const Color _kAppOutline = Color(0xFFA6A2AA);
  static const Color _kAppOnSurfaceVariant = Color(0xFF49454F);
  static const _fontFamily = 'Poppins';

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    colorScheme: const ColorScheme.light(
      primary: _primary,
      error: _error,
      secondary: _secondary,
      surface: _kAppSurface,
      onPrimary: _kAppOnPrimary,
      onSecondary: _kAppOnSecondary,
      onError: _kAppOnError,
      onSurface: _kAppOnSurface,
      surfaceContainer: _kAppSurfaceContainer,
    ),
    scaffoldBackgroundColor: _kAppSurface,
    appBarTheme: AppBarTheme(
      toolbarHeight: 70,
      centerTitle: false,
      backgroundColor: _kAppSurface,
      foregroundColor: _kAppOnSurface,
      elevation: 0,
      shape: Border.fromBorderSide(BorderSide(color: _kAppOutline.withValues(alpha: .3))),
      actionsPadding: EdgeInsets.only(right: 16),
      titleTextStyle: TextStyle(color: _kAppSurface, fontSize: 22, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: _kAppSurface),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primary,
      foregroundColor: _kAppOnPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _kAppOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: _primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAppOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAppOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAppOnSurface),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error),
      ),
      filled: true,
      fillColor: _kAppSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      hintStyle: TextStyle(color: _kAppOutline, fontSize: 16),
      labelStyle: TextStyle(color: _kAppOnSurface, fontSize: 16),
      floatingLabelStyle: TextStyle(color: _kAppOnSurface, fontSize: 16),
    ),
    cardTheme: const CardThemeData(
      color: _kAppSurface,
      elevation: 1,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    dividerTheme: const DividerThemeData(color: _kAppOutline, thickness: .3, space: 1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _kAppSurface,
      selectedItemColor: _primary,
      unselectedItemColor: _kAppOnSurfaceVariant,
      elevation: 2,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _kAppSurface,
      indicatorColor: _primary,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: _kAppOnSurface)),
    ),
  );
}
