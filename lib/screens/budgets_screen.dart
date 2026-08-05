import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/coinka.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<Map<String, dynamic>> _budgets = [];
  bool _isLoading = true;

  static const _periods = {
    'day': 'В день',
    'week': 'В неделю',
    'month': 'В месяц',
  };

  // Все категории расходов из Coinka
  static const _categories = [
    'Продукты', 'Транспорт', 'Развлечения', 'Здоровье',
    'Образование', 'Кафе', 'Одежда', 'Дом', 'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) { setState(() => _isLoading = false); return; }
    try {
      final budgetSnap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('budgets').get();
      final budgets = budgetSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      // Считаем реальные расходы из транзакций за текущий период
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final dayStart = DateTime(now.year, now.month, now.day);

      final txSnap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      // Группируем расходы по категории и периоду
      final Map<String, Map<String, double>> spent = {};
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        if (amount >= 0) continue; // только расходы (amount < 0)
        final category = (data['category'] as String?) ?? 'Другое';
        final date = (data['date'] as Timestamp?)?.toDate() ?? now;

        spent[category] ??= {'day': 0, 'week': 0, 'month': 0};
        final abs = amount.abs();
        spent[category]!['month'] = (spent[category]!['month'] ?? 0) + abs;
        if (!date.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day))) {
          spent[category]!['week'] = (spent[category]!['week'] ?? 0) + abs;
        }
        if (!date.isBefore(dayStart)) {
          spent[category]!['day'] = (spent[category]!['day'] ?? 0) + abs;
        }
      }

      for (final b in budgets) {
        final category = b['category'] as String? ?? 'Другое';
        final period = b['period'] as String? ?? 'month';
        b['spent'] = spent[category]?[period] ?? 0.0;
      }

      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBudget(String category, double limit, String period) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('budgets').add({
      'category': category,
      'limit': limit,
      'period': period,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _loadBudgets();
  }

  Future<void> _deleteBudget(String id) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('budgets').doc(id).delete();
    _loadBudgets();
  }

  void _showAddDialog(BuildContext context) {
    String selectedCategory = _categories[0];
    String selectedPeriod = 'month';
    final limitCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.ckCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 3, decoration: BoxDecoration(color: context.ckMuted, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Новый бюджет', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText)),
                const SizedBox(height: 16),

                Text('Категория', style: TextStyle(fontSize: 12, color: context.ckHint, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _categories.map((cat) {
                    final sel = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setS(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? Coinka.accentDim : context.ckS2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? Coinka.accent : context.ckBorder),
                        ),
                        child: Text('${Coinka.emojiFor(cat)} $cat',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Coinka.accent : context.ckHint)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Text('Период', style: TextStyle(fontSize: 12, color: context.ckHint, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: context.ckS2, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: _periods.entries.map((e) {
                      final sel = selectedPeriod == e.key;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () { HapticFeedback.selectionClick(); setS(() => selectedPeriod = e.key); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? Coinka.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.black : context.ckHint))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Лимит', style: TextStyle(fontSize: 12, color: context.ckHint, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(color: context.ckText, fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0 ₽', hintStyle: TextStyle(color: context.ckHint),
                    suffixText: '₽',
                    suffixStyle: TextStyle(color: context.ckHint, fontSize: 15),
                    filled: true, fillColor: context.ckS2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.ckBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.ckBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: context.ckS2, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                        child: Center(child: Text('Отмена', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.ckHint))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final limit = double.tryParse(limitCtrl.text.replaceAll(',', '.'));
                        if (limit != null && limit > 0) {
                          Navigator.pop(ctx);
                          _addBudget(selectedCategory, limit, selectedPeriod);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(child: Text('Создать', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
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
                Expanded(child: Text('Бюджеты', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); _showAddDialog(context); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]), borderRadius: BorderRadius.circular(20)),
                    child: const Text('+ Добавить', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Coinka.accent))
                : _budgets.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('💰', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text('Нет бюджетов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText)),
                      const SizedBox(height: 8),
                      Text('Добавь лимит трат\nпо категориям', style: TextStyle(fontSize: 14, color: context.ckHint), textAlign: TextAlign.center),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      itemCount: _budgets.length,
                      itemBuilder: (ctx, i) => _buildBudgetCard(ctx, _budgets[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Map<String, dynamic> b) {
    final category = b['category'] as String? ?? 'Другое';
    final limit = ((b['limit'] as num?) ?? 0).toDouble();
    final spent = (b['spent'] as num? ?? 0).toDouble();
    final period = b['period'] as String? ?? 'month';
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > limit;
    final emoji = Coinka.emojiFor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.ckCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOver ? Coinka.red.withOpacity(0.4) : context.ckBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.ckText)),
            Text(_periods[period] ?? 'В месяц', style: TextStyle(fontSize: 11, color: context.ckHint)),
          ])),
          GestureDetector(onTap: () => _deleteBudget(b['id']), child: const Text('🗑️', style: TextStyle(fontSize: 18))),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: context.ckS2,
            valueColor: AlwaysStoppedAnimation(isOver ? Coinka.red : Coinka.accent),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${spent.round()} ₽ из ${limit.round()} ₽', style: TextStyle(fontSize: 13, color: context.ckHint)),
          Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isOver ? Coinka.red : Coinka.accent)),
        ]),
      ]),
    );
  }
}
