import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/coinka.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  static const _periods = {
    'daily': 'Ежедневно',
    'weekly': 'Еженедельно',
    'monthly': 'Ежемесячно',
    'yearly': 'Ежегодно',
  };

  static const _emojis = [
    '📺', '🎵', '💪', '☁️', '📱', '🎮', '📰', '🔐',
    '🛒', '💊', '🏠', '🚗', '💡', '💧', '📡', '🍕',
    '☕', '💈', '🎓', '🧘',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) { setState(() => _isLoading = false); return; }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('recurring')
          .orderBy('createdAt', descending: true).get();
      setState(() {
        _items = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _add(Map<String, dynamic> data) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('recurring')
        .add({...data, 'isActive': true, 'createdAt': FieldValue.serverTimestamp()});
    _load();
  }

  Future<void> _delete(String id) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('recurring').doc(id).delete();
    _load();
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String period = 'monthly';
    String emoji = '📺';
    bool isIncome = false;
    DateTime nextDate = DateTime.now().add(const Duration(days: 30));
    final outerContext = context;

    showModalBottomSheet(
      context: outerContext,
      backgroundColor: outerContext.ckCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Widget field(TextEditingController c, String hint, {bool isNum = false}) => TextField(
            controller: c,
            keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: TextStyle(color: outerContext.ckText, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint, hintStyle: TextStyle(color: outerContext.ckHint),
              filled: true, fillColor: outerContext.ckS2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: outerContext.ckBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: outerContext.ckBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
            ),
          );

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 3, decoration: BoxDecoration(color: outerContext.ckMuted, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),

                  // Расход / Доход
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: outerContext.ckS2, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      _typeBtn(ctx, 'Расход', !isIncome, Coinka.red, () => setS(() => isIncome = false)),
                      _typeBtn(ctx, 'Доход', isIncome, Coinka.green, () => setS(() => isIncome = true)),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Emoji picker
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _emojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final e = _emojis[i];
                        final sel = emoji == e;
                        return GestureDetector(
                          onTap: () => setS(() => emoji = e),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: sel ? Coinka.accentDim : outerContext.ckS2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sel ? Coinka.accent : outerContext.ckBorder),
                            ),
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  field(nameCtrl, 'Название'),
                  const SizedBox(height: 10),

                  // Сумма + RUB
                  Row(children: [
                    Expanded(child: field(amountCtrl, 'Сумма', isNum: true)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(color: outerContext.ckS2, borderRadius: BorderRadius.circular(12), border: Border.all(color: outerContext.ckBorder)),
                      child: Text('RUB', style: TextStyle(color: outerContext.ckHint, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  field(noteCtrl, 'Заметка (необязательно)'),
                  const SizedBox(height: 14),

                  // Период
                  Text('Периодичность', style: TextStyle(fontSize: 12, color: outerContext.ckHint, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _periods.entries.map((e) {
                      final sel = period == e.key;
                      return GestureDetector(
                        onTap: () => setS(() => period = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? Coinka.accentDim : outerContext.ckS2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? Coinka.accent : outerContext.ckBorder),
                          ),
                          child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Coinka.accent : outerContext.ckHint)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Следующая дата — CupertinoDatePicker во избежание серого экрана
                  GestureDetector(
                    onTap: () {
                      DateTime picked = nextDate;
                      showModalBottomSheet(
                        context: outerContext,
                        backgroundColor: outerContext.ckCard,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => SizedBox(
                          height: 300,
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('Следующий платёж', style: TextStyle(color: outerContext.ckHint, fontSize: 14)),
                                GestureDetector(
                                  onTap: () { Navigator.pop(outerContext); setS(() => nextDate = picked); },
                                  child: Text('Готово', style: TextStyle(color: Coinka.accent, fontSize: 15, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                            ),
                            Expanded(
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.date,
                                initialDateTime: nextDate,
                                minimumDate: DateTime.now(),
                                maximumDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                onDateTimeChanged: (d) => picked = d,
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(color: outerContext.ckS2, borderRadius: BorderRadius.circular(12), border: Border.all(color: outerContext.ckBorder)),
                      child: Row(children: [
                        const Text('📅', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Следующая дата', style: TextStyle(fontSize: 11, color: outerContext.ckHint)),
                          Text(
                            '${nextDate.day.toString().padLeft(2,'0')}.${nextDate.month.toString().padLeft(2,'0')}.${nextDate.year}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: outerContext.ckText),
                          ),
                        ])),
                        Icon(Icons.chevron_right_rounded, color: outerContext.ckHint, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Кнопки
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: outerContext.ckS2, borderRadius: BorderRadius.circular(14), border: Border.all(color: outerContext.ckBorder)),
                          child: Center(child: Text('Отмена', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: outerContext.ckHint))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                          if (nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;
                          Navigator.pop(ctx);
                          _add({
                            'name': nameCtrl.text.trim(),
                            'amount': amount,
                            'period': period,
                            'emoji': emoji,
                            'isIncome': isIncome,
                            'note': noteCtrl.text.trim(),
                            'nextDate': Timestamp.fromDate(nextDate),
                          });
                        },
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(child: Text('Сохранить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeBtn(BuildContext ctx, String label, bool active, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : Colors.transparent, width: 1.5),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? color : ctx.ckHint))),
        ),
      ),
    );
  }

  double get _monthlyTotal {
    double total = 0;
    for (final item in _items) {
      final amount = ((item['amount'] as num?) ?? 0).toDouble();
      final isIncome = item['isIncome'] == true;
      final multiplier = isIncome ? -1.0 : 1.0;
      switch (item['period']) {
        case 'daily': total += amount * 30 * multiplier; break;
        case 'weekly': total += amount * 4.3 * multiplier; break;
        case 'monthly': total += amount * multiplier; break;
        case 'yearly': total += amount / 12 * multiplier; break;
      }
    }
    return total;
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
                Expanded(child: Text('Регулярные', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
              ]),
            ),
            if (!_isLoading && _items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Text('🔄', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('В месяц', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      Text('${_monthlyTotal.abs().round()} ₽${_monthlyTotal < 0 ? ' (доход)' : ''}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ]),
                ),
              ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Coinka.accent))
                : _items.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🔄', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text('Нет регулярных платежей', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText)),
                      const SizedBox(height: 8),
                      Text('Добавь регулярные платежи\nи доходы чтобы отслеживать их', style: TextStyle(fontSize: 14, color: context.ckHint), textAlign: TextAlign.center),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        final isIncome = item['isIncome'] == true;
                        final nextTs = item['nextDate'] as Timestamp?;
                        final nextDate = nextTs?.toDate();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: ctx.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: ctx.ckBorder)),
                          child: Row(children: [
                            Text(item['emoji'] ?? '💳', style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ctx.ckText)),
                              Text(
                                '${_periods[item['period']] ?? 'Ежемесячно'}${nextDate != null ? ' · ${nextDate.day.toString().padLeft(2,'0')}.${nextDate.month.toString().padLeft(2,'0')}' : ''}',
                                style: TextStyle(fontSize: 12, color: ctx.ckHint),
                              ),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(
                                '${isIncome ? '+' : '−'}${((item['amount'] as num?) ?? 0).round()} ₽',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isIncome ? Coinka.green : Coinka.red),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(onTap: () => _delete(item['id']), child: const Text('🗑️', style: TextStyle(fontSize: 14))),
                            ]),
                          ]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Coinka.accent, foregroundColor: Colors.black,
        onPressed: () { HapticFeedback.mediumImpact(); _showAddDialog(); },
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }
}
