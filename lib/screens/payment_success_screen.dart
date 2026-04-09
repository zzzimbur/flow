import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/yookassa_service.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/enhanced_glass_card.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String paymentId;

  const PaymentSuccessScreen({
    super.key,
    required this.paymentId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final YooKassaService _yooKassaService = YooKassaService();
  Timer? _checkTimer;
  String _status = 'pending';
  bool _isChecking = true;
  int _checkAttempts = 0;
  static const int _maxAttempts = 60; // Максимум 5 минут (60 * 5 сек)

  @override
  void initState() {
    super.initState();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startPaymentCheck() {
    // Проверяем статус платежа каждые 5 секунд
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });

    // Первая проверка сразу
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (_checkAttempts >= _maxAttempts) {
      _checkTimer?.cancel();
      setState(() {
        _status = 'timeout';
        _isChecking = false;
      });
      return;
    }

    _checkAttempts++;

    try {
      final paymentInfo = await _yooKassaService.getPaymentInfo(widget.paymentId);
      
      if (paymentInfo == null) {
        // Продолжаем проверку
        return;
      }

      final status = paymentInfo['status'] as String;
      
      if (status == 'succeeded') {
        // Платеж успешен - активируем подписку
        _checkTimer?.cancel();
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          );
          
          await subscriptionProvider.activatePremium(user.uid, durationDays: 30);
          
          // ДОБАВЛЕНО: Удаляем pending платеж
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'pendingPayment': FieldValue.delete()});
          } catch (e) {
            print('Ошибка удаления pending платежа: $e');
          }
          
          setState(() {
            _status = 'succeeded';
            _isChecking = false;
          });
          
          // Показываем успешное сообщение на 2 секунды, затем возвращаемся
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } else if (status == 'canceled') {
        // Платеж отменен
        _checkTimer?.cancel();
        setState(() {
          _status = 'canceled';
          _isChecking = false;
        });
      } else if (status == 'pending' || status == 'waiting_for_capture') {
        // Продолжаем ждать
        setState(() {
          _status = status;
        });
      }
    } catch (e) {
      print('Ошибка проверки статуса платежа: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return WillPopScope(
      onWillPop: () async {
        // Предупреждаем пользователя при попытке выхода
        if (_isChecking) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Прервать проверку?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              content: Text(
                'Оплата может еще обрабатываться. Вы уверены, что хотите выйти?',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Продолжить ожидание'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Выйти',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0f172a),
                      const Color(0xFF1e293b),
                    ]
                  : [
                      const Color(0xFFf1f5f9),
                      const Color(0xFFe2e8f0),
                    ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EnhancedGlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(),
                      const SizedBox(height: 32),
                      _buildStatusText(isDark),
                      const SizedBox(height: 16),
                      _buildDescription(isDark),
                      if (!_isChecking && _status != 'succeeded') ...[
                        const SizedBox(height: 32),
                        _buildActionButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_status == 'succeeded') {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF10b981).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          size: 64,
          color: Color(0xFF10b981),
        ),
      );
    } else if (_status == 'canceled') {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFef4444).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cancel,
          size: 64,
          color: Color(0xFFef4444),
        ),
      );
    } else if (_status == 'timeout') {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFf59e0b).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.access_time,
          size: 64,
          color: Color(0xFFf59e0b),
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF8b7ff5).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b7ff5)),
          ),
        ),
      );
    }
  }

  Widget _buildStatusText(bool isDark) {
    String text;
    if (_status == 'succeeded') {
      text = 'Оплата успешна!';
    } else if (_status == 'canceled') {
      text = 'Оплата отменена';
    } else if (_status == 'timeout') {
      text = 'Превышено время ожидания';
    } else {
      text = 'Обработка платежа...';
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(bool isDark) {
    String text;
    if (_status == 'succeeded') {
      text = 'Premium подписка активирована на 30 дней';
    } else if (_status == 'canceled') {
      text = 'Платеж был отменен. Попробуйте еще раз';
    } else if (_status == 'timeout') {
      text = 'Проверьте статус платежа в настройках или попробуйте позже';
    } else {
      text = 'Пожалуйста, подождите. Проверяем статус платежа...\nПопытка $_checkAttempts из $_maxAttempts';
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _status == 'canceled'
              ? const Color(0xFF8b7ff5)
              : const Color(0xFFef4444),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _status == 'canceled' ? 'Вернуться' : 'Закрыть',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
