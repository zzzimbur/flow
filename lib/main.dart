// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  Intl.defaultLocale = 'ru_RU';
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: Colors.grey[800]!,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.grey[800]!,
          secondary: Colors.grey[600]!,
          surface: Colors.grey[200]!,
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(color: Colors.grey[900]!, fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.grey[800]!, fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.grey[700]!),
          bodySmall: TextStyle(color: Colors.grey[600]!),
        ),
      ),
      home: const MainScreen(),
    );
  }
}