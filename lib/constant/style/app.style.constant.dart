import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Core Colors
  static const Color primaryBlue = Color(
    0xFF3B82F6,
  ); // Bright blue from background
  static const Color darkBlue = Color(
    0xFF2563EB,
  ); // Deeper shade for gradient or hover
  static const Color accentColor = Color(0xFF60A5FA); // Lighter accent tone
  static const Color backgroundColor = Color(
    0xFFF9FAFB,
  ); // Light neutral background
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF1E3A8A); // Deep blue text
  static const Color textSecondaryColor = Color(
    0xFF475569,
  ); // Neutral secondary
  static const Color shadowColor = Color(
    0x1A000000,
  ); // Subtle shadow (10% opacity)

  // Refined palette
  static const Color primaryIndigo = Color(0xFF2563EB);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color mutedGray = Color(0xFFF3F4F6);

  // 🌗 Optional dark mode colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);

  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'Inter',
      primaryColor: primaryIndigo,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,

      // ✅ AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // ✅ Elevated Buttons (like "Get Started")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ✅ Text
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textSecondaryColor),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryColor),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),

      // ✅ Cards (like info containers)
      // cardTheme: CardTheme(
      //   color: cardColor,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //   elevation: 2,
      //   shadowColor: shadowColor,
      //   margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // ),

      // ✅ Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryIndigo.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: primaryIndigo.withOpacity(0.9),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),

      // ✅ Icon Colors
      iconTheme: const IconThemeData(color: primaryIndigo),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryIndigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),

      // ✅ Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryIndigo,
        secondary: accentTeal,
        surface: cardColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
      ),
    );
  }

  // 🌙 Optional dark theme for later
  static ThemeData get darkTheme {
    return theme.copyWith(
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentColor,
      ),
    );
  }
}
