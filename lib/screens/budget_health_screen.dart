import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/coinka.dart';

class BudgetHealthScreen extends StatefulWidget {
  const BudgetHealthScreen({super.key});

  @override
  State<BudgetHealthScreen> createState() => _BudgetHealthScreenState();
}

class _BudgetHealthScreenState extends State<BudgetHealthScreen> {
  bool _isLoading = true;
  int _discipline = 0;
  int _overBudgetDays = 0;
  int _stability = 0;
  int _balance = 0;
  int _regularity = 0;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  Future<void> _compute() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) { setState(() => _isLoading = false); return; }

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      final budgetSnap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('budgets').get();

      // Группируем расходы по дням
      final dailyExpenses = <int, double>{};
      double totalIncome = 0, totalExpense = 0;
      final daysWithTx = <int>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final isIncome = data['isIncome'] as bool? ?? false;
        final amount = ((data['amount'] as num?) ?? 0).toDouble().abs();
        final date = (data['date'] as Timestamp).toDate();
        final dayKey = date.day;

        daysWithTx.add(dayKey);
        if (isIncome) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
          dailyExpenses[dayKey] = (dailyExpenses[dayKey] ?? 0) + amount;
        }
      }

      // --- Дисциплина: наличие бюджетов и соблюдение лимитов ---
      if (budgetSnap.docs.isNotEmpty) {
        int withinBudget = 0;
        for (final b in budgetSnap.docs) {
          final data = b.data();
          final spent = (data['spent'] as num? ?? 0).toDouble();
          final limit = ((data['limit'] as num?) ?? 0).toDouble();
          if (spent <= limit) withinBudget++;
        }
        _discipline = ((withinBudget / budgetSnap.docs.length) * 100).round();
      } else {
        _discipline = 50;
      }

      // --- Дни превышения: дней когда расходы > среднего * 2 ---
      if (dailyExpenses.isNotEmpty) {
        final avgDaily = totalExpense / now.day;
        _overBudgetDays = dailyExpenses.values.where((v) => v > avgDaily * 2).length;
      }

      // --- Стабильность: равномерность расходов (0-100) ---
      if (dailyExpenses.length > 1) {
        final values = dailyExpenses.values.toList();
        final avg = values.reduce((a, b) => a + b) / values.length;
        final variance = values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) / values.length;
        final stdDev = variance > 0 ? variance.sqrt() : 0;
        final cv = avg > 0 ? stdDev / avg : 1;
        _stability = (100 - (cv * 100).clamp(0, 100)).round();
      }

      // --- Баланс: соотношение доходов и расходов ---
      if (totalIncome > 0) {
        _balance = ((totalIncome - totalExpense) / totalIncome * 100).clamp(0, 100).round();
      }

      // --- Регулярность: % дней с транзакциями в этом месяце ---
      _regularity = ((daysWithTx.length / now.day) * 100).round();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalScore {
    return ((_discipline * 0.3) + ((_overBudgetDays == 0 ? 100 : (100 - _overBudgetDays * 5).clamp(0, 100)) * 0.2) + (_stability * 0.2) + (_balance * 0.2) + (_regularity * 0.1)).round();
  }

  String get _grade {
    final s = _totalScore;
    if (s >= 90) return 'A+';
    if (s >= 80) return 'A';
    if (s >= 70) return 'B';
    if (s >= 60) return 'C';
    if (s >= 50) return 'D';
    return 'F';
  }

  Color get _gradeColor {
    final s = _totalScore;
    if (s >= 70) return Coinka.green;
    if (s >= 50) return const Color(0xFFf59e0b);
    return Coinka.red;
  }

  String get _advice {
    final s = _totalScore;
    if (s >= 80) return 'Отличная финансовая дисциплина! Продолжайте в том же духе и рассмотрите увеличение накоплений.';
    if (s >= 60) return 'Неплохой результат. Поработайте над стабильностью расходов и чаще ведите учёт.';
    if (s >= 40) return 'Ваши результаты показывают, что есть значительные проблемы со стабильностью и балансом в бюджете. Рекомендую начать с создания резервного фонда для непредвиденных расходов.';
    return 'Финансовое состояние требует внимания. Начните с фиксации всех расходов и установки лимитов по основным категориям.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ckBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.ckHint, size: 20), onPressed: () => Navigator.pop(context)),
                Expanded(child: Text('Здоровье бюджета', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
              ]),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Coinka.accent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок с оценкой
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.ckCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.ckBorder),
                          ),
                          child: Row(children: [
                            const Text('📊', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Здоровье бюджета', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.ckText)),
                              Text('За текущий месяц', style: TextStyle(fontSize: 12, color: context.ckHint)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_grade, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _gradeColor, height: 1)),
                              Text('$_totalScore/100', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gradeColor)),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // Показатели
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.ckCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.ckBorder),
                          ),
                          child: Column(children: [
                            _metric(context, 'Дисциплина', 'Соблюдение лимитов бюджета', _discipline, 100),
                            _divider(context),
                            _metricInverse(context, 'Дни превышения', 'Дни, когда бюджет был превышен', _overBudgetDays, 30),
                            _divider(context),
                            _metric(context, 'Стабильность', 'Равномерность ежедневных трат', _stability, 100),
                            _divider(context),
                            _metric(context, 'Баланс', 'Соотношение доходов и расходов', _balance, 100),
                            _divider(context),
                            _metric(context, 'Регулярность', 'Как часто ведёте учёт', _regularity, 100),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // Совет
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _gradeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _gradeColor.withOpacity(0.25)),
                          ),
                          child: Text(_advice, style: TextStyle(fontSize: 14, color: context.ckText, height: 1.5)),
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

  Widget _divider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: context.ckBorder),
  );

  Widget _metric(BuildContext context, String title, String subtitle, int value, int max) {
    final ratio = (value / max).clamp(0.0, 1.0);
    final Color color = ratio >= 0.7 ? Coinka.green : (ratio >= 0.5 ? const Color(0xFFf59e0b) : Coinka.red);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.ckText)),
        Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: ratio, minHeight: 5, backgroundColor: context.ckS2, valueColor: AlwaysStoppedAnimation(color)),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(fontSize: 11, color: context.ckHint)),
    ]);
  }

  Widget _metricInverse(BuildContext context, String title, String subtitle, int value, int max) {
    final ratio = (value / max).clamp(0.0, 1.0);
    final Color color = ratio == 0 ? Coinka.green : (ratio <= 0.2 ? const Color(0xFFf59e0b) : Coinka.red);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.ckText)),
        Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: ratio, minHeight: 5, backgroundColor: context.ckS2, valueColor: AlwaysStoppedAnimation(color)),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(fontSize: 11, color: context.ckHint)),
    ]);
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) return 0;
    double x = this;
    double r = x;
    for (int i = 0; i < 20; i++) r = (r + x / r) / 2;
    return r;
  }
}
