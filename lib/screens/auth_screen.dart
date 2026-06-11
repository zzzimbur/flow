import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/enhanced_glass_card.dart';
import 'main_screen.dart';
import 'email_verification_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accentColor = settings.accentColor;

    return Scaffold(
      body: AnimatedBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFf4e4a7),
                            Color(0xFF8b7ff5),
                            Color(0xFF000000),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8b7ff5).withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Название приложения
                  Text(
                    'Flow',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Войти в аккаунт' : 'Создать аккаунт',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Форма
                  EnhancedGlassCard(
                    padding: const EdgeInsets.all(28),
                    enableShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Имя',
                            icon: Icons.person_outline,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Пароль',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        if (_isLogin) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Забыли пароль?',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        // Чекбокс с согласием (только при регистрации)
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildAgreementCheckbox(isDark, accentColor),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Кнопка входа/регистрации
                        GlassButton(
                          text: _isLogin ? 'Войти' : 'Зарегистрироваться',
                          onPressed: _handleAuth,
                          color: accentColor,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Разделитель
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'или войти через',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Кнопки соц. сетей
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          isDark: isDark,
                          icon: _googleIcon(),
                          onTap: () => _handleSocialAuth('google'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SocialButton(
                          label: 'Яндекс',
                          isDark: isDark,
                          icon: _yandexIcon(),
                          onTap: () => _handleSocialAuth('yandex'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SocialButton(
                          label: 'Telegram',
                          isDark: isDark,
                          icon: _telegramIcon(),
                          onTap: () => _handleSocialAuth('telegram'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Переключатель режима
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Нет аккаунта?' : 'Уже есть аккаунт?',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            // Сбрасываем чекбокс при переключении
                            _agreedToTerms = false;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Зарегистрироваться' : 'Войти',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementCheckbox(bool isDark, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value!),
          activeColor: accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Я согласен с '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _openDocument('privacy'),
                        child: Text(
                          'Политикой конфиденциальности',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ', '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _openDocument('terms'),
                        child: Text(
                          'Пользовательским соглашением',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' и '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _openDocument('consent'),
                        child: Text(
                          'даю согласие на обработку персональных данных',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDocument(String type) async {
    final urls = {
      'privacy': 'https://zzzimbur.github.io/flow-legal/privacy-policy.html',
      'terms': 'https://zzzimbur.github.io/flow-legal/terms-of-service.html',
      'consent': 'https://zzzimbur.github.io/flow-legal/consent.html',
    };
    
    final url = urls[type];
    if (url == null) return;
    
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          _showError('Не удалось открыть документ');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка открытия документа: $e');
      }
    }
  }

  Future<void> _handleAuth() async {
    // Валидация
    if (_emailController.text.trim().isEmpty) {
      _showError('Введите email');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showError('Введите пароль');
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showError('Введите имя');
      return;
    }

    if (!_isLogin && !_agreedToTerms) {
      _showError('Примите условия использования');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    try {
      if (_isLogin) {
        success = await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        success = await authProvider.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (success && mounted) {
        // Инициализируем настройки сразу после входа
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        final firebaseDisplayName = authProvider.user?.displayName ?? '';
        await settingsProvider.initialize(
          authProvider.userId,
          firebaseDisplayName: firebaseDisplayName,
        );

        if (!mounted) return;

        // После регистрации — показываем экран подтверждения email
        // После входа — сразу в приложение
        if (!_isLogin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const EmailVerificationScreen(),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } else if (mounted) {
        _showError(authProvider.errorMessage ?? 'Произошла ошибка');
      }
    } catch (e) {
      if (mounted) {
        _showError('Произошла ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFef4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = false;
    try {
      switch (provider) {
        case 'google':
          success = await authProvider.signInWithGoogle();
          break;
        case 'yandex':
          success = await authProvider.signInWithYandex();
          break;
        case 'telegram':
          success = await authProvider.signInWithTelegram();
          break;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await settingsProvider.initialize(
        authProvider.userId,
        firebaseDisplayName: authProvider.user?.displayName ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      _showError(authProvider.errorMessage ?? 'Ошибка входа');
    }
  }

  Widget _googleIcon() => Image.network(
    'https://www.google.com/favicon.ico',
    width: 18, height: 18,
    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
  );

  Widget _telegramIcon() => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(
      color: const Color(0xFF26A5E4),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Center(
      child: Icon(Icons.send_rounded, color: Colors.white, size: 12),
    ),
  );

  Widget _yandexIcon() => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(
      color: const Color(0xFFFC3F1D),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Center(
      child: Text('Я', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Provider.of<SettingsProvider>(context).accentColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}