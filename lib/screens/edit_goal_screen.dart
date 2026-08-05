import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import '../theme/coinka.dart';

class EditGoalScreen extends StatefulWidget {
  final GoalModel goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  late final TextEditingController _percentCtrl;
  late String _icon;
  Color _iconColor = Coinka.accent2;
  bool _isLoading = false;
  bool _isDeleting = false;

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
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.goal.name);
    _targetCtrl = TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(0));
    _currentCtrl = TextEditingController(text: widget.goal.currentAmount.toStringAsFixed(0));
    _percentCtrl = TextEditingController(text: widget.goal.percentage.toStringAsFixed(0));
    _icon = widget.goal.icon.isEmpty ? '🎯' : widget.goal.icon;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    if (target == null || target <= 0) return;
    final current = double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
    final percent = double.tryParse(_percentCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() => _isLoading = true);
    final updated = widget.goal.copyWith(
      name: _nameCtrl.text.trim(),
      targetAmount: target,
      currentAmount: current,
      icon: _icon,
      percentage: percent,
      updatedAt: DateTime.now(),
    );
    final success = await context.read<GoalProvider>().updateGoal(updated);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.ckCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗑️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Удалить цель?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ctx.ckText)),
              const SizedBox(height: 8),
              Text('Это действие нельзя отменить', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ctx.ckHint)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: ctx.ckS2, borderRadius: BorderRadius.circular(14), border: Border.all(color: ctx.ckBorder)),
                    child: Center(child: Text('Отмена', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ctx.ckText))),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Coinka.red, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('Удалить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    if (ok == true) _deleteGoal();
  }

  Future<void> _deleteGoal() async {
    setState(() => _isDeleting = true);
    final success = await context.read<GoalProvider>().deleteGoal(widget.goal.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (success) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context, true);
    }
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ckCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 3, decoration: BoxDecoration(color: context.ckMuted, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Выберите иконку', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.ckText)),
              const SizedBox(height: 12),
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
                      onTap: () { setSheet(() {}); setState(() => _iconColor = c); },
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
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool isNum = false, String? suffix}) {
    return TextField(
      controller: c,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))] : null,
      style: TextStyle(color: context.ckText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.ckHint),
        suffixText: suffix,
        suffixStyle: TextStyle(color: context.ckHint, fontWeight: FontWeight.w600),
        filled: true, fillColor: context.ckS2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
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
                IconButton(icon: Icon(Icons.close_rounded, color: context.ckHint), onPressed: () => Navigator.pop(context)),
                Expanded(child: Text('Редактировать цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText))),
                if (_isDeleting)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Coinka.red, strokeWidth: 2)))
                else
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('🗑️', style: TextStyle(fontSize: 20))),
                  ),
                const SizedBox(width: 4),
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
                    // Иконка превью
                    Center(
                      child: GestureDetector(
                        onTap: _showIconPicker,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: _iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _iconColor.withOpacity(0.4), width: 1.5),
                          ),
                          child: Center(child: Text(_icon, style: const TextStyle(fontSize: 36))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(child: GestureDetector(
                      onTap: _showIconPicker,
                      child: Text('Изменить иконку', style: TextStyle(fontSize: 12, color: Coinka.accent, fontWeight: FontWeight.w600)),
                    )),
                    const SizedBox(height: 20),

                    Text('НАЗВАНИЕ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    _field(_nameCtrl, 'Название цели'),
                    const SizedBox(height: 16),

                    Text('ЦЕЛЕВАЯ СУММА', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    _field(_targetCtrl, 'Сколько накопить', isNum: true, suffix: '₽'),
                    const SizedBox(height: 16),

                    Text('УЖЕ НАКОПЛЕНО', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    _field(_currentCtrl, 'Текущая сумма', isNum: true, suffix: '₽'),
                    const SizedBox(height: 16),

                    Text('ДОЛЯ ОТ ДОХОДОВ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    _field(_percentCtrl, 'Процент дохода в цель', isNum: true, suffix: '%'),
                    const SizedBox(height: 32),
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
