import '../screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../widgets/custom_bottom_nav.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'calendar_screen.dart';
import 'add_task_screen.dart';
import 'ai_screen.dart';
import 'add_transaction_screen.dart';
import 'add_shift_screen.dart';
import 'accountant_report_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;
  
  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  bool _showAddMenu = false;
  late AnimationController _menuController;
  late Animation<double> _menuFade;
  late Animation<Offset> _menuSlide;

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
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _menuFade = CurvedAnimation(parent: _menuController, curve: Curves.easeOut);
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _menuController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _openMenu() {
    setState(() => _showAddMenu = true);
    _menuController.forward(from: 0);
  }

  Future<void> _closeMenu() async {
    await _menuController.reverse();
    if (mounted) setState(() => _showAddMenu = false);
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


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final isAccountant = settings.isAccountant;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _screenForIndex(_currentIndex),
          if (_showAddMenu) _buildAddMenu(isDark),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        showAccountantTab: isAccountant,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onAddPressed: _openMenu,
      ),
    );
  }

  Widget _buildAddMenu(bool isDark) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final accent = settings.accentColor;

    final items = [
      _MenuItemData(
        title: 'Смену',
        subtitle: 'Добавить в график',
        icon: Icons.event_available_rounded,
        color: accent,
        onTap: () async {
          await _closeMenu();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddShiftScreen()),
          );
          if (result == true && mounted) _refreshAllScreens();
        },
      ),
      _MenuItemData(
        title: 'Операцию',
        subtitle: 'Доход или расход',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF10b981),
        onTap: () async {
          await _closeMenu();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true && mounted) _refreshAllScreens();
        },
      ),
      _MenuItemData(
        title: 'Задачу',
        subtitle: 'Напоминание или дело',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF3b82f6),
        onTap: () async {
          await _closeMenu();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (result == true && mounted) _refreshAllScreens();
        },
      ),
      _MenuItemData(
        title: 'Flow AI',
        subtitle: 'Советник и прогноз',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF00e5b3),
        onTap: () async {
          await _closeMenu();
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen()));
          }
        },
      ),
    ];

    return FadeTransition(
      opacity: _menuFade,
      child: GestureDetector(
        onTap: _closeMenu,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _menuSlide,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1a1f2e).withOpacity(0.98)
                          : Colors.white.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Создать',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: _closeMenu,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark ? Colors.white60 : Colors.black45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Items
                        ...items.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return _AnimatedMenuItem(
                            data: item,
                            isDark: isDark,
                            delay: Duration(milliseconds: i * 50),
                            parentController: _menuController,
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _AnimatedMenuItem extends StatelessWidget {
  final _MenuItemData data;
  final bool isDark;
  final Duration delay;
  final AnimationController parentController;

  const _AnimatedMenuItem({
    required this.data,
    required this.isDark,
    required this.delay,
    required this.parentController,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay.inMilliseconds / 320.0;
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: parentController,
      curve: Interval(start.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
    ));
    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: parentController,
        curve: Interval(start.clamp(0.0, 1.0), 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: data.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : data.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(data.icon, color: data.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1e293b),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: data.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}