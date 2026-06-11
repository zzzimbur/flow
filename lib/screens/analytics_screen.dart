import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/enhanced_glass_card.dart';
import '../providers/subscription_provider.dart';
import '../widgets/ad_banner.dart';
import 'ai_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'month';
  bool _isLoading = true;

  Map<String, dynamic> _weekStats = {};
  Map<String, dynamic> _monthStats = {};
  Map<String, dynamic> _yearStats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      
      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final now = DateTime.now();
      
      final weekStats = await _loadPeriodStats(userId, now.subtract(const Duration(days: 7)), now);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final monthStats = await _loadPeriodStats(userId, startOfMonth, endOfMonth);
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
      final yearStats = await _loadPeriodStats(userId, startOfYear, endOfYear);
      
      if (mounted) {
        setState(() {
          _weekStats = weekStats;
          _monthStats = monthStats;
          _yearStats = yearStats;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('Ошибка загрузки аналитики: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadPeriodStats(String userId, DateTime start, DateTime end) async {
    final shiftsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('shifts')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    
    double totalEarnings = 0.0;
    double totalHours = 0.0;
    int totalShifts = shiftsSnapshot.docs.length;
    
    for (var doc in shiftsSnapshot.docs) {
      final data = doc.data();
      final startTime = (data['startTime'] as Timestamp).toDate();
      final endTime = (data['endTime'] as Timestamp).toDate();
      final shiftHours = endTime.difference(startTime).inMinutes / 60.0;
      totalHours += shiftHours;
      
      final paymentType = data['paymentType'] ?? 'hourly';
      if (paymentType == 'hourly') {
        final hourlyRate = (data['hourlyRate'] ?? 0.0).toDouble();
        final paidTime = (data['paidTime'] ?? 0.0).toDouble();
        totalEarnings += hourlyRate * (paidTime > 0 ? paidTime : shiftHours);
      } else if (paymentType == 'perShift') {
        totalEarnings += (data['shiftRate'] ?? 0.0).toDouble();
      }
      
      totalEarnings += (data['bonus'] ?? 0.0).toDouble();
      totalEarnings -= (data['expenses'] ?? 0.0).toDouble();
    }
    
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    
    int completedTasks = 0;
    int totalTasks = tasksSnapshot.docs.length;
    
    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      if (data['isDone'] == true) {
        completedTasks++;
      }
    }
    
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    
    double totalExpenses = 0.0;
    Map<String, double> expensesByCategory = {};
    
    for (var doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0.0).toDouble();
      final isIncome = data['isIncome'] ?? false;
      final category = data['category'] ?? 'Другое';
      
      if (!isIncome) {
        totalExpenses += amount.abs();
        expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount.abs();
      }
    }
    
    String topExpenseCategory = 'Нет данных';
    double maxExpense = 0;
    expensesByCategory.forEach((category, amount) {
      if (amount > maxExpense) {
        maxExpense = amount;
        topExpenseCategory = category;
      }
    });
    
    double averageHourlyRate = totalHours > 0 ? totalEarnings / totalHours : 0;
    
    return {
      'totalEarnings': totalEarnings.toInt(),
      'totalExpenses': totalExpenses.toInt(),
      'totalHours': totalHours.toInt(),
      'totalShifts': totalShifts,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
      'averageHourlyRate': averageHourlyRate.toInt(),
      'topExpenseCategory': topExpenseCategory,
      'topCategory': 'Работа',
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accentColor = settings.themeMode == ThemeMode.light
        ? const Color(0xFF3b82f6)
        : const Color(0xFF2563eb);

  final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    return Scaffold(
      body: AnimatedBackground(
        isDark: isDark,
        child: Column(
          children: [
            if (!subscriptionProvider.isActive) const AdBanner(),
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    // Хедер
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Аналитика',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7b6ff0), Color(0xFF00e5b3)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 5),
                                  Text('Flow AI', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Селектор периода
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: EnhancedGlassCard(
                        padding: const EdgeInsets.all(4),
                        enableHover: false,
                        enableShadow: false,
                        child: Row(
                          children: [
                            _buildPeriodButton('Неделя', 'week', isDark, accentColor),
                            _buildPeriodButton('Месяц', 'month', isDark, accentColor),
                            _buildPeriodButton('Год', 'year', isDark, accentColor),
                          ],
                        ),
                      ),
                    ),

                    // Контент
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: accentColor,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                child: _buildContent(isDark, accentColor),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color accentColor) {
    final stats = _selectedPeriod == 'week'
        ? _weekStats
        : _selectedPeriod == 'month'
            ? _monthStats
            : _yearStats;

    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Нет данных за выбранный период',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Финансы',
          icon: Icons.account_balance_wallet,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildFinanceStats(stats, isDark),
        const SizedBox(height: 24),

        SectionHeader(
          title: 'Работа',
          icon: Icons.work,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildWorkStats(stats, isDark, accentColor),
        const SizedBox(height: 24),

        SectionHeader(
          title: 'Продуктивность',
          icon: Icons.check_circle,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTaskStats(stats, isDark),
        const SizedBox(height: 24),

        SectionHeader(
          title: 'Инсайты',
          icon: Icons.lightbulb,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildInsights(stats, isDark, accentColor),
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPeriodButton(String label, String value, bool isDark, Color accentColor) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPeriod = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceStats(Map<String, dynamic> stats, bool isDark) {
    final earnings = stats['totalEarnings'] as int;
    final expenses = stats['totalExpenses'] as int;
    final balance = earnings - expenses;

    return EnhancedGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Чистый доход',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${_formatNumber(balance)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: balance >= 0
                  ? const Color(0xFF10b981)
                  : const Color(0xFFef4444),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Доходы',
                  value: '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${_formatNumber(earnings)}',
                  color: const Color(0xFF10b981),
                  icon: Icons.trending_up,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Расходы',
                  value: '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${_formatNumber(expenses)}',
                  color: const Color(0xFFef4444),
                  icon: Icons.trending_down,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStats(Map<String, dynamic> stats, bool isDark, Color accentColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Часов',
                value: '${stats['totalHours']}ч',
                color: accentColor,
                icon: Icons.schedule,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Смен',
                value: '${stats['totalShifts']}',
                color: accentColor,
                icon: Icons.event,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        EnhancedGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments,
                  color: Color(0xFF10b981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Средняя ставка',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Text(
                      '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${stats['averageHourlyRate']}/час',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStats(Map<String, dynamic> stats, bool isDark) {
    final completed = stats['completedTasks'] as int;
    final total = stats['totalTasks'] as int;
    final progress = total > 0 ? completed / total : 0.0;

    return EnhancedGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Выполнено задач',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '$completed / $total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10b981),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% завершено',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(Map<String, dynamic> stats, bool isDark, Color accentColor) {
    return Column(
      children: [
        if (stats.containsKey('topExpenseCategory'))
          _buildInsightCard(
            icon: Icons.shopping_cart,
            title: 'Топ категория расходов',
            value: stats['topExpenseCategory'],
            color: const Color(0xFFef4444),
            isDark: isDark,
          ),
        if (stats.containsKey('topCategory')) ...[
          const SizedBox(height: 8),
          _buildInsightCard(
            icon: Icons.work,
            title: 'Топ категория доходов',
            value: stats['topCategory'],
            color: accentColor,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
      enableHover: false,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}