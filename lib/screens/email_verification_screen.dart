import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'main_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Проверяем каждые 3 секунды, подтвердил ли пользователь email
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.reloadUser();
    if (authProvider.isEmailVerified && mounted) {
      _timer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendVerificationEmail();
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });
    // Countdown
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        t.cancel();
        setState(() => _canResend = true);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Письмо отправлено'),
          backgroundColor: const Color(0xFF10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.user?.email ?? '';

    final bg = isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc);
    final textColor = isDark ? Colors.white : const Color(0xFF1e293b);
    final subtitleColor = isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF8b7ff5).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48,
                  color: Color(0xFF8b7ff5),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Подтвердите email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Мы отправили письмо на\n$email',
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Нажмите на ссылку в письме — и вы попадёте в приложение автоматически.',
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8b7ff5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Я подтвердил',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _canResend ? _resendEmail : null,
                child: Text(
                  _canResend
                      ? 'Отправить письмо снова'
                      : 'Повторная отправка через ${_resendCooldown}с',
                  style: TextStyle(
                    color: _canResend ? const Color(0xFF8b7ff5) : subtitleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Пропустить верификацию и войти в приложение
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                child: Text(
                  'Пропустить',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
