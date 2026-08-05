import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/coinka.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  bool _isLoading = true;
  double _avgIncome = 0;
  double _avgExpense = 0;
  Map<String, double> _topExpenses = {};
  double _forecastBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) { setState(() => _isLoading = false); return; }

    try {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

      final snap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo))
          .get();

      double totalIncome = 0, totalExpense = 0;
      final categoryExpenses = <String, double>{};
      final monthlyIncome = <int, double>{};
      final monthlyExpense = <int, double>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final amount = ((data['amount'] as num?) ?? 0).toDouble().abs();
        final isIncome = data['isIncome'] as bool? ?? false;
        final category = data['category'] as String? ?? 'Другое';
        final date = (data['date'] as Timestamp).toDate();
        final monthKey = date.year * 12 + date.month;

        if (isIncome) {
          totalIncome += amount;
          monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + amount;
        } else {
          totalExpense += amount;
          monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0) + amount;
          categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
        }
      }

      final months = monthlyIncome.length.clamp(1, 3);
      _avgIncome = totalIncome / months;
      _avgExpense = totalExpense / months;
      _forecastBalance = _avgIncome - _avgExpense;

      final sorted = categoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      _topExpenses = Map.fromEntries(sorted.take(5));

      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _fmt(double v) {
    final currency = context.read<SettingsProvider>().currencySymbol;
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf $currency';
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
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.ckHint, size: 20), onPressed: () => Navigator.pop(context)),
                  Expanded(child: Text('Прогноз', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Coinka.accent))
                : _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero прогноза
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _forecastBalance >= 0
                  ? [Coinka.accent2, Coinka.accent]
                  : [Coinka.red.withOpacity(0.8), Coinka.red],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Прогноз на следующий месяц', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  '${_forecastBalance >= 0 ? '+' : '−'}${_fmt(_forecastBalance.abs())}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
                ),
                const SizedBox(height: 4),
                Text(
                  _forecastBalance >= 0 ? 'Ожидаемый профицит 🎉' : 'Ожидаемый дефицит ⚠️',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Средние показатели
          Text('СРЕДНЕЕ ЗА 3 МЕСЯЦА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statCard(context, '📈 Доходы', _avgIncome, Coinka.green)),
            const SizedBox(width: 10),
            Expanded(child: _statCard(context, '📉 Расходы', _avgExpense, Coinka.red)),
          ]),
          const SizedBox(height: 20),

          // Топ расходов
          if (_topExpenses.isNotEmpty) ...[
            Text('ТОП КАТЕГОРИЙ РАСХОДОВ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
              child: Column(
                children: _topExpenses.entries.map((entry) {
                  final maxVal = _topExpenses.values.first;
                  final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(Coinka.emojiFor(entry.key), style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.ckText))),
                          Text(_fmt(entry.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Coinka.red)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio, minHeight: 4,
                            backgroundColor: context.ckS2,
                            valueColor: const AlwaysStoppedAnimation(Coinka.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Совет
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Coinka.accentDim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Coinka.accent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 Совет', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Coinka.accent)),
                const SizedBox(height: 8),
                Text(
                  _forecastBalance >= 0
                    ? 'Хороший прогноз! Откладывай часть дохода на сбережения или цели.'
                    : 'Расходы превышают доходы. Проверь регулярные платежи и постарайся сократить топ категории.',
                  style: TextStyle(fontSize: 13, color: context.ckText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.ckHint)),
          const SizedBox(height: 6),
          Text(_fmt(value), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text('в месяц', style: TextStyle(fontSize: 11, color: context.ckHint)),
        ],
      ),
    );
  }
}
