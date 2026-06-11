import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../services/yookassa_service.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/enhanced_glass_card.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  final YooKassaService _yooKassaService = YooKassaService();

  Future<void> _startPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('Пользователь не авторизован');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Создаем платеж через ЮКассу
      final paymentData = await _yooKassaService.createPayment(
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: user.displayName,
      );

      if (paymentData == null) {
        _showErrorSnackBar('Не удалось создать платеж. Попробуйте позже.');
        setState(() => _isLoading = false);
        return;
      }

      final confirmationUrl = paymentData['confirmation_url'] as String?;
      final paymentId = paymentData['payment_id'] as String?;

      if (confirmationUrl != null && paymentId != null) {
        // Сохраняем pending платеж
        final subscriptionProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        await subscriptionProvider.savePendingPayment(user.uid, paymentId);
        
        // Открываем страницу оплаты ЮКассы
        final uri = Uri.parse(confirmationUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          _showErrorSnackBar('Не удалось открыть страницу оплаты');
          setState(() => _isLoading = false);
          return;
        }

        // Переходим на экран ожидания подтверждения оплаты
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                paymentId: paymentId,
              ),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Некорректный ответ от сервера оплаты');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFef4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          child: Column(
            children: [
              // Header с кнопкой назад
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Оформление подписки',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Премиум карточка с описанием
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8b7ff5),
                              const Color(0xFF6c5ce7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8b7ff5).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Flow AI',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Умный учёт с искусственным интеллектом',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '299 ₽',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '/ месяц',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Преимущества Premium
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Что входит в Flow AI:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeature(
                              '🤖',
                              'AI-прогноз доходов',
                              'Умные предсказания на основе ваших смен',
                              isDark,
                            ),
                            _buildFeature(
                              '💡',
                              'Персональные советы',
                              'AI анализирует расходы и даёт рекомендации',
                              isDark,
                            ),
                            _buildFeature(
                              '📷',
                              'Сканирование чеков',
                              'Фото чека → автоматическая запись расхода',
                              isDark,
                            ),
                            _buildFeature(
                              '🎙️',
                              'Голосовой ввод',
                              'Добавляйте смены и траты голосом',
                              isDark,
                            ),
                            _buildFeature(
                              '🚫',
                              'Без рекламы',
                              'Работайте без отвлечений',
                              isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Информация об оплате
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: accentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Безопасная оплата',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Оплата происходит через защищенный сервис ЮКасса. Мы не храним данные вашей карты.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPaymentIcon('assets/visa.png'),
                                _buildPaymentIcon('assets/mastercard.png'),
                                _buildPaymentIcon('assets/mir.png'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Кнопка оплаты
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _startPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8b7ff5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFF8b7ff5).withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Оплатить 299 ₽',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Юридическая информация
                      Text(
                        'Нажимая кнопку "Оплатить", вы соглашаетесь с условиями оферты и политикой конфиденциальности',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    String emoji,
    String title,
    String description,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: const Color(0xFF10b981),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.credit_card,
        size: 32,
        color: Colors.grey,
      ),
      // Замените на Image.asset(assetPath) когда добавите логотипы
    );
  }
}

// Animated Background виджет
class AnimatedBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}
