import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/goal_provider.dart';
import '../theme/coinka.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';
import 'ai_screen.dart';
import 'budgets_screen.dart';
import 'goals_list_screen.dart';
import 'debts_screen.dart';
import 'recurring_screen.dart';
import 'forecast_screen.dart';
import 'analytics_screen.dart';
import 'budget_health_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  DateTime _month = DateTime.now();
  bool _isLoading = true;

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isNotEmpty) context.read<GoalProvider>().loadGoals(userId);
    });
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final startDate = DateTime(_month.year, _month.month, 1);
      final endDate = DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);

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
      final transactions = <Map<String, dynamic>>[];

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
        } else {
          expense += amount;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки транзакций: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
    _loadTransactions();
  }

  int get _healthScore {
    if (_totalIncome == 0 && _totalExpense == 0) return 0;
    final now = DateTime.now();
    final daysElapsed = now.day.clamp(1, 31);
    // Баланс (0–50)
    int balanceScore = 0;
    if (_totalIncome > 0) {
      balanceScore = ((_totalIncome - _totalExpense) / _totalIncome * 50).clamp(0, 50).round();
    }
    // Регулярность (0–30): уникальных дней с транзакциями
    final uniqueDays = _transactions.map((t) => (t['date'] as DateTime).day).toSet().length;
    final regularityScore = ((uniqueDays / daysElapsed) * 30).round();
    // Активность (0–20): количество операций
    final activityScore = (_transactions.length * 2).clamp(0, 20);
    return (balanceScore + regularityScore + activityScore).clamp(0, 100);
  }

  String get _healthGrade {
    final s = _healthScore;
    if (s >= 80) return 'A';
    if (s >= 65) return 'B';
    if (s >= 50) return 'C';
    if (s >= 35) return 'D';
    return 'F';
  }

  Color get _healthColor {
    final s = _healthScore;
    if (s >= 65) return Coinka.green;
    if (s >= 40) return const Color(0xFFf59e0b);
    return Coinka.red;
  }

  String _fmt(double v) {
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${v < 0 ? '−' : ''}$buf $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalIncome - _totalExpense;
    final bg = context.ckBg;
    final s2 = context.ckS2;

    return Container(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTransactions,
                color: Coinka.accent,
                backgroundColor: s2,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildFinanceHero(context, balance),
                    CoinkaAddButton(
                      label: 'Добавить операцию',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()))
                            .then((result) { if (result == true) _loadTransactions(); });
                      },
                    ),
                    _buildServicesGrid(context),
                    _buildDebtsPreview(context),
                    _buildGoalsSection(context),
                    CoinkaSectionHeader('Операции', textColor: context.ckHint),
                    if (_isLoading)
                      const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: Coinka.accent, strokeWidth: 2.5)))
                    else if (_transactions.isEmpty)
                      const CoinkaEmpty(emoji: '💸', text: 'Нет операций за этот месяц.\nДобавь первую!')
                    else
                      ..._buildTransactionsByDate(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceHero(BuildContext context, double balance) {
    final day = DateTime.now().day;
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12122A), Color(0xFF1A1A3A), Color(0xFF0F1A2A)],
          ),
          border: Border.all(color: const Color(0x407B6FF0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Орб справа сверху
              Positioned(top: -40, right: -20,
                child: Container(width: 140, height: 140,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0x2600E5B3), Colors.transparent])))),
              // Орб слева снизу
              Positioned(bottom: -30, left: -10,
                child: Container(width: 100, height: 100,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0x1F7B6FF0), Colors.transparent])))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  children: [
                    // Топ: день месяца + здоровье
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0x1F7B6FF0), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🗓', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('$day дн.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          ]),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetHealthScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: _isLoading ? const Color(0x1F7B6FF0) : _healthColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Text('📊', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                _isLoading ? '—' : '$_healthGrade $_healthScore',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _isLoading ? Colors.white54 : _healthColor),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 14, color: _isLoading ? Colors.white54 : _healthColor),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Центр: лейбл + сумма
                    Text('Баланс', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(colors: [Colors.white, Coinka.accent]).createShader(rect),
                      child: Text(
                        _isLoading ? '—' : _fmt(balance),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: Colors.white, height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Доходы | Расходы
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Column(children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Coinka.green)),
                              const SizedBox(width: 5),
                              Text('Доходы', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ]),
                            const SizedBox(height: 4),
                            Text(_isLoading ? '—' : _fmt(_totalIncome), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Coinka.green)),
                          ])),
                          Container(width: 1, color: const Color(0x20FFFFFF)),
                          Expanded(child: Column(children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Coinka.red)),
                              const SizedBox(width: 5),
                              Text('Расходы', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            ]),
                            const SizedBox(height: 4),
                            Text(_isLoading ? '—' : _fmt(_totalExpense), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Coinka.red)),
                          ])),
                        ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text('Финансы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.ckText)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Coinka.accentDim, borderRadius: BorderRadius.circular(10)),
              child: const Text('✦ AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Coinka.accent)),
            ),
          ),
          const SizedBox(width: 8),
          CoinkaMonthNav(
            label: '${coinkaMonths[_month.month - 1]} ${_month.year != DateTime.now().year ? _month.year : ''}'.trim(),
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final items = [
      _ServiceItem('💰', 'Бюджеты', 'лимиты трат', Coinka.accent2, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()))),
      _ServiceItem('🎯', 'Цели', 'накопления', Coinka.accent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsListScreen()))),
      _ServiceItem('💳', 'Долги', 'должники', Coinka.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen()))),
      _ServiceItem('🔄', 'Регулярные', 'подписки', const Color(0xFFf59e0b), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()))),
      _ServiceItem('📊', 'Прогноз', 'след. месяц', const Color(0xFF3b82f6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForecastScreen()))),
      _ServiceItem('📈', 'Аналитика', 'статистика', const Color(0xFF8b5cf6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('СЕРВИСЫ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.08,
            children: items.map((item) => _buildServiceCard(context, item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem item) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); item.onTap(); },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.ckCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.ckBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: item.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 18))),
            ),
            const Spacer(),
            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.ckText)),
            const SizedBox(height: 2),
            Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.ckHint)),
          ],
        ),
      ),
    );
  }

  // ─── Долги (превью) ────────────────────────────────────────────────────────

  Widget _buildDebtsPreview(BuildContext context) {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users').doc(userId).collection('debts')
          .where('isPaid', isEqualTo: false).get()
          .then((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
      builder: (ctx, snap) {
        final debts = snap.data ?? [];
        if (debts.isEmpty) return const SizedBox.shrink();

        final iOwe = debts.where((d) => d['iOwe'] == true).fold<double>(0, (s, d) => s + ((d['amount'] as num?) ?? 0));
        final oweMe = debts.where((d) => d['iOwe'] == false).fold<double>(0, (s, d) => s + ((d['amount'] as num?) ?? 0));

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen())),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ctx.ckCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Coinka.red.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Text('💳', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text('Долги', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ctx.ckText))),
                if (iOwe > 0) ...[
                  Text('−${iOwe.round()} ₽', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Coinka.red)),
                  const SizedBox(width: 10),
                ],
                if (oweMe > 0)
                  Text('+${oweMe.round()} ₽', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Coinka.green)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 16, color: ctx.ckHint),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ─── Цели ──────────────────────────────────────────────────────────────────

  Widget _buildGoalsSection(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (ctx, goalProvider, _) {
        final goals = goalProvider.goals;
        if (goals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoinkaSectionHeader(
              'Цели',
              textColor: ctx.ckHint,
              trailing: GestureDetector(
                onTap: () {
                  Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AddGoalScreen()))
                      .then((_) {
                    final userId = ctx.read<AuthProvider>().userId;
                    if (userId.isNotEmpty) ctx.read<GoalProvider>().loadGoals(userId);
                  });
                },
                child: const Text('+ Добавить', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Coinka.accent)),
              ),
            ),
            ...goals.map((g) => _buildGoalCard(ctx, g)),
          ],
        );
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, dynamic goal) {
    final progress = goal.progress as double;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => EditGoalScreen(goal: goal)))
            .then((_) {
          final userId = context.read<AuthProvider>().userId;
          if (userId.isNotEmpty) context.read<GoalProvider>().loadGoals(userId);
        });
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ckCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.ckBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.icon as String? ?? '🎯', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(goal.name as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.ckText),
                    overflow: TextOverflow.ellipsis),
                ),
                Text('${(progress * 100).round()}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Coinka.accent)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress, minHeight: 5,
                backgroundColor: context.ckS2,
                valueColor: const AlwaysStoppedAnimation(Coinka.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text('${_fmt(goal.currentAmount as double)} из ${_fmt(goal.targetAmount as double)}',
              style: TextStyle(fontSize: 12, color: context.ckHint)),
          ],
        ),
      ),
    );
  }

  // ─── Операции по датам ─────────────────────────────────────────────────────

  List<Widget> _buildTransactionsByDate(BuildContext context) {
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (final tx in _transactions) {
      final date = tx['date'] as DateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (lastDate != dateKey) {
        lastDate = dateKey;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Text(
            _dateLabel(dateKey).toUpperCase(),
            style: TextStyle(fontSize: 11, color: context.ckMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ));
      }
      widgets.add(_buildTransactionItem(context, tx));
    }
    return widgets;
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return 'Сегодня';
    if (d == today.subtract(const Duration(days: 1))) return 'Вчера';
    return '${d.day} ${coinkaMonths[d.month - 1].toLowerCase()}';
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> tx) {
    final isIncome = tx['isIncome'] as bool;
    final amount = tx['amount'] as double;
    final category = tx['category'] as String;
    final note = tx['note'] as String;
    final emoji = Coinka.emojiFor(category, isIncome: isIncome);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditTransactionScreen(
              transactionId: tx['id'],
              initialAmount: amount,
              initialCategory: category,
              initialIsIncome: isIncome,
              initialDate: tx['date'],
              initialNote: note,
              transactionData: {},
            ),
          ),
        ).then((result) { if (result == true) _loadTransactions(); });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.ckBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isIncome ? Coinka.accentDim : const Color(0x1FFF4D6D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.isNotEmpty ? note : category,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.ckText),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(category, style: TextStyle(fontSize: 12, color: context.ckHint)),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '−'}${_fmt(amount)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isIncome ? Coinka.green : Coinka.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ServiceItem(this.emoji, this.title, this.subtitle, this.color, this.onTap);
}
