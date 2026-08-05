import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/ad_banner.dart';
import '../theme/coinka.dart';
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
    final currency = Provider.of<SettingsProvider>(context, listen: false).currencySymbol;
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: context.ckBg,
      body: Column(
        children: [
          if (!subscriptionProvider.isActive) const AdBanner(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.ckHint, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(child: Text('Аналитика', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(children: [
                              Text('✨', style: TextStyle(fontSize: 13)),
                              SizedBox(width: 4),
                              Text('Flow AI', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Период
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                      child: Row(children: [
                        _buildPeriodButton('Неделя', 'week'),
                        _buildPeriodButton('Месяц', 'month'),
                        _buildPeriodButton('Год', 'year'),
                      ]),
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Coinka.accent))
                      : RefreshIndicator(
                          onRefresh: _loadData, color: Coinka.accent,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                            child: _buildContent(currency),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String currency) {
    final stats = _selectedPeriod == 'week' ? _weekStats : _selectedPeriod == 'month' ? _monthStats : _yearStats;

    if (stats.isEmpty) {
      return Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: Text('Нет данных за выбранный период', style: TextStyle(fontSize: 15, color: context.ckHint)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💰 ФИНАНСЫ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _buildFinanceStats(stats, currency),
        const SizedBox(height: 20),

        Text('💼 РАБОТА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _buildWorkStats(stats, currency),
        const SizedBox(height: 20),

        Text('✅ ПРОДУКТИВНОСТЬ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _buildTaskStats(stats),
        const SizedBox(height: 20),

        Text('💡 ИНСАЙТЫ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _buildInsights(stats),
      ],
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedPeriod = value); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Coinka.accent.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Coinka.accent : Colors.transparent, width: 1.5),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: isSelected ? Coinka.accent : context.ckHint,
          )),
        ),
      ),
    );
  }

  Widget _buildFinanceStats(Map<String, dynamic> stats, String currency) {
    final earnings = stats['totalEarnings'] as int;
    final expenses = stats['totalExpenses'] as int;
    final balance = earnings - expenses;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.ckBorder)),
      child: Column(
        children: [
          Text('Чистый доход', style: TextStyle(fontSize: 13, color: context.ckHint)),
          const SizedBox(height: 6),
          Text('$currency${_formatNumber(balance)}', style: TextStyle(
            fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1,
            color: balance >= 0 ? Coinka.green : Coinka.red,
          )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildStatCard(label: 'Доходы', value: '$currency${_formatNumber(earnings)}', color: Coinka.green, emoji: '📈')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(label: 'Расходы', value: '$currency${_formatNumber(expenses)}', color: Coinka.red, emoji: '📉')),
          ]),
        ],
      ),
    );
  }

  Widget _buildWorkStats(Map<String, dynamic> stats, String currency) {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildStatCard(label: 'Часов', value: '${stats['totalHours']}ч', color: Coinka.accent2, emoji: '⏱️')),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(label: 'Смен', value: '${stats['totalShifts']}', color: Coinka.accent, emoji: '📋')),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
        child: Row(children: [
          const Text('💵', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Средняя ставка', style: TextStyle(fontSize: 13, color: context.ckHint)),
            Text('$currency${stats['averageHourlyRate']}/час', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText)),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildTaskStats(Map<String, dynamic> stats) {
    final completed = stats['completedTasks'] as int;
    final total = stats['totalTasks'] as int;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Выполнено задач', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.ckText)),
          Text('$completed / $total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.ckHint)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
          value: progress, minHeight: 6,
          backgroundColor: context.ckMuted, valueColor: const AlwaysStoppedAnimation(Coinka.accent),
        )),
        const SizedBox(height: 6),
        Text('${(progress * 100).toStringAsFixed(0)}% завершено', style: TextStyle(fontSize: 13, color: context.ckHint)),
      ]),
    );
  }

  Widget _buildInsights(Map<String, dynamic> stats) {
    return Column(children: [
      if (stats.containsKey('topExpenseCategory'))
        _buildInsightCard(emoji: '🛍️', title: 'Топ расходов', value: stats['topExpenseCategory'], color: Coinka.red),
      if (stats.containsKey('topCategory')) ...[
        const SizedBox(height: 8),
        _buildInsightCard(emoji: '💼', title: 'Топ доходов', value: stats['topCategory'], color: Coinka.accent),
      ],
    ]);
  }

  Widget _buildStatCard({required String label, required String value, required Color color, required String emoji}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: context.ckHint, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildInsightCard({required String emoji, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, color: context.ckHint)),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.ckText)),
        ])),
      ]),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}