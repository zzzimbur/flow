import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import '../providers/subscription_provider.dart';
import '../services/ads_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() async {
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );

      // Не показываем рекламу для Premium пользователей
      if (subscriptionProvider.isActive) {
        debugPrint('⏭️ Пропускаем баннер - есть активная подписка');
        return;
      }

      // Загружаем рекламу только для бесплатных пользователей
      debugPrint('🔄 Загрузка баннера для бесплатного пользователя...');
      _bannerAd = AdsService().createBanner(context);

      if (_bannerAd != null) {
        await _bannerAd!.loadAd();
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
          debugPrint('✅ Баннер загружен и готов к показу');
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки баннера: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем изменения подписки
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        // Если есть подписка - не показываем рекламу
        if (subscriptionProvider.isActive) {
          debugPrint('⏭️ Скрываем баннер - активна подписка');
          return const SizedBox.shrink();
        }

        // Если реклама не загружена - не показываем
        if (!_isLoaded || _bannerAd == null) {
          return const SizedBox.shrink();
        }

        // Показываем баннер
        return Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          height: 100,
          child: AdWidget(bannerAd: _bannerAd!),
        );
      },
  }
}