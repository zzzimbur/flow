// lib/providers/subscription_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/settings_screen.dart';
import '../screens/payment_screen.dart'; // ДОБАВЛЕНО
import '../services/yookassa_service.dart';

enum SubscriptionType {
  free,
  premium,
}

class SubscriptionProvider extends ChangeNotifier {
  bool _isActive = false;
  SubscriptionType _type = SubscriptionType.free;
  DateTime? _expiresAt;
  DateTime? _startedAt;
  bool _isLoaded = false;

  // Геттеры
  bool get isActive => _isActive;
  bool get isPremium => _isActive && _type == SubscriptionType.premium;
  bool get isFree => !isPremium;
  SubscriptionType get type => _type;
  DateTime? get expiresAt => _expiresAt;
  DateTime? get startedAt => _startedAt;
  bool get isLoaded => _isLoaded;

  // Список фич доступных с подпиской
  bool get canUseWeekView => isPremium;
  bool get canCreateGoals => isPremium;
  bool get canUseTemplates => isPremium;
  bool get canUseAnalytics => isPremium;
  bool get canExportData => isPremium;
  bool get canAccessFinance => isPremium;
  bool get canCreateTransactions => isPremium;
  bool get canImportExportCalendar => isPremium;
  bool get canAccessWeekView => isPremium;

  // Загрузить данные подписки
  Future<void> initialize(String userId) async {
    if (userId.isEmpty) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final subscription = data?['subscription'] as Map<String, dynamic>?;

        if (subscription != null) {
          _isActive = subscription['isActive'] ?? false;
          _type = _parseType(subscription['type'] ?? 'free');
          _expiresAt = (subscription['expiresAt'] as Timestamp?)?.toDate();
          _startedAt = (subscription['startedAt'] as Timestamp?)?.toDate();

          // Проверяем не истекла ли подписка
          if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
            _isActive = false;
            _type = SubscriptionType.free;
          }
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки подписки: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Активировать подписку (для тестирования или после покупки)
  Future<void> activatePremium(String userId, {int durationDays = 365}) async {
    try {
      final now = DateTime.now();
      final expires = now.add(Duration(days: durationDays));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'subscription': {
          'isActive': true,
          'type': 'premium',
          'startedAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(expires),
        }
      }, SetOptions(merge: true));

      _isActive = true;
      _type = SubscriptionType.premium;
      _startedAt = now;
      _expiresAt = expires;

      notifyListeners();
    } catch (e) {
      print('Ошибка активации подписки: $e');
    }
  }

  // Отменить подписку
  Future<void> cancelSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'subscription': {
          'isActive': false,
          'type': 'free',
          'expiresAt': null,
        }
      }, SetOptions(merge: true));

      _isActive = false;
      _type = SubscriptionType.free;
      _expiresAt = null;

      notifyListeners();
    } catch (e) {
      print('Ошибка отмены подписки: $e');
    }
  }

  // НОВЫЙ МЕТОД: Сохранить pending платеж
  Future<void> savePendingPayment(String userId, String paymentId) async {
    if (userId.isEmpty || paymentId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'pendingPayment': {
          'paymentId': paymentId,
          'createdAt': Timestamp.now(),
        }
      }, SetOptions(merge: true));
      
      print('💾 Pending платеж сохранен: $paymentId');
    } catch (e) {
      print('Ошибка сохранения pending платежа: $e');
    }
  }

  // НОВЫЙ МЕТОД: Проверить pending платежи
  Future<void> checkPendingPayments(String userId) async {
    if (userId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final pendingPayment = doc.data()?['pendingPayment'] as Map<String, dynamic>?;
      
      if (pendingPayment != null) {
        final paymentId = pendingPayment['paymentId'] as String;
        final createdAt = (pendingPayment['createdAt'] as Timestamp).toDate();
        
        // Проверяем только если платеж не старше 24 часов
        if (DateTime.now().difference(createdAt).inHours < 24) {
          print('🔍 Проверяем pending платеж: $paymentId');
          
          final yooKassaService = YooKassaService();
          final paymentInfo = await yooKassaService.getPaymentInfo(paymentId);
          
          if (paymentInfo != null) {
            final status = paymentInfo['status'] as String;
            print('📊 Статус платежа: $status');
            
            if (status == 'succeeded') {
              // Активируем подписку
              print('✅ Платеж успешен! Активируем подписку...');
              await activatePremium(userId, durationDays: 30);
              
              // Удаляем pending платеж
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'pendingPayment': FieldValue.delete()});
              
              print('🎉 Подписка активирована!');
            } else if (status == 'canceled') {
              // Платеж отменен - удаляем pending
              print('❌ Платеж отменен, удаляем из pending');
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'pendingPayment': FieldValue.delete()});
            }
          }
        } else {
          // Платеж слишком старый - удаляем
          print('⏰ Платеж старше 24 часов, удаляем');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'pendingPayment': FieldValue.delete()});
        }
      }
    } catch (e) {
      print('Ошибка проверки pending платежей: $e');
    }
  }

  // Проверить доступ к фиче
  bool hasAccessTo(String feature) {
    if (isPremium) return true;

    switch (feature) {
      case 'week_view':
        return canUseWeekView;
      case 'goals':
        return canCreateGoals;
      case 'templates':
        return canUseTemplates;
      case 'analytics':
        return canUseAnalytics;
      case 'export':
        return canExportData;
      default:
        return false;
    }
  }

  // Показать диалог с предложением подписки
  void showPremiumDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => PremiumDialog(feature: feature),
    );
  }

  // Парсинг типа подписки
  SubscriptionType _parseType(String typeString) {
    switch (typeString) {
      case 'premium':
        return SubscriptionType.premium;
      case 'free':
      default:
        return SubscriptionType.free;
    }
  }

  // Получить описание фичи
  static String getFeatureDescription(String feature) {
    switch (feature) {
      case 'week_view':
        return 'Недельный вид календаря с drag & drop';
      case 'goals':
        return 'Создание и отслеживание финансовых целей';
      case 'templates':
        return 'Сохранение и использование шаблонов';
      case 'analytics':
        return 'Подробная аналитика и статистика';
      case 'export':
        return 'Экспорт данных в Excel/CSV';
      default:
        return 'Премиум функция';
    }
  }
}

// Диалог предложения подписки
class PremiumDialog extends StatelessWidget {
  final String feature;

  const PremiumDialog({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featureDesc = SubscriptionProvider.getFeatureDescription(feature);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8b7ff5).withOpacity(0.95),
              const Color(0xFF6c5ce7).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Премиум функция',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              featureDesc,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'Премиум включает:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeature('📅', 'Недельный вид календаря'),
            _buildFeature('🎯', 'Неограниченные цели'),
            _buildFeature('📋', 'Шаблоны событий'),
            _buildFeature('📊', 'Детальная аналитика'),
            _buildFeature('💾', 'Экспорт данных'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем диалог
                // Переход на экран покупки подписки
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8b7ff5),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Получить Премиум',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Может позже',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            size: 20,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}