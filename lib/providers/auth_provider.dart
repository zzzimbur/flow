import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

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

  String get userName => _user?.displayName ?? '';
  
  // Автоматический вход для разработки
  Future<bool> autoSignInForDevelopment() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      const testEmail = 'test@flow.com';
      const testPassword = 'test123456';
      const testName = 'Тестовый пользователь';
      
      try {
        // Пытаемся войти
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        _user = userCredential.user;
      } catch (e) {
        // Если пользователя нет, создаём его
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        
        // Обновляем displayName
        await userCredential.user?.updateDisplayName(testName);
        
        // Создаем документ пользователя в Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': testName,
          'email': testEmail,
          'currency': '₽ Рубль',
          'theme': 'light',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        _user = userCredential.user;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Ошибка автоматического входа: $e');
      _isLoading = false;
      _errorMessage = 'Ошибка автоматического входа';
      notifyListeners();
      return false;
    }
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
        'role': 'employee',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Отправляем письмо с подтверждением
      await userCredential.user?.sendEmailVerification();

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

  // Повторная отправка письма с подтверждением
  Future<void> resendVerificationEmail() async {
    await _user?.sendEmailVerification();
  }

  // Обновить данные пользователя (для проверки верификации)
  Future<void> reloadUser() async {
    await _user?.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  bool get isEmailVerified => _user?.emailVerified ?? false;

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
    await GoogleSignIn().signOut().catchError((_) => null);
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
  
  // ─── Google Sign-In ──────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      await _ensureUserDoc(userCred.user!);
      _user = userCred.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ошибка входа через Google';
      notifyListeners();
      return false;
    }
  }

  // ─── Yandex ID ───────────────────────────────────────────────────
  Future<bool> signInWithYandex() async {
    return _signInWithOAuth(
      provider: 'yandex',
      authUrl: 'https://flow-ai.prostozapaska.workers.dev/auth/yandex',
      displayName: 'Yandex ID',
    );
  }

  // ─── Telegram ────────────────────────────────────────────────────
  Future<bool> signInWithTelegram() async {
    return _signInWithOAuth(
      provider: 'telegram',
      authUrl: 'https://flow-ai.prostozapaska.workers.dev/auth/telegram',
      displayName: 'Telegram',
    );
  }

  Future<bool> _signInWithOAuth({
    required String provider,
    required String authUrl,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final completer = Completer<String?>();

      // Слушаем входящий deep link flowapp://oauth?token=...
      final appLinks = AppLinks();
      StreamSubscription<Uri>? sub;
      sub = appLinks.uriLinkStream.listen((uri) {
        if (uri.scheme == 'flowapp' && uri.host == 'oauth') {
          if (!completer.isCompleted) {
            completer.complete(uri.queryParameters['token']);
          }
          sub?.cancel();
        }
      });

      // Открываем браузер (Safari / Chrome)
      await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      // Ждём callback (таймаут 5 минут)
      final firebaseToken = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          sub?.cancel();
          return null;
        },
      );

      if (firebaseToken == null) {
        _isLoading = false;
        _errorMessage = 'Вход отменён';
        notifyListeners();
        return false;
      }

      final userCred = await _auth.signInWithCustomToken(firebaseToken);
      await _ensureUserDoc(userCred.user!);
      _user = userCred.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ошибка входа через $displayName';
      notifyListeners();
      return false;
    }
  }

  // Создаём документ пользователя при первом входе
  Future<void> _ensureUserDoc(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'currency': '₽ Рубль',
        'theme': 'light',
        'role': 'employee',
        'createdAt': FieldValue.serverTimestamp(),
      });
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