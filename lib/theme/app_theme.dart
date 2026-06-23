import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sky's visual identity. A calm sky-blue palette with light & dark variants.
class AppTheme {
  AppTheme._();

  // Brand palette
  static const Color skyBlue = Color(0xFF1E88E5);
  static const Color skyBlueDark = Color(0xFF1565C0);
  static const Color skyAccent = Color(0xFF26C6DA);
  static const Color bubbleOutgoing = Color(0xFFD6EAFE);
  static const Color bubbleOutgoingDark = Color(0xFF144D8A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: skyBlue,
      brightness: Brightness.light,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: skyBlue,
      brightness: Brightness.dark,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0E1621),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: skyBlue,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
