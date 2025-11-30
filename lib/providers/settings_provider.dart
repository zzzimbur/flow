import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Пользовательские данные
  String _userName = 'Александр';
  String _userEmail = 'alex@example.com';
  String _userPassword = '********';
  
  // Настройки приложения
  ThemeMode _themeMode = ThemeMode.light;
  String _currency = '₽ Рубль';
  
  // Геттеры
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPassword => _userPassword;
  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Сеттеры с уведомлением слушателей
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }
  
  void setUserEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }
  
  void setUserPassword(String password) {
    _userPassword = password;
    notifyListeners();
  }
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  void setCurrency(String curr) {
    _currency = curr;
    notifyListeners();
  }
  
  // Список доступных валют
  List<String> get availableCurrencies => [
    '₽ Рубль',
    '\$ Доллар',
    '€ Евро',
    '£ Фунт',
    '¥ Йена',
  ];
}