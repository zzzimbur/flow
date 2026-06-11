import '../widgets/enhanced_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';
import '../providers/subscription_provider.dart';
import 'main_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with TickerProviderStateMixin {
  String _selectedPeriod = 'month';
  bool _isLoading = true;

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _incomeByCategory = {};
  Map<String, double> _expenseByCategory = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadTransactions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
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
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (_selectedPeriod == 'week') {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
      } else if (_selectedPeriod == 'month') {
        startDate = DateTime(now.year, now.month, 1);
      } else {
        startDate = DateTime(now.year, 1, 1);
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      double income = 0.0;
      double expense = 0.0;
      Map<String, double> incomeCategories = {};
      Map<String, double> expenseCategories = {};
      List<Map<String, dynamic>> transactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble().abs();
        final isIncome = data['isIncome'] ?? false;
        final category = data['category'] ?? 'Другое';
        final date = (data['date'] as Timestamp).toDate();

        transactions.add({
          'id': doc.id,
          'amount': amount,
          'category': category,
          'isIncome': isIncome,
          'date': date,
          'note': data['note'] ?? '',
        });

        if (isIncome) {
          income += amount;
          incomeCategories[category] = (incomeCategories[category] ?? 0) + amount;
        } else {
          expense += amount;
          expenseCategories[category] = (expenseCategories[category] ?? 0) + amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _transactions = transactions;
          _incomeByCategory = incomeCategories;
          _expenseByCategory = expenseCategories;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      print('Ошибка загрузки транзакций: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final balance = _totalIncome - _totalExpense;
    final accent = Provider.of<SettingsProvider>(context, listen: false).accentColor;

    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    if (!subscriptionProvider.canAccessFinance) {
      return _buildPremiumRequired(context);
    }

    return AnimatedBackground(
      isDark: isDark,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, accent),
            _buildPeriodSelector(isDark, accent),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      color: accent,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBalanceCard(balance, isDark, accent),
                              const SizedBox(height: 24),
                              _buildStatsCards(isDark),
                              const SizedBox(height: 24),
                              if (_incomeByCategory.isNotEmpty || _expenseByCategory.isNotEmpty) ...[
                                _buildCategoriesSection(isDark),
                                const SizedBox(height: 24),
                              ],
                              _buildTransactionsSection(isDark),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b7ff5)),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💰 Финансы',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Отслеживай доходы и расходы',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              ).then((result) {
                if (result == true) _loadTransactions();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1e1e2e) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildPeriodButton('Неделя', 'week', isDark, accent),
            _buildPeriodButton('Месяц', 'month', isDark, accent),
            _buildPeriodButton('Год', 'year', isDark, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, bool isDark, Color accent) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPeriod = value);
          _loadTransactions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [accent, accent.withOpacity(0.75)],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ─── BALANCE CARD ────────────────────────────────────────────────────────────
  Widget _buildBalanceCard(double balance, bool isDark, Color accent) {
    final currency = Provider.of<SettingsProvider>(context, listen: false).currencySymbol;
    return Stack(
      children: [
        // Solid dark base
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131320) : const Color(0xFF1e1e2e),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Баланс" label
              Text(
                'Баланс',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.55),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              // Large balance number
              Text(
                '$currency${balance.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              // Two pills: income + expense
              Row(
                children: [
                  _buildBalancePill(
                    icon: Icons.arrow_downward,
                    label: '$currency${_totalIncome.toStringAsFixed(0)}',
                    color: const Color(0xFF10b981),
                  ),
                  const SizedBox(width: 10),
                  _buildBalancePill(
                    icon: Icons.arrow_upward,
                    label: '$currency${_totalExpense.toStringAsFixed(0)}',
                    color: const Color(0xFFef4444),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Accent left-border glow overlay
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent,
                  accent.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomLeft: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalancePill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS CARDS ─────────────────────────────────────────────────────────────
  Widget _buildStatsCards(bool isDark) {
    final currency = Provider.of<SettingsProvider>(context, listen: false).currencySymbol;
    return Row(
      children: [
        Expanded(
          child: _buildSolidStatCard(
            icon: Icons.arrow_downward,
            value: '$currency${_totalIncome.toStringAsFixed(0)}',
            label: 'Доходы',
            gradientColors: const [Color(0xFF10b981), Color(0xFF059669)],
            shadowColor: const Color(0xFF10b981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSolidStatCard(
            icon: Icons.arrow_upward,
            value: '$currency${_totalExpense.toStringAsFixed(0)}',
            label: 'Расходы',
            gradientColors: const [Color(0xFFef4444), Color(0xFFdc2626)],
            shadowColor: const Color(0xFFef4444),
          ),
        ),
      ],
    );
  }

  Widget _buildSolidStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradientColors,
    required Color shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CATEGORIES ──────────────────────────────────────────────────────────────
  Widget _buildCategoriesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 По категориям',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1e293b),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        if (_incomeByCategory.isNotEmpty) ...[
          _buildCategoryCard(
            title: 'Доходы',
            categories: _incomeByCategory,
            color: const Color(0xFF10b981),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
        ],
        if (_expenseByCategory.isNotEmpty)
          _buildCategoryCard(
            title: 'Расходы',
            categories: _expenseByCategory,
            color: const Color(0xFFef4444),
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required Map<String, double> categories,
    required Color color,
    required bool isDark,
  }) {
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categories.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  title == 'Доходы' ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedCategories.take(5).map((entry) {
            final percentage = (entry.value / total * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                      Text(
                        '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────────
  Widget _buildTransactionsSection(bool isDark) {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const Text(
                '💸',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Нет транзакций',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 История',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1e293b),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ..._transactions.map((transaction) => _buildTransactionCard(transaction, isDark)),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    final isIncome = transaction['isIncome'] as bool;
    final amount = transaction['amount'] as double;
    final category = transaction['category'] as String;
    final date = transaction['date'] as DateTime;
    final note = transaction['note'] as String;

    final borderColor = isIncome ? const Color(0xFF10b981) : const Color(0xFFef4444);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTransactionScreen(
              transactionId: transaction['id'],
              initialAmount: amount,
              initialCategory: category,
              initialIsIncome: isIncome,
              initialDate: date,
              initialNote: note,
              transactionData: {},
            ),
          ),
        ).then((result) {
          if (result == true) _loadTransactions();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [const Color(0xFF10b981), const Color(0xFF059669)]
                      : [const Color(0xFFef4444), const Color(0xFFdc2626)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}.${date.month}.${date.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isIncome ? const Color(0xFF10b981) : const Color(0xFFef4444),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRequired(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Премиум функция',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Управление финансами доступно только с Premium подпиской',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              GlassButton(
                text: 'Получить Premium',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(initialTab: 3),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
