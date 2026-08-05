import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/goal_provider.dart';
import '../models/goal_model.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';
import '../providers/subscription_provider.dart';
import '../widgets/ad_banner.dart';
import '../widgets/enhanced_glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  double _monthEarnings = 0.0;
  double _monthHours = 0.0;
  int _todayTasks = 0;
  int _monthShifts = 0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final goalProvider = context.read<GoalProvider>();
      final userId = authProvider.userId;

      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      goalProvider.loadGoals(userId);

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Загружаем смены
      final shiftsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double earnings = 0.0;
      double hours = 0.0;

      for (var doc in shiftsSnapshot.docs) {
        final data = doc.data();
        final startTime = (data['startTime'] as Timestamp).toDate();
        final endTime = (data['endTime'] as Timestamp).toDate();
        final shiftHours = endTime.difference(startTime).inMinutes / 60.0;
        hours += shiftHours;

        final paymentType = data['paymentType'] ?? 'hourly';
        if (paymentType == 'hourly') {
          final hourlyRate = (data['hourlyRate'] ?? 0.0).toDouble();
          final paidTime = (data['paidTime'] ?? 0.0).toDouble();
          earnings += hourlyRate * (paidTime > 0 ? paidTime : shiftHours);
        } else if (paymentType == 'perShift') {
          earnings += (data['shiftRate'] ?? 0.0).toDouble();
        }

        earnings += (data['bonus'] ?? 0.0).toDouble();
        earnings -= (data['expenses'] ?? 0.0).toDouble();
      }

      // Загружаем задачи
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('isDone', isEqualTo: false)
          .get();

      // Загружаем транзакции
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final isIncome = data['isIncome'] ?? false;

        if (isIncome) {
          totalIncome += amount.abs();
        } else {
          totalExpense += amount.abs();
        }
      }

      setState(() {
        _monthEarnings = earnings;
        _monthHours = hours;
        _monthShifts = shiftsSnapshot.docs.length;
        _todayTasks = tasksSnapshot.docs.length;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _getDateChip() {
    final now = DateTime.now();
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, ${now.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accent = settings.accentColor;
    final balance = _totalIncome - _totalExpense;
    final userName = settings.userName.split(' ')[0];
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return AnimatedBackground(
      isDark: isDark,
      child: Column(
        children: [
          if (!subscriptionProvider.isActive) const AdBanner(),
          Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _isLoading
                      ? _buildLoadingState(isDark, accent)
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                child: _buildHeader(userName, isDark, accent),
                              ),
                              const SizedBox(height: 28),
                              _buildHeroBalance(
                                balance,
                                _totalIncome,
                                _totalExpense,
                                isDark,
                                accent,
                                settings.currencySymbol,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildStatsRow(isDark, accent, settings.currencySymbol),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildActivityRow(isDark, accent),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildGoalsSection(context, balance, isDark, accent, settings.currencySymbol),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Color accent) {
    return SizedBox(
      height: 600,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(String userName, bool isDark, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDateChip(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Hero Balance ──────────────────────────────────────────────────────────

  Widget _buildHeroBalance(
    double balance,
    double income,
    double expense,
    bool isDark,
    Color accent,
    String symbol,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF1e293b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Баланс месяца',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$symbol${balance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFinancePill(
                  arrow: '↗',
                  label: 'Доходы',
                  value: income,
                  color: const Color(0xFF10b981),
                  symbol: symbol,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancePill(
                  arrow: '↙',
                  label: 'Расходы',
                  value: expense,
                  color: const Color(0xFFef4444),
                  symbol: symbol,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancePill({
    required String arrow,
    required String label,
    required double value,
    required Color color,
    required String symbol,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.white.withOpacity(0.9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$symbol${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark, Color accent, String symbol) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassStatCard(
            icon: Icons.schedule_rounded,
            iconColor: accent,
            value: '${_monthHours.toStringAsFixed(0)}ч',
            label: 'Часов в месяце',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassStatCard(
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF10b981),
            value: '$symbol${_monthEarnings.toStringAsFixed(0)}',
            label: 'Заработано',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ─── Activity Row ──────────────────────────────────────────────────────────

  Widget _buildActivityRow(bool isDark, Color accent) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassStatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF3b82f6),
            value: '$_todayTasks',
            label: 'Задач сегодня',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassStatCard(
            icon: Icons.event_available_rounded,
            iconColor: accent,
            value: '$_monthShifts',
            label: 'Смен в месяце',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.white.withOpacity(0.9),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                  letterSpacing: -1,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.45),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Goals Section ─────────────────────────────────────────────────────────

  Widget _buildGoalsSection(
    BuildContext context,
    double balance,
    bool isDark,
    Color accent,
    String symbol,
  ) {
    return Consumer<GoalProvider>(
      builder: (context, goalProvider, child) {
        final goals = goalProvider.goals;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Цели',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddGoalScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (goals.isEmpty)
              _buildEmptyGoals(isDark)
            else
              ...goals.map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGoalCard(context, goal, isDark, accent, symbol),
                  )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyGoals(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.white.withOpacity(0.9),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет целей',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withOpacity(0.45)
                        : Colors.black.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Нажмите + чтобы добавить первую цель',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.25),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Goal Card ─────────────────────────────────────────────────────────────

  Widget _buildGoalCard(
    BuildContext context,
    GoalModel goal,
    bool isDark,
    Color accent,
    String symbol,
  ) {
    final progress = goal.progress;
    final isAchieved = goal.isCompleted;
    final progressColor = isAchieved ? const Color(0xFF10b981) : accent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditGoalScreen(goal: goal),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.18)
                    : Colors.white.withOpacity(0.9),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          goal.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          goal.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1e293b),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${goal.progressPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Amounts row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Накоплено: $symbol${goal.currentAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        '$symbol${goal.targetAmount.toStringAsFixed(0)} цель',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
