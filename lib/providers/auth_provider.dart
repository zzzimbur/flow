import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Геттеры
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String get userId => _user?.uid ?? '';
  
  AuthProvider() {
    // Слушаем изменения состояния аутентификации
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  // Регистрация нового пользователя
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Создаем пользователя в Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Обновляем displayName
      await userCredential.user?.updateDisplayName(name);
      
      // Создаем документ пользователя в Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'currency': '₽ Рубль',
        'theme': 'light',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Произошла неизвестная ошибка';
      notifyListeners();
      return false;
    }
  }
  
  // Вход пользователя
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Произошла неизвестная ошибка';
      notifyListeners();
      return false;
    }
  }
  
  // Выход пользователя
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
  
  // Сброс пароля
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }
  
  // Обновление профиля пользователя
  Future<bool> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      if (name != null && _user != null) {
        await _user!.updateDisplayName(name);
        await _firestore.collection('users').doc(_user!.uid).update({
          'name': name,
        });
      }
      
      if (email != null && _user != null) {
        await _user!.verifyBeforeUpdateEmail(email);
        await _firestore.collection('users').doc(_user!.uid).update({
          'email': email,
        });
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Не удалось обновить профиль';
      notifyListeners();
      return false;
    }
  }
  
  // Изменение пароля
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      if (_user == null) {
        throw Exception('Пользователь не авторизован');
      }
      
      // Реаутентификация пользователя
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      
      await _user!.reauthenticateWithCredential(credential);
      
      // Обновление пароля
      await _user!.updatePassword(newPassword);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }
  
  // Получение данных пользователя из Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Очистка ошибки
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Преобразование кодов ошибок Firebase в читаемые сообщения
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Проблемы с интернет-соединением';
      case 'requires-recent-login':
        return 'Требуется повторная авторизация';
      default:
        return 'Произошла ошибка: $code';
    }
  }
}