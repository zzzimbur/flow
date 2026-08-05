import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Класс для хранения информации о цветовой теме
class ColorTheme {
  final String name;
  final Color lightAccent;
  final Color darkAccent;
  final String id;

  const ColorTheme({
    required this.name,
    required this.lightAccent,
    required this.darkAccent,
    required this.id,
  });
}

class SettingsProvider extends ChangeNotifier {
  // Пользовательские данные
  String _userName = '';
  String _userEmail = '';
  String _userPassword = '********';
  String _userId = '';
  
  // Настройки приложения
  ThemeMode _themeMode = ThemeMode.dark;
  String _currency = '₽ Рубль';
  String _selectedThemeId = 'purple'; // ID выбранной темы
  bool _isLoaded = false; // Флаг загрузки настроек
  bool _isFirstLaunch = true;
  SharedPreferences? _prefs;

  // Геттеры
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPassword => _userPassword;
  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get selectedThemeId => _selectedThemeId;
  bool get isLoaded => _isLoaded; // Геттер для проверки загрузки
  bool get isFirstLaunch => _isFirstLaunch;
  String get currencySymbol => _currency.isNotEmpty ? _currency.split(' ')[0] : '₽';

  String _userRole = 'employee'; // 'employee' или 'accountant'
  String get userRole => _userRole;
  bool get isAccountant => _userRole == 'accountant';

  // Доступные темы
  static const List<ColorTheme> _availableThemes = [
    ColorTheme(
      name: 'Фиолетовая',
      lightAccent: Color(0xFF8b7ff5),
      darkAccent: Color(0xFF8b7ff5),
      id: 'purple',
    ),
    ColorTheme(
      name: 'Синяя',
      lightAccent: Color(0xFF007AFF),
      darkAccent: Color(0xFF0A84FF),
      id: 'blue',
    ),
    ColorTheme(
      name: 'Зелёная',
      lightAccent: Color(0xFF059669),
      darkAccent: Color(0xFF10b981),
      id: 'green',
    ),
    ColorTheme(
      name: 'Розовая',
      lightAccent: Color(0xFFec4899),
      darkAccent: Color(0xFFf472b6),
      id: 'pink',
    ),
    ColorTheme(
      name: 'Оранжевая',
      lightAccent: Color(0xFFf97316),
      darkAccent: Color(0xFFfb923c),
      id: 'orange',
    ),
    ColorTheme(
      name: 'Бирюзовая',
      lightAccent: Color(0xFF06b6d4),
      darkAccent: Color(0xFF22d3ee),
      id: 'cyan',
    ),
    ColorTheme(
      name: 'Красная',
      lightAccent: Color(0xFFdc2626),
      darkAccent: Color(0xFFef4444),
      id: 'red',
    ),
    ColorTheme(
      name: 'Индиго',
      lightAccent: Color(0xFF4f46e5),
      darkAccent: Color(0xFF6366f1),
      id: 'indigo',
    ),
  ];
  
  // Получить текущую тему
  ColorTheme get currentTheme {
    return _availableThemes.firstWhere(
      (theme) => theme.id == _selectedThemeId,
      orElse: () => _availableThemes[0], // По умолчанию фиолетовая
    );
  }
  
  // Получить акцентный цвет для текущей темы
  Color get accentColor {
    return isDarkMode ? currentTheme.darkAccent : currentTheme.lightAccent;
  }
  
  // Получить список доступных тем
  List<ColorTheme> get availableThemes => _availableThemes;
  
  // Сеттеры с уведомлением слушателей
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
    // Сохраняем имя в Firestore при каждом изменении
    if (_userId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .set({'name': name}, SetOptions(merge: true));
    }
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
    _saveToPrefs();
  }
  

  Future<void> _loadFromPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    final isDark = _prefs!.getBool('isDarkMode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _currency = _prefs!.getString('currency') ?? '₽ Рубль';
    _selectedThemeId = _prefs!.getString('themeId') ?? 'purple';
  }

  Future<void> _saveToPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('isDarkMode', isDarkMode);
    await _prefs!.setString('currency', _currency);
    await _prefs!.setString('themeId', _selectedThemeId);
  }

  Future<void> _saveToFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'isDarkMode': isDarkMode,
        'themeId': _selectedThemeId,
        'currency': _currency,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Ошибка сохранения настроек: $e');
    }
  }

  void toggleTheme(bool isDark, {String? userId}) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    _saveToPrefs();
    final uid = userId ?? _userId;
    if (uid.isNotEmpty) {
      _saveToFirestore(uid);
    }
  }

  void setCurrency(String curr) {
    _currency = curr;
    notifyListeners();
    _saveToPrefs();
    if (_userId.isNotEmpty) {
      _saveToFirestore(_userId);
    }
  }

  void setAccentTheme(String themeId) {
    _selectedThemeId = themeId;
    notifyListeners();
    _saveToPrefs();
    if (_userId.isNotEmpty) {
      _saveToFirestore(_userId);
    }
  }
  
  // Инициализация настроек
  Future<void> initialize(String userId, {String? firebaseDisplayName}) async {
    _userId = userId;

    // Загружаем из локального хранилища сначала — мгновенная отрисовка
    await _loadFromPrefs();
    notifyListeners();

    if (userId.isEmpty) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      // Загружаем данные пользователя из Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();

        // Firebase Auth displayName имеет приоритет над Firestore
        // (пользователь мог сменить имя через Auth, но Firestore не обновился)
        final firestoreName = data?['name'] as String?;
        if (firebaseDisplayName != null && firebaseDisplayName.isNotEmpty &&
            firebaseDisplayName != firestoreName) {
          _userName = firebaseDisplayName;
          // Синхронизируем Firestore с Firebase Auth
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({'name': firebaseDisplayName}, SetOptions(merge: true));
        } else {
          _userName = firestoreName ?? firebaseDisplayName ?? '';
        }

        // Загружаем настройки
        _userEmail = data?['email'] ?? _userEmail;
        _selectedThemeId = data?['themeId'] ?? 'purple';
        _currency = data?['currency'] ?? '₽ Рубль';
        
        // Проверяем, завершен ли онбординг
        _isFirstLaunch = data?['onboardingCompleted'] != true;
        _userRole = data?['role'] ?? 'employee';

        // Загружаем тему
        final isDark = data?['isDarkMode'] ?? true;
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

        // Кешируем в локальное хранилище для следующего запуска
        await _saveToPrefs();
      } else {
        // Документ не существует - первый запуск
        _isFirstLaunch = true;
      }
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding(String userId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .set({'onboardingCompleted': true}, SetOptions(merge: true));
      
  _isFirstLaunch = false;
  notifyListeners();
}
  
  // Очистить данные пользователя (для выхода)
  void clearData() {
    _userName = '';
    _userEmail = '';
    _userPassword = '';
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