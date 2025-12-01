import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../widgets/glass_card.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'tasks_screen.dart';
import 'schedule_screen.dart';
import 'add_task_screen.dart';
import 'add_transaction_screen.dart';
import 'add_shift_screen.dart';

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
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0f172a), const Color(0xFF1e293b)]
                : [const Color(0xFFf8fafc), const Color(0xFFe2e8f0)],
          ),
        ),
        child: Stack(
          children: [
            _screens[_currentIndex],
            if (_showAddMenu) _buildAddMenu(isDark),
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

  Widget _buildAddMenu(bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAddMenu = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              child: GestureDetector(
                onTap: () {},
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  color: isDark 
                      ? const Color(0xFF1e293b).withOpacity(0.8)
                      : Colors.white.withOpacity(0.9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Добавить',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1e293b),
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
                              backgroundColor: isDark 
                                  ? const Color(0xFF0f172a) 
                                  : const Color(0xFFf1f5f9),
                              foregroundColor: isDark 
                                  ? Colors.white 
                                  : const Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                        _buildMenuItem(
                          'Задачу',
                          'Создать новую задачу',
                          Icons.check_circle_outline,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTaskScreen(),
                              ),
                            );
                          },
                          isDark,
                        ),
                      const SizedBox(height: 8),
                        _buildMenuItem(
                          'Операцию',
                          'Доход или расход',
                          Icons.account_balance_wallet_outlined,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransactionScreen(),
                              ),
                            );
                          },
                          isDark,
                        ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        'Смену',
                        'Добавить в график',
                        Icons.calendar_today_outlined,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddShiftScreen(),
                            ),
                          );
                        },
                        isDark,
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
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF0f172a).withOpacity(0.5) 
              : const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6c5ce7), Color(0xFF8b7ff5)],
                ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? const Color(0xFF94a3b8) 
                          : const Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
            ),
          ],
        ),
      ),
    );
  }
}