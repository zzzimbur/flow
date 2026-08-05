import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/coinka.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _icon = '🎯';
  Color _iconColor = Coinka.accent2;
  DateTime? _deadline;
  bool _isLoading = false;

  static const _icons = [
    '🎯', '💰', '🏠', '🚗', '✈️', '📱', '💻', '🎓',
    '💍', '🎉', '🏖️', '🎸', '📷', '⚽', '🎮', '👔',
    '🍕', '☕', '🎨', '📚', '💪', '🌟', '🏋️', '🛒',
  ];

  static const _colors = [
    Color(0xFF7B6FF0), Color(0xFF00E5B3), Color(0xFFFF4D6D),
    Color(0xFFf59e0b), Color(0xFF3b82f6), Color(0xFF8b5cf6),
    Color(0xFF10b981), Color(0xFFec4899),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) { setState(() => _isLoading = false); return; }

    final goal = GoalModel(
      id: '',
      name: _nameCtrl.text.trim(),
      targetAmount: amount,
      currentAmount: 0,
      icon: _icon,
      percentage: 10,
      createdAt: DateTime.now(),
    );

    final success = await context.read<GoalProvider>().addGoal(goal);
    setState(() => _isLoading = false);
    if (success && mounted) Navigator.pop(context, true);
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ckCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3, decoration: BoxDecoration(color: context.ckMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Выберите иконку', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.ckText)),
            const SizedBox(height: 12),
            // Цвет иконки
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _colors[i];
                  final sel = _iconColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _iconColor = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
                        boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)] : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: _icons.length,
              itemBuilder: (_, i) {
                final ic = _icons[i];
                final sel = _icon == ic;
                return GestureDetector(
                  onTap: () { setState(() => _icon = ic); Navigator.pop(context); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: sel ? _iconColor.withOpacity(0.15) : context.ckS2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? _iconColor : context.ckBorder, width: sel ? 1.5 : 1),
                    ),
                    child: Center(child: Text(ic, style: const TextStyle(fontSize: 26))),
                  ),
                );
              },
            ),
          ],
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.ckHint),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(child: Text('Новая цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText))),
                _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Coinka.accent, strokeWidth: 2))
                  : GestureDetector(
                      onTap: () { HapticFeedback.mediumImpact(); _save(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Сохранить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название цели
                    TextField(
                      controller: _nameCtrl,
                      style: TextStyle(color: context.ckText, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Название цели',
                        hintStyle: TextStyle(color: context.ckHint),
                        filled: true, fillColor: context.ckS2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Сумма + валюта
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                          style: TextStyle(color: context.ckText, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Целевая сумма',
                            hintStyle: TextStyle(color: context.ckHint),
                            filled: true, fillColor: context.ckS2,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(color: context.ckS2, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                        child: Text('RUB', style: TextStyle(color: context.ckHint, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Дата (необязательно)
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          locale: const Locale('ru'),
                        );
                        if (d != null) setState(() => _deadline = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: context.ckS2, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                        child: Row(children: [
                          Expanded(child: Text(
                            _deadline != null
                              ? '${_deadline!.day.toString().padLeft(2,'0')}.${_deadline!.month.toString().padLeft(2,'0')}.${_deadline!.year}'
                              : 'Дата (необязательно)',
                            style: TextStyle(fontSize: 15, color: _deadline != null ? context.ckText : context.ckHint),
                          )),
                          Icon(Icons.calendar_today_rounded, size: 16, color: context.ckHint),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Иконка
                    Text('Иконка', style: TextStyle(fontSize: 12, color: context.ckHint, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showIconPicker,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _iconColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _iconColor.withOpacity(0.3)),
                            ),
                            child: Center(child: Text(_icon, style: const TextStyle(fontSize: 28))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Кнопки
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                          onTap: () { HapticFeedback.mediumImpact(); _save(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(child: Text('Сохранить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
