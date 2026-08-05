import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../widgets/custom_bottom_nav.dart';
import '../providers/settings_provider.dart';
import '../theme/coinka.dart';
import 'finance_screen.dart';
import 'shifts_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
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
  Key _financeKey = UniqueKey();
  Key _shiftsKey = UniqueKey();
  Key _tasksKey = UniqueKey();
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

  // 0=Финансы, 1=Смены, 2=Задачи, 3=Настройки, 4=Табель (бухгалтер)
  Widget _screenForIndex(int index) {
    switch (index) {
      case 0: return FinanceScreen(key: _financeKey);
      case 1: return ShiftsScreen(key: _shiftsKey);
      case 2: return TasksScreen(key: _tasksKey);
      case 3: return SettingsScreen(key: _settingsKey);
      case 4: return AccountantReportScreen(key: _accountantKey);
      default: return FinanceScreen(key: _financeKey);
    }
  }

  void _refreshAllScreens() {
    setState(() {
      _financeKey = UniqueKey();
      _shiftsKey = UniqueKey();
      _tasksKey = UniqueKey();
      _settingsKey = UniqueKey();
      _accountantKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isAccountant = settings.isAccountant;

    return Scaffold(
      backgroundColor: context.ckBg,
      body: Stack(
        children: [
          _screenForIndex(_currentIndex),
          if (_showAddMenu) _buildAddMenu(),
        ],
      ),
      // «+» вынесена в floating-кнопку НАД таб-баром, чтобы все вкладки
      // (включая «Табель») ровно помещались в ряд.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showAddMenu ? null : _buildAddFab(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        showAccountantTab: isAccountant,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildAddFab() {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); _openMenu(); },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Coinka.accent2, Coinka.accent],
          ),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(color: Coinka.accent.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildAddMenu() {
    final items = [
      _MenuItemData(
        title: 'Смену',
        subtitle: 'Добавить в график',
        emoji: '📅',
        color: Coinka.accent2,
        onTap: () async {
          await _closeMenu();
          if (!mounted) return;
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
        emoji: '💰',
        color: Coinka.green,
        onTap: () async {
          await _closeMenu();
          if (!mounted) return;
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
        emoji: '✅',
        color: const Color(0xFF3B82F6),
        onTap: () async {
          await _closeMenu();
          if (!mounted) return;
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
        emoji: '✦',
        color: Coinka.accent,
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
          color: Colors.black.withOpacity(0.6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _menuSlide,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    decoration: BoxDecoration(
                      color: context.ckS1,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.ckBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 4),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.ckBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Создать',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.ckText,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              GestureDetector(
                                onTap: _closeMenu,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: context.ckS2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: context.ckHint,
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
                            delay: Duration(milliseconds: i * 50),
                            parentController: _menuController,
                          );
                        }),
                        const SizedBox(height: 14),
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
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.onTap,
  });
}

class _AnimatedMenuItem extends StatelessWidget {
  final _MenuItemData data;
  final Duration delay;
  final AnimationController parentController;

  const _AnimatedMenuItem({
    required this.data,
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
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: data.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.ckCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.ckBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        data.emoji,
                        style: TextStyle(
                          fontSize: 19,
                          color: data.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.ckText,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.ckHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: data.color,
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
