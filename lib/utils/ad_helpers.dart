import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ads_service.dart';
import '../providers/subscription_provider.dart';

/// Утилиты для работы с рекламой
class AdHelpers {
  // Ключи для SharedPreferences
  static const String _lastInterstitialKey = 'last_interstitial_ad_shown';
  static const String _interstitialCounterKey = 'interstitial_counter';
  
  // Настройки частоты показа
  static const int cooldownMinutes = 3; // Не чаще 1 раза в 3 минуты
  static const int showEveryNActions = 5; // Показывать каждое 5-е действие

  /// Проверяет, можно ли показывать рекламу (cooldown)
  static Future<bool> _canShowByCooldown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_lastInterstitialKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final cooldown = cooldownMinutes * 60 * 1000;
      
      final canShow = (now - lastShown) >= cooldown;
      
      if (!canShow) {
        final remainingSeconds = ((lastShown + cooldown - now) / 1000).ceil();
        debugPrint('⏭️ Cooldown активен, осталось $remainingSeconds секунд');
      }
      
      return canShow;
    } catch (e) {
      debugPrint('❌ Ошибка проверки cooldown: $e');
      return true; // В случае ошибки разрешаем показ
    }
  }

  /// Отмечает время показа рекламы
  static Future<void> _markAdShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastInterstitialKey, 
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('✅ Время показа рекламы сохранено');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения времени показа: $e');
    }
  }

  /// Увеличивает счётчик действий
  static Future<int> _incrementCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final counter = (prefs.getInt(_interstitialCounterKey) ?? 0) + 1;
      await prefs.setInt(_interstitialCounterKey, counter);
      return counter;
    } catch (e) {
      debugPrint('❌ Ошибка увеличения счётчика: $e');
      return 0;
    }
  }

  /// Сбрасывает счётчик действий
  static Future<void> _resetCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_interstitialCounterKey, 0);
      debugPrint('✅ Счётчик действий сброшен');
    } catch (e) {
      debugPrint('❌ Ошибка сброса счётчика: $e');
    }
  }

  /// Универсальный метод показа межстрочной рекламы
  /// 
  /// Проверяет:
  /// - Наличие активной подписки
  /// - Cooldown между показами
  /// - Счётчик действий
  /// 
  /// Использование:
  /// ```dart
  /// await AdHelpers.showInterstitialAd(context);
  /// ```
  static Future<void> showInterstitialAd(
    BuildContext context, {
    bool ignoreCounter = false,
    bool ignoreCooldown = false,
  }) async {
    try {
      // 1. Проверяем подписку
      if (!context.mounted) return;
      
      final subscriptionProvider = context.read<SubscriptionProvider>();
      
      if (subscriptionProvider.isActive) {
        debugPrint('⏭️ Пропускаем межстрочную рекламу - есть подписка');
        return;
      }

      // 2. Проверяем cooldown
      if (!ignoreCooldown && !await _canShowByCooldown()) {
        return;
      }

      // 3. Проверяем счётчик действий
      if (!ignoreCounter) {
        final counter = await _incrementCounter();
        debugPrint('📊 Счётчик действий: $counter');
        
        if (counter % showEveryNActions != 0) {
          debugPrint('⏭️ Пропускаем рекламу - счётчик $counter');
          return;
        }
      }

      // 4. Показываем рекламу
      final adsService = AdsService();
      
      if (!adsService.isInitialized) {
        debugPrint('⚠️ AdsService не инициализирован');
        return;
      }

      if (adsService.isInterstitialAdLoaded) {
        debugPrint('📺 Показываем межстрочную рекламу...');
        await adsService.showInterstitialAd();
        await _markAdShown();
        await _resetCounter();
        debugPrint('✅ Межстрочная реклама показана');
      } else {
        debugPrint('⚠️ Межстрочная реклама не загружена, пропускаем');
        // Пытаемся загрузить для следующего раза
        await adsService.loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('❌ Ошибка показа межстрочной рекламы: $e');
    }
  }

  /// Показывает межстрочную рекламу с гарантией
  /// Игнорирует счётчик, но соблюдает cooldown
  static Future<void> showInterstitialAdForced(BuildContext context) async {
    await showInterstitialAd(
      context,
      ignoreCounter: true,
      ignoreCooldown: false,
    );
  }

  /// Показывает App Open Ad при возврате в приложение
  static Future<void> showAppOpenAd(BuildContext context) async {
    try {
      if (!context.mounted) return;
      
      // Проверяем подписку
      final subscriptionProvider = context.read<SubscriptionProvider>();
      
      if (subscriptionProvider.isActive) {
        debugPrint('⏭️ Пропускаем App Open Ad - есть подписка');
        return;
      }

      // Показываем рекламу
      final adsService = AdsService();
      
      if (adsService.isAppOpenAdLoaded) {
        debugPrint('📺 Показываем App Open Ad...');
        await adsService.showAppOpenAd();
        debugPrint('✅ App Open Ad показана');
      } else {
        debugPrint('⚠️ App Open Ad не загружена');
      }
    } catch (e) {
      debugPrint('❌ Ошибка показа App Open Ad: $e');
    }
  }

  /// Сбрасывает все данные о рекламе (для тестирования)
  static Future<void> resetAdData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastInterstitialKey);
      await prefs.remove(_interstitialCounterKey);
      debugPrint('✅ Данные рекламы сброшены');
    } catch (e) {
      debugPrint('❌ Ошибка сброса данных рекламы: $e');
    }
  }

  /// Проверяет, загружена ли межстрочная реклама
  static bool isInterstitialAdReady() {
    return AdsService().isInterstitialAdLoaded;
  }

  /// Проверяет, загружена ли App Open реклама
  static bool isAppOpenAdReady() {
    return AdsService().isAppOpenAdLoaded;
  }
}