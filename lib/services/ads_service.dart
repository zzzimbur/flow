import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // Баннер
  BannerAd? _bannerAd;
  
  // Межстрочная реклама
  InterstitialAdLoader? _interstitialAdLoader;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  
  // Реклама при открытии
  AppOpenAdLoader? _appOpenAdLoader;
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  bool _isColdStartAdShown = false;
  
  bool _isInitialized = false;

  // ✅ РЕАЛЬНЫЕ Ad Unit ID
  static const String _bannerAdUnitId = 'R-M-18425489-5';         // Баннер
  static const String _interstitialAdUnitId = 'R-M-18425489-6';  // Межстрочная
  static const String _appOpenAdUnitId = 'R-M-18425489-4';       // При открытии

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Реклама уже инициализирована');
      return;
    }

    try {
      debugPrint('🔄 Инициализация MobileAds...');
      await MobileAds.initialize();
      
      _isInitialized = true;
      debugPrint('✅ MobileAds инициализирован успешно');
      debugPrint('📍 Application ID: 18425489');

      // Инициализируем загрузчики рекламы
      await _initializeInterstitialLoader();
      await _initializeAppOpenLoader();

    } catch (e) {
      debugPrint('❌ Ошибка инициализации MobileAds: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // ==========================================
  // БАННЕР
  // ==========================================

  BannerAd? createBanner(BuildContext context) {
    debugPrint('🔄 Создание баннера...');
    
    if (!_isInitialized) {
      debugPrint('❌ MobileAds не инициализирован!');
      return null;
    }

    try {
      final screenWidth = MediaQuery.of(context).size.width.round();
      
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        adSize: BannerAdSize.inline(width: screenWidth, maxHeight: 100),
        adRequest: const AdRequest(),
        onAdLoaded: () {
          debugPrint('✅ Баннер загружен успешно');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Ошибка загрузки баннера:');
          debugPrint('   Код: ${error.code}');
          debugPrint('   Описание: ${error.description}');
        },
        onAdClicked: () => debugPrint('👆 Клик по баннеру'),
        onLeftApplication: () => debugPrint('🚪 Пользователь покинул приложение'),
        onReturnedToApplication: () => debugPrint('🔙 Пользователь вернулся'),
        onImpression: (impressionData) => debugPrint('👁️ Impression: $impressionData'),
      );

      debugPrint('✅ Баннер создан');
      return _bannerAd;
    } catch (e) {
      debugPrint('❌ Ошибка создания баннера: $e');
      return null;
    }
  }

  void disposeBanner() {
    debugPrint('🗑️ Удаление баннера');
    _bannerAd?.destroy();
    _bannerAd = null;
  }

  // ==========================================
  // МЕЖСТРОЧНАЯ РЕКЛАМА (Interstitial)
  // ==========================================
  
  Future<void> _initializeInterstitialLoader() async {
    try {
      debugPrint('🔄 Инициализация InterstitialAdLoader...');
      
      _interstitialAdLoader = await InterstitialAdLoader.create(
        onAdLoaded: (InterstitialAd interstitialAd) {
          debugPrint('✅ Межстрочная реклама загружена');
          _interstitialAd = interstitialAd;
          _isInterstitialLoading = false;
          
          // Устанавливаем слушатель событий
          _setInterstitialEventListener(interstitialAd);
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Ошибка загрузки межстрочной рекламы:');
          debugPrint('   Код: ${error.code}');
          debugPrint('   Описание: ${error.description}');
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      );
      
      debugPrint('✅ InterstitialAdLoader создан');
      
      // Сразу загружаем первую рекламу
      await loadInterstitialAd();
      
    } catch (e) {
      debugPrint('❌ Ошибка создания InterstitialAdLoader: $e');
    }
  }

  Future<void> loadInterstitialAd() async {
    if (!_isInitialized || _interstitialAdLoader == null) {
      debugPrint('❌ Нельзя загрузить межстрочную рекламу: не инициализировано');
      return;
    }

    if (_isInterstitialLoading) {
      debugPrint('⚠️ Межстрочная реклама уже загружается');
      return;
    }

    try {
      debugPrint('🔄 Загрузка межстрочной рекламы...');
      _isInterstitialLoading = true;
      
      final adRequestConfiguration = AdRequestConfiguration(
        adUnitId: _interstitialAdUnitId,
      );
      
      await _interstitialAdLoader!.loadAd(
        adRequestConfiguration: adRequestConfiguration,
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки межстрочной рекламы: $e');
      _isInterstitialLoading = false;
    }
  }

  void _setInterstitialEventListener(InterstitialAd ad) {
    ad.setAdEventListener(
      eventListener: InterstitialAdEventListener(
        onAdShown: () => debugPrint('👁️ Межстрочная реклама показана'),
        onAdFailedToShow: (error) {
          debugPrint('❌ Ошибка показа межстрочной рекламы: ${error.description}');
        },
        onAdDismissed: () {
          debugPrint('🚪 Межстрочная реклама закрыта');
          _interstitialAd = null;
          // Загружаем следующую рекламу
          loadInterstitialAd();
        },
        onAdClicked: () => debugPrint('👆 Клик по межстрочной рекламе'),
        onAdImpression: (impressionData) {
          debugPrint('👁️ Impression межстрочной рекламы: $impressionData');
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Межстрочная реклама не загружена');
      // Пытаемся загрузить
      await loadInterstitialAd();
      return;
    }

    try {
      debugPrint('📺 Показываем межстрочную рекламу...');
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('❌ Ошибка показа межстрочной рекламы: $e');
      _interstitialAd = null;
    }
  }

  bool get isInterstitialAdLoaded => _interstitialAd != null;

  // ==========================================
  // РЕКЛАМА ПРИ ОТКРЫТИИ (App Open Ad)
  // ==========================================
  
  Future<void> _initializeAppOpenLoader() async {
    try {
      debugPrint('🔄 Инициализация AppOpenAdLoader...');
      
      _appOpenAdLoader = await AppOpenAdLoader.create(
        onAdLoaded: (AppOpenAd appOpenAd) {
          debugPrint('✅ Реклама при открытии загружена');
          _appOpenAd = appOpenAd;
          _isAppOpenLoading = false;
          
          // Устанавливаем слушатель событий
          _setAppOpenEventListener(appOpenAd);
          
          // Показываем при холодном старте
          if (!_isColdStartAdShown) {
            showAppOpenAd();
            _isColdStartAdShown = true;
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Ошибка загрузки рекламы при открытии:');
          debugPrint('   Код: ${error.code}');
          debugPrint('   Описание: ${error.description}');
          _isAppOpenLoading = false;
          _appOpenAd = null;
        },
      );
      
      debugPrint('✅ AppOpenAdLoader создан');
      
      // Сразу загружаем первую рекламу
      await loadAppOpenAd();
      
    } catch (e) {
      debugPrint('❌ Ошибка создания AppOpenAdLoader: $e');
    }
  }

  Future<void> loadAppOpenAd() async {
    if (!_isInitialized || _appOpenAdLoader == null) {
      debugPrint('❌ Нельзя загрузить рекламу при открытии: не инициализировано');
      return;
    }

    if (_isAppOpenLoading) {
      debugPrint('⚠️ Реклама при открытии уже загружается');
      return;
    }

    try {
      debugPrint('🔄 Загрузка рекламы при открытии...');
      _isAppOpenLoading = true;
      
      final adRequestConfiguration = AdRequestConfiguration(
        adUnitId: _appOpenAdUnitId,
      );
      
      await _appOpenAdLoader!.loadAd(
        adRequestConfiguration: adRequestConfiguration,
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки рекламы при открытии: $e');
      _isAppOpenLoading = false;
    }
  }

  void _setAppOpenEventListener(AppOpenAd ad) {
    ad.setAdEventListener(
      eventListener: AppOpenAdEventListener(
        onAdShown: () => debugPrint('👁️ Реклама при открытии показана'),
        onAdFailedToShow: (error) {
          debugPrint('❌ Ошибка показа рекламы при открытии: ${error.description}');
        },
        onAdDismissed: () {
          debugPrint('🚪 Реклама при открытии закрыта');
          _appOpenAd = null;
          // Загружаем следующую рекламу
          loadAppOpenAd();
        },
        onAdClicked: () => debugPrint('👆 Клик по рекламе при открытии'),
        onAdImpression: (impressionData) {
          debugPrint('👁️ Impression рекламы при открытии: $impressionData');
        },
      ),
    );
  }

  Future<void> showAppOpenAd() async {
    if (_appOpenAd == null) {
      debugPrint('⚠️ Реклама при открытии не загружена');
      return;
    }

    try {
      debugPrint('📺 Показываем рекламу при открытии...');
      await _appOpenAd!.show();
    } catch (e) {
      debugPrint('❌ Ошибка показа рекламы при открытии: $e');
      _appOpenAd = null;
    }
  }

  bool get isAppOpenAdLoaded => _appOpenAd != null;

  // ==========================================
  // ОБЩИЕ МЕТОДЫ
  // ==========================================
  
  bool get isInitialized => _isInitialized;

  void dispose() {
    debugPrint('🗑️ Очистка AdsService');
    disposeBanner();
    _interstitialAd = null;
    _appOpenAd = null;
  }
}