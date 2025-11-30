import 'package:flutter/material.dart';

class AppTheme {
  // Светлая тема - цвета
  static const Color lightPrimary = Color(0xFF1e293b);
  static const Color lightBackground = Color(0xFFf8fafc);
  static const Color lightCardColor = Color(0xFFffffff);
  static const Color lightTextPrimary = Color(0xFF1e293b);
  static const Color lightTextSecondary = Color(0xFF64748b);
  
  // Темная тема - цвета
  static const Color darkPrimary = Color(0xFF8b7ff5);
  static const Color darkBackground = Color(0xFF0f172a);
  static const Color darkCardColor = Color(0xFF1e293b);
  static const Color darkTextPrimary = Color(0xFFf8fafc);
  static const Color darkTextSecondary = Color(0xFF94a3b8);
  
  // Акцентные цвета (общие)
  static const Color accentPurple = Color(0xFF8b7ff5);
  static const Color accentYellow = Color(0xFFf4e4a7);
  static const Color accentBlack = Color(0xFF000000);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: accentPurple,
      surface: lightCardColor,
      background: lightBackground,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: accentPurple,
      surface: darkCardColor,
      background: darkBackground,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class AppColors {
  static const emerald50 = Color(0xFFecfdf5);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065f46);
  
  static const red50 = Color(0xFFfef2f2);
  static const red600 = Color(0xFFdc2626);
  static const red700 = Color(0xFFb91c1c);
  static const red800 = Color(0xFF991b1b);
  
  static const slate50 = Color(0xFFf8fafc);
  static const slate100 = Color(0xFFf1f5f9);
  static const slate200 = Color(0xFFe2e8f0);
  static const slate400 = Color(0xFF94a3b8);
  static const slate500 = Color(0xFF64748b);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1e293b);
  static const slate900 = Color(0xFF0f172a);
  
  // Цвета для темной темы
  static const dark50 = Color(0xFFf8fafc);
  static const dark100 = Color(0xFFe2e8f0);
  static const dark200 = Color(0xFF94a3b8);
  static const dark700 = Color(0xFF334155);
  static const dark800 = Color(0xFF1e293b);
  static const dark900 = Color(0xFF0f172a);
}