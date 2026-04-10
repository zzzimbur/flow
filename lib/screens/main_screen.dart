import 'package:flow/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../widgets/glass_card.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'calendar_screen.dart';
import 'add_task_screen.dart';
import 'add_transaction_screen.dart';
import 'add_shift_screen.dart';
import 'accountant_report_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _showAddMenu = false;

  // Ключи для принудительного пересоздания экранов
  Key _homeKey = UniqueKey();
  Key _financeKey = UniqueKey();
  Key _calendarKey = UniqueKey();
  Key _settingsKey = UniqueKey();
  Key _accountantKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  // index 4 = AccountantReportScreen (only shown when isAccountant)
  Widget _screenForIndex(int index) {
    switch (index) {
      case 0: return HomeScreen(key: _homeKey);
      case 1: return FinanceScreen(key: _financeKey);
      case 2: return CalendarScreen(key: _calendarKey);
      case 3: return SettingsScreen(key: _settingsKey);
      case 4: return AccountantReportScreen(key: _accountantKey);
      default: return HomeScreen(key: _homeKey);
    }
  }

  // Метод для обновления всех экранов
  void _refreshAllScreens() {
    setState(() {
      _homeKey = UniqueKey();
      _financeKey = UniqueKey();
      _calendarKey = UniqueKey();
      _settingsKey = UniqueKey();
      _accountantKey = UniqueKey();
    });
  }

  /// Метод для обновления конкретного экрана
  void _refreshScreen(int index) {
    setState(() {
      switch (index) {
        case 0:
          _homeKey = UniqueKey();
          break;
        case 1:
          _financeKey = UniqueKey();
          break;
        case 2:
          _calendarKey = UniqueKey();
          break;
        case 3:
          _settingsKey = UniqueKey();
          break;
        case 4:
          _accountantKey = UniqueKey();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final isAccountant = settings.isAccountant;

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
            _screenForIndex(_currentIndex),
            if (_showAddMenu) _buildAddMenu(isDark),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        showAccountantTab: isAccountant,
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
                      ? const Color(0xFF1e293b).withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Создать',
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
                      // Задача
                      _buildMenuItem(
                        title: 'Задачу',
                        subtitle: 'Создать новую задачу',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF3b82f6),
                        onTap: () async {
                          setState(() => _showAddMenu = false);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTaskScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _refreshAllScreens();
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      // Операция
                      _buildMenuItem(
                        title: 'Операцию',
                        subtitle: 'Доход или расход',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF10b981),
                        onTap: () async {
                          setState(() => _showAddMenu = false);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _refreshAllScreens();
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      // Смена
                      _buildMenuItem(
                        title: 'Смену',
                        subtitle: 'Добавить в график',
                        icon: Icons.event_available,
                        color: const Color(0xFF8b7ff5),
                        onTap: () async {
                          setState(() => _showAddMenu = false);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddShiftScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _refreshAllScreens();
                          }
                        },
                        isDark: isDark,
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

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
      ),
    );
  }
}