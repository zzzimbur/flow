// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'tasks_screen.dart';
import 'schedule_screen.dart';
import '../widgets/add_menu.dart';
import '../widgets/glass_card.dart';  // Added import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();  // Changed to public State
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FinanceScreen(),
    const TasksScreen(),
    const ScheduleScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const AddMenu(),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _bottomNavItem(int index, IconData icon, String label) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[400],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey[400],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFADD8E6), Color(0xFFFFC0CB)], // Light blue to light pink gradient
              ),
            ),
          ),
          SafeArea(
            child: _screens[_selectedIndex],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bottomNavItem(0, Icons.home, 'Главная'),
                    _bottomNavItem(1, Icons.attach_money, 'Финансы'),
                    const SizedBox(width: 56), // Space for center button
                    _bottomNavItem(2, Icons.check_circle, 'Задачи'),
                    _bottomNavItem(3, Icons.calendar_today, 'График'),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32, // Elevated above the nav bar
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _showAddMenu,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}