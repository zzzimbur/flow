import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';
import 'providers/goals_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/ads_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  // Инициализация Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase инициализирован');
  } catch (e) {
    debugPrint('❌ Ошибка инициализации Firebase: $e');
  }

  // Локализация
  Intl.defaultLocale = 'ru_RU';
  await initializeDateFormatting('ru_RU', null);

  // Только портретная ориентация
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const FlowApp());
}

class FlowApp extends StatefulWidget {
  const FlowApp({super.key});

  @override
  State<FlowApp> createState() => _FlowAppState();
}

class _FlowAppState extends State<FlowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Добавляем observer для отслеживания жизненного цикла приложения
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Показываем App Open Ad при возврате в приложение
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAdIfNeeded();
    }
  }

  // Показываем App Open Ad только для пользователей БЕЗ подписки
  Future<void> _showAppOpenAdIfNeeded() async {
    try {
      // Получаем провайдер подписки
      final subscriptionProvider = context.read<SubscriptionProvider>();
      
      // Проверяем подписку
      if (subscriptionProvider.isActive) {
        debugPrint('⏭️ Пропускаем App Open Ad - есть активная подписка');
        return;
      }
      
      // Показываем рекламу только бесплатным пользователям
      final adsService = AdsService();
      if (adsService.isAppOpenAdLoaded) {
        debugPrint('🔄 Приложение возобновлено - показываем App Open Ad');
        await adsService.showAppOpenAd();
      } else {
        debugPrint('⚠️ App Open Ad не загружена');
      }
    } catch (e) {
      debugPrint('❌ Ошибка показа App Open Ad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Flow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🚀 Начало инициализации приложения');
    
    if (!mounted) return;
    
    try {
      final authProvider = context.read<AuthProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final subscriptionProvider = context.read<SubscriptionProvider>();
      final goalProvider = context.read<GoalProvider>();
      final goalsProvider = context.read<GoalsProvider>();
      
      debugPrint('🔍 Проверка авторизации...');
      
      final isAuth = authProvider.isAuthenticated;
      final userId = authProvider.userId;
      
      debugPrint('✅ isAuthenticated: $isAuth');
      debugPrint('✅ userId: $userId');
      
      // Если пользователь авторизован - загружаем его данные
      if (isAuth && userId.isNotEmpty) {
        debugPrint('🔄 Загрузка данных пользователя...');

        // Передаём displayName из Firebase Auth чтобы синхронизировать с Firestore
        final firebaseDisplayName = authProvider.user?.displayName ?? '';

        await Future.wait([
          settingsProvider.initialize(userId, firebaseDisplayName: firebaseDisplayName),
          subscriptionProvider.initialize(userId),
          goalProvider.loadGoals(userId),
          goalsProvider.loadGoals(),
        ]);
        
        debugPrint('✅ Данные пользователя загружены');
      } else {
        debugPrint('ℹ️ Пользователь не авторизован');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка инициализации: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    if (mounted) {
      setState(() => _isInitializing = false);
      debugPrint('✅ Инициализация завершена');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SplashScreen();
    }

    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, _) {
        debugPrint('🔄 Построение главного экрана');
        debugPrint('✅ isAuthenticated: ${authProvider.isAuthenticated}');
        debugPrint('✅ isFirstLaunch: ${settingsProvider.isFirstLaunch}');
        
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}