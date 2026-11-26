import 'package:flutter/material.dart';

/// Navy / emerald / gold identity, matching the PWA (artifact lmw-dhn-ldhky)
/// and the user's supplied logo (navy + gold, mosque/minaret/crescent).
class AppTheme {
  static const Color navy = Color(0xFF0B1F4B);
  static const Color navyDark = Color(0xFF071633);
  static const Color emerald = Color(0xFF0E7C5B);
  static const Color gold = Color(0xFFC9A227);
  static const Color warmWhite = Color(0xFFFAF6EE);
  static const Color ink = Color(0xFF1A1A1A);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald,
        primary: emerald,
        secondary: gold,
        surface: warmWhite,
      ),
      scaffoldBackgroundColor: warmWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: emerald,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 17),
        bodyMedium: TextStyle(fontSize: 15),
      ),
    );
  }

  static ThemeData dark() {
    final base = light();
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navyDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald,
        brightness: Brightness.dark,
        primary: emerald,
        secondary: gold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDark,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}
