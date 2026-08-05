import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../theme/coinka.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Map<String, dynamic>> _debts = [];
  bool _isLoading = true;

  // Неоплаченные сверху, оплаченные внизу; внутри — порядок загрузки.
  List<Map<String, dynamic>> get _sortedDebts {
    final list = [..._debts];
    list.sort((a, b) => (a['isPaid'] == true ? 1 : 0) - (b['isPaid'] == true ? 1 : 0));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) { setState(() => _isLoading = false); return; }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('debts')
          .orderBy('createdAt', descending: true).get();
      setState(() {
        _debts = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDebt(Map<String, dynamic> data) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('debts')
        .add({...data, 'isPaid': false, 'createdAt': FieldValue.serverTimestamp()});
    _loadDebts();
  }

  Future<void> _togglePaid(String id, bool current) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('debts').doc(id)
        .update({'isPaid': !current});
    _loadDebts();
  }

  Future<void> _deleteDebt(String id) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('debts').doc(id).delete();
    _loadDebts();
  }

  void _showAddDialog([bool iOweInitial = true]) {
    bool iOwe = iOweInitial;
    bool isMortgage = false;
    DateTime? dueDate;
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final termCtrl = TextEditingController();
    final bankPaymentCtrl = TextEditingController();
    final outerContext = context;

    showModalBottomSheet(
      context: outerContext,
      backgroundColor: outerContext.ckCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Widget field(TextEditingController c, String hint, {bool isNum = false}) {
            return TextField(
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
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(child: Container(width: 36, height: 3, decoration: BoxDecoration(color: outerContext.ckMuted, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),

                  // Тип: Я должен / Мне должны — скрывается при кредите (банк не должен тебе)
                  if (!isMortgage) ...[
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: outerContext.ckS2, borderRadius: BorderRadius.circular(14)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _typeBtn(ctx, 'Я должен', iOwe, Coinka.red, () => setS(() => iOwe = true)),
                        _typeBtn(ctx, 'Мне должны', !iOwe, Coinka.green, () => setS(() => iOwe = false)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  field(nameCtrl, 'Название'),
                  const SizedBox(height: 10),

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

                  // Кредит / Ипотека
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: outerContext.ckS2, borderRadius: BorderRadius.circular(12), border: Border.all(color: outerContext.ckBorder)),
                    child: Row(children: [
                      Expanded(child: Text('Кредит / Ипотека', style: TextStyle(fontSize: 15, color: outerContext.ckText))),
                      CupertinoSwitch(
                        value: isMortgage,
                        activeColor: Coinka.accent2,
                        onChanged: (v) => setS(() {
                          isMortgage = v;
                          // Банк не может быть должен пользователю
                          if (v) iOwe = true;
                        }),
                      ),
                    ]),
                  ),
                  if (isMortgage) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: field(rateCtrl, 'Годовая ставка (%)', isNum: true)),
                      const SizedBox(width: 10),
                      Expanded(child: field(termCtrl, 'Срок (месяцев)', isNum: true)),
                    ]),
                    const SizedBox(height: 10),
                    field(bankPaymentCtrl, 'Платёж из банка (необязательно)', isNum: true),
                  ],
                  const SizedBox(height: 10),

                  field(noteCtrl, 'Заметка (необязательно)'),
                  const SizedBox(height: 10),

                  // Срок — CupertinoDatePicker в showModalBottomSheet во избежание серого экрана
                  GestureDetector(
                    onTap: () {
                      DateTime picked = dueDate ?? DateTime.now().add(const Duration(days: 30));
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
                                GestureDetector(
                                  onTap: () { Navigator.pop(outerContext); setS(() => dueDate = null); },
                                  child: Text('Сбросить', style: TextStyle(color: outerContext.ckHint, fontSize: 15)),
                                ),
                                GestureDetector(
                                  onTap: () { Navigator.pop(outerContext); setS(() => dueDate = picked); },
                                  child: Text('Готово', style: TextStyle(color: Coinka.accent, fontSize: 15, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                            ),
                            Expanded(
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.date,
                                initialDateTime: picked,
                                minimumDate: DateTime.now(),
                                maximumDate: DateTime.now().add(const Duration(days: 365 * 10)),
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
                        Expanded(child: Text(
                          dueDate != null
                            ? 'Срок: ${dueDate!.day.toString().padLeft(2,'0')}.${dueDate!.month.toString().padLeft(2,'0')}.${dueDate!.year}'
                            : 'Срок (необязательно)',
                          style: TextStyle(fontSize: 15, color: dueDate != null ? outerContext.ckText : outerContext.ckHint),
                        )),
                        Icon(Icons.calendar_today_rounded, size: 16, color: outerContext.ckHint),
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
                          final name = nameCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                          if (name.isEmpty || amount == null || amount <= 0) return;
                          Navigator.pop(ctx);
                          _addDebt({
                            'name': name,
                            'amount': amount,
                            'iOwe': iOwe,
                            'note': noteCtrl.text.trim(),
                            'isMortgage': isMortgage,
                            if (isMortgage) ...{
                              'rate': double.tryParse(rateCtrl.text) ?? 0,
                              'term': int.tryParse(termCtrl.text) ?? 0,
                              'bankPayment': double.tryParse(bankPaymentCtrl.text) ?? 0,
                            },
                            if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          child: const Center(child: Text('Сохранить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
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
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : Colors.transparent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? color : ctx.ckHint)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iOweDebts = _debts.where((d) => d['iOwe'] == true).toList();
    final oweMeDebts = _debts.where((d) => d['iOwe'] == false).toList();
    final totalOwe = iOweDebts.where((d) => d['isPaid'] != true).fold<double>(0, (s, d) => s + ((d['amount'] as num?) ?? 0));
    final totalOwed = oweMeDebts.where((d) => d['isPaid'] != true).fold<double>(0, (s, d) => s + ((d['amount'] as num?) ?? 0));

    return Scaffold(
      backgroundColor: context.ckBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.ckHint, size: 20), onPressed: () => Navigator.pop(context)),
                Expanded(child: Text('Долги', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
              ]),
            ),
            // Итоги
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                Expanded(child: _statCard(context, '💳 Я должен', totalOwe, Coinka.red)),
                const SizedBox(width: 10),
                Expanded(child: _statCard(context, '💵 Мне должны', totalOwed, Coinka.green)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Coinka.accent))
                : _buildList(context, _sortedDebts),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Coinka.red,
        foregroundColor: Colors.white,
        onPressed: () { HapticFeedback.mediumImpact(); _showAddDialog(true); },
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.ckHint)),
        const SizedBox(height: 4),
        Text('${amount.round()} ₽', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🤝', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Долгов нет', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.ckText)),
        const SizedBox(height: 4),
        Text('Добавь, кто кому должен', style: TextStyle(fontSize: 13, color: context.ckHint)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final d = items[i];
        final iOwe = d['iOwe'] == true;
        final isPaid = d['isPaid'] == true;
        final isMortgage = d['isMortgage'] == true;
        final dueTs = d['dueDate'] as Timestamp?;
        final dueDate = dueTs?.toDate();
        final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && !isPaid;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPaid ? ctx.ckS2 : ctx.ckCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isOverdue ? Coinka.red.withOpacity(0.5) : (isPaid ? ctx.ckBorder : (iOwe ? Coinka.red.withOpacity(0.2) : Coinka.green.withOpacity(0.2)))),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); _togglePaid(d['id'], isPaid); },
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isPaid ? Coinka.accentDim : ctx.ckS2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isPaid ? Coinka.accent : ctx.ckBorder),
                ),
                child: isPaid ? const Icon(Icons.check_rounded, size: 16, color: Coinka.accent) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (isMortgage) const Padding(padding: EdgeInsets.only(right: 4), child: Text('🏠', style: TextStyle(fontSize: 13))),
                Text(d['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isPaid ? ctx.ckHint : ctx.ckText, decoration: isPaid ? TextDecoration.lineThrough : null)),
              ]),
              if ((d['note'] ?? '').toString().isNotEmpty)
                Text(d['note'], style: TextStyle(fontSize: 12, color: ctx.ckHint)),
              if (dueDate != null)
                Text(
                  'Срок: ${dueDate.day.toString().padLeft(2,'0')}.${dueDate.month.toString().padLeft(2,'0')}.${dueDate.year}',
                  style: TextStyle(fontSize: 11, color: isOverdue ? Coinka.red : ctx.ckHint),
                ),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${((d['amount'] as num?) ?? 0).round()} ₽',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isPaid ? ctx.ckHint : (iOwe ? Coinka.red : Coinka.green))),
              const SizedBox(height: 4),
              GestureDetector(onTap: () => _deleteDebt(d['id']), child: const Text('🗑️', style: TextStyle(fontSize: 14))),
            ]),
          ]),
        );
      },
    );
  }
}
