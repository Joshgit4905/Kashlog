import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/home_widget_service.dart';

class UserProvider with ChangeNotifier {
  String _name = '';
  int _age = 0;
  String _currencyCode = 'USD';
  String _currencySymbol = '\$';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isOnboarded = false;
  bool _isInitialBalanceSet = false;
  bool _isSteganographyMode = false;
  bool _isDeveloperMode = false;

  String get name => _name;
  int get age => _age;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  ThemeMode get themeMode => _themeMode;
  bool get isOnboarded => _isOnboarded;
  bool get isInitialBalanceSet => _isInitialBalanceSet;
  bool get isSteganographyMode => _isSteganographyMode;
  bool get isDeveloperMode => _isDeveloperMode;

  UserProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? '';
    _age = prefs.getInt('user_age') ?? 0;
    _currencyCode = prefs.getString('currency_code') ?? 'USD';
    _currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    _isOnboarded = prefs.getBool('is_onboarded') ?? false;
    _isInitialBalanceSet = prefs.getBool('is_initial_balance_set') ?? false;
    _isSteganographyMode = prefs.getBool('is_steganography_mode') ?? false;
    _isDeveloperMode = prefs.getBool('is_developer_mode') ?? false;

    final themeString = prefs.getString('theme_mode') ?? 'light';
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setUserProfile(
    String name,
    int age,
    String currencyCode,
    String currencySymbol,
  ) async {
    _name = name;
    _age = age;
    _currencyCode = currencyCode;
    _currencySymbol = currencySymbol;
    _isOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_age', age);
    await prefs.setString('currency_code', currencyCode);
    await prefs.setString('currency_symbol', currencySymbol);
    await prefs.setBool('is_onboarded', true);

    // Sync widget
    await HomeWidgetService.updateWidget(currency: currencyCode);

    notifyListeners();
  }

  Future<void> setInitialBalanceSet(bool value) async {
    _isInitialBalanceSet = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_initial_balance_set', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';
    await prefs.setString('theme_mode', themeString);
    notifyListeners();
  }

  Future<void> setSteganographyMode(bool value) async {
    _isSteganographyMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_steganography_mode', value);
    notifyListeners();
  }

  Future<void> setDeveloperMode(bool value) async {
    _isDeveloperMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_developer_mode', value);
    notifyListeners();
  }
}
