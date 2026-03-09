import 'package:flutter/material.dart';

class AppColors {
  // Light Mode
  static const Color lightBackground = Color(0xFFF1F8E9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(
    0xFFE1EADD,
  ); // Stronger contrast (darker)
  static const Color lightPrimary = Color(0xFF2E7D32);
  static const Color lightText = Color(0xFF1B5E20);
  static const Color lightAlert = Color(0xFFC62828);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0A1A0A);
  static const Color darkSurface = Color(0xFF1B2E1B);
  static const Color darkCard = Color(
    0xFF1B301B,
  ); // Stronger contrast (lighter)
  static const Color darkPrimary = Color(0xFF66BB6A);
  static const Color darkText = Color(0xFFE8F5E9);
  static const Color darkDivider = Color(0xFF2D4F2D);
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white,
      onSurface: AppColors.lightText,
      error: AppColors.lightAlert,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.lightPrimary),
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      surface: AppColors.darkSurface,
      onPrimary: Colors.black,
      onSurface: AppColors.darkText,
      secondary: AppColors.darkDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.darkPrimary),
    ),
    useMaterial3: true,
  );
}

class AppConstants {
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'symbol': '\$'},
    {'code': 'EUR', 'symbol': '€'},
    {'code': 'MXN', 'symbol': '\$'},
    {'code': 'GBP', 'symbol': '£'},
    {'code': 'JPY', 'symbol': '¥'},
    {'code': 'CAD', 'symbol': '\$'},
    {'code': 'AUD', 'symbol': '\$'},
    {'code': 'BRL', 'symbol': 'R\$'},
    {'code': 'CHF', 'symbol': 'Fr'},
    {'code': 'CNY', 'symbol': '¥'},
    {'code': 'HKD', 'symbol': '\$'},
    {'code': 'IDR', 'symbol': 'Rp'},
    {'code': 'INR', 'symbol': '₹'},
    {'code': 'KRW', 'symbol': '₩'},
    {'code': 'NOK', 'symbol': 'kr'},
    {'code': 'NZD', 'symbol': '\$'},
    {'code': 'PLN', 'symbol': 'zł'},
    {'code': 'RUB', 'symbol': '₽'},
    {'code': 'SAR', 'symbol': '﷼'},
    {'code': 'SEK', 'symbol': 'kr'},
    {'code': 'SGD', 'symbol': '\$'},
    {'code': 'THB', 'symbol': '฿'},
    {'code': 'TRY', 'symbol': '₺'},
    {'code': 'TWD', 'symbol': 'NT\$'},
    {'code': 'ZAR', 'symbol': 'R'},
    {'code': 'COP', 'symbol': '\$'},
    {'code': 'ARS', 'symbol': '\$'},
    {'code': 'CLP', 'symbol': '\$'},
    {'code': 'PEN', 'symbol': 'S/'},
    {'code': 'VES', 'symbol': 'Bs.'},
  ];
}
