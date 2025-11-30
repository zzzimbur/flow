import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'tasks_screen.dart';
import 'schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showAddMenu = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FinanceScreen(),
    const TasksScreen(),
    const ScheduleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf8fafc),
              Color(0xFFe2e8f0),
            ],
          ),
        ),
        child: Stack(
          children: [
            _screens[_currentIndex],
            if (_showAddMenu) _buildAddMenu(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onAddPressed: () {
          setState(() {
            _showAddMenu = true;
          });
        },
      ),
    );
  }

  Widget _buildAddMenu() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAddMenu = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              child: GestureDetector(
                onTap: () {},
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Добавить',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showAddMenu = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFf1f5f9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMenuItem(
                        'Задачу',
                        'Создать новую задачу',
                        Icons.check_circle_outline,
                        () {},
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        'Операцию',
                        'Доход или расход',
                        Icons.account_balance_wallet_outlined,
                        () {},
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        'Смену',
                        'Добавить в график',
                        Icons.calendar_today_outlined,
                        () {},
                      ),
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

  Widget _buildMenuItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF94a3b8),
            ),
          ],
        ),
      ),
    );
  }
}