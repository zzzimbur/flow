import 'package:flutter/material.dart';
import '../screens/main_screen.dart';

// Навигация к определённому табу в MainScreen
class NavigationHelper {
  static void navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreenWithTab(initialTab: tabIndex),
      ),
    );
  }
  
  static void navigateToHome(BuildContext context) => navigateToTab(context, 0);
  static void navigateToFinance(BuildContext context) => navigateToTab(context, 1);
  static void navigateToTasks(BuildContext context) => navigateToTab(context, 2);
  static void navigateToSchedule(BuildContext context) => navigateToTab(context, 3);
}

// Обёртка для MainScreen с начальным табом
class MainScreenWithTab extends StatefulWidget {
  final int initialTab;
  
  const MainScreenWithTab({super.key, required this.initialTab});

  @override
  State<MainScreenWithTab> createState() => _MainScreenWithTabState();
}

class _MainScreenWithTabState extends State<MainScreenWithTab> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return MainScreen(initialTab: _currentIndex);
  }
}