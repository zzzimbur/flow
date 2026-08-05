import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_snackbar.dart';
import '../theme/coinka.dart';

class EditTransactionScreen extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> transactionData;

  const EditTransactionScreen({
    super.key,
    required this.transactionId,
    required this.transactionData,
    required String initialCategory,
    required double initialAmount,
    required bool initialIsIncome,
    required DateTime initialDate,
    required String initialNote,
  })  : _initialCategory = initialCategory,
        _initialAmount = initialAmount,
        _initialIsIncome = initialIsIncome,
        _initialDate = initialDate,
        _initialNote = initialNote;

  final String _initialCategory;
  final double _initialAmount;
  final bool _initialIsIncome;
  final DateTime _initialDate;
  final String _initialNote;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late bool _isIncome;
  late String _amount;
  late String _selectedCategory;
  final _commentController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedAccount;
  bool _isSaving = false;
  bool _isDeleting = false;

  // Категории расходов (codePoint для сохранения categoryIcon)
  final Map<String, Map<String, dynamic>> _expenseCategories = {
    'Продукты': {'icon': Icons.shopping_cart.codePoint, 'color': const Color(0xFF10b981)},
    'Транспорт': {'icon': Icons.directions_car.codePoint, 'color': const Color(0xFF3b82f6)},
    'Развлечения': {'icon': Icons.movie.codePoint, 'color': const Color(0xFFf59e0b)},
    'Здоровье': {'icon': Icons.medical_services.codePoint, 'color': const Color(0xFFef4444)},
    'Образование': {'icon': Icons.school.codePoint, 'color': const Color(0xFF8b5cf6)},
    'Кафе': {'icon': Icons.restaurant.codePoint, 'color': const Color(0xFFf97316)},
    'Одежда': {'icon': Icons.checkroom.codePoint, 'color': const Color(0xFFec4899)},
    'Дом': {'icon': Icons.home.codePoint, 'color': const Color(0xFF06b6d4)},
  };

  // Категории доходов
  final Map<String, Map<String, dynamic>> _incomeCategories = {
    'Зарплата': {'icon': Icons.account_balance_wallet.codePoint, 'color': const Color(0xFF10b981)},
    'Фриланс': {'icon': Icons.computer.codePoint, 'color': const Color(0xFF3b82f6)},
    'Подработка': {'icon': Icons.work_outline.codePoint, 'color': const Color(0xFF8b5cf6)},
    'Инвестиции': {'icon': Icons.trending_up.codePoint, 'color': const Color(0xFF06b6d4)},
    'Подарок': {'icon': Icons.card_giftcard.codePoint, 'color': const Color(0xFFec4899)},
    'Другое': {'icon': Icons.attach_money.codePoint, 'color': const Color(0xFF64748b)},
  };

  final List<String> _accounts = ['Наличные', 'Карта', 'Сбережения'];

  @override
  void initState() {
    super.initState();
    _isIncome = widget._initialIsIncome;
    _amount = widget._initialAmount.abs().toStringAsFixed(0);
    _selectedCategory = widget._initialCategory.isEmpty ? 'Другое' : widget._initialCategory;
    _selectedDate = widget._initialDate;
    _commentController.text = widget._initialNote;
    final acc = widget.transactionData['account']?.toString();
    _selectedAccount = (acc != null && _accounts.contains(acc)) ? acc : 'Наличные';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onCalculatorTap(String value) {
    setState(() {
      if (value == '⌫') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (value == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        _amount = _amount == '0' ? value : _amount + value;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final picked = await IOSDatePicker.show(context: context, initialDate: _selectedDate, isDark: isDark);
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveTransaction() async {
    if (_selectedCategory.isEmpty) {
      AppSnackbar.error(context, 'Выберите категорию');
      return;
    }
    String clean = _amount.endsWith('.') ? _amount.substring(0, _amount.length - 1) : _amount;
    final amount = double.tryParse(clean);
    if (amount == null || amount <= 0) {
      AppSnackbar.error(context, 'Введите корректную сумму');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) throw Exception('Пользователь не авторизован');

      final categories = _isIncome ? _incomeCategories : _expenseCategories;
      final categoryData = categories[_selectedCategory];
      final catColor = categoryData != null
          ? (categoryData['color'] as Color).value
          : (widget.transactionData['categoryColor'] ?? 0xFF64748b);
      final catIcon = categoryData != null
          ? categoryData['icon'] as int
          : (widget.transactionData['categoryIcon'] ?? Icons.attach_money.codePoint);

      await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('transactions').doc(widget.transactionId)
          .update({
        'amount': _isIncome ? amount : -amount,
        'category': _selectedCategory,
        'categoryColor': catColor,
        'categoryIcon': catIcon,
        'account': _selectedAccount,
        'date': Timestamp.fromDate(DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          _selectedDate.hour, _selectedDate.minute,
        )),
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        'isIncome': _isIncome,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      HapticFeedback.heavyImpact();
      if (mounted) {
        AppSnackbar.success(context, '✅ Операция обновлена!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) AppSnackbar.error(context, 'Ошибка: ${e.toString()}');
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
              Text('Удалить операцию?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ctx.ckText)),
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
    if (ok == true) _deleteTransaction();
  }

  Future<void> _deleteTransaction() async {
    setState(() => _isDeleting = true);
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) throw Exception('Пользователь не авторизован');
      await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('transactions').doc(widget.transactionId)
          .delete();
      HapticFeedback.heavyImpact();
      if (mounted) {
        AppSnackbar.success(context, '🗑️ Операция удалена');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) AppSnackbar.error(context, 'Ошибка: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsProvider>().currencySymbol;
    final isDark = context.isDark;
    final amountColor = _isIncome ? Coinka.green : Coinka.red;

    return Scaffold(
      backgroundColor: context.ckBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.ckHint),
                    onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  ),
                  Expanded(
                    child: Text('Редактировать', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText)),
                  ),
                  if (_isDeleting)
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Coinka.red, strokeWidth: 2)))
                  else
                    GestureDetector(
                      onTap: _confirmDelete,
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('🗑️', style: TextStyle(fontSize: 20))),
                    ),
                  const SizedBox(width: 4),
                  if (_isSaving)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Coinka.accent, strokeWidth: 2))
                  else
                    GestureDetector(
                      onTap: _saveTransaction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Готово', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Доход / Расход toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.ckCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.ckBorder),
                      ),
                      child: Row(children: [
                        Expanded(child: _buildTypeButton('Расход', false)),
                        Expanded(child: _buildTypeButton('Доход', true)),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Сумма
                    Center(
                      child: Column(children: [
                        Text(_isIncome ? 'Доход' : 'Расход', style: TextStyle(fontSize: 13, color: context.ckHint)),
                        const SizedBox(height: 6),
                        Text('$_amount $currency', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: amountColor, letterSpacing: -1)),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    _buildCalculator(),
                    const SizedBox(height: 20),

                    Text('КАТЕГОРИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    _buildCategoryGrid(),
                    const SizedBox(height: 20),

                    Text('СЧЁТ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                      child: DropdownButton<String>(
                        value: _selectedAccount,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: context.ckCard,
                        style: TextStyle(fontSize: 15, color: context.ckText, fontWeight: FontWeight.w600),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.ckHint),
                        items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                        onChanged: (v) => setState(() => _selectedAccount = v!),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Дата
                    GestureDetector(
                      onTap: () => _selectDate(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Дата', style: TextStyle(fontSize: 12, color: context.ckHint)),
                                const SizedBox(height: 4),
                                Text('${_selectedDate.day} ${coinkaMonths[_selectedDate.month - 1].toLowerCase()} ${_selectedDate.year}',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.ckText)),
                              ],
                            ),
                            const Icon(Icons.calendar_today_rounded, color: Coinka.accent, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Комментарий
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      style: TextStyle(color: context.ckText, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Комментарий...',
                        hintStyle: TextStyle(color: context.ckHint, fontSize: 15),
                        filled: true, fillColor: context.ckCard,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
                      ),
                    ),
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

  Widget _buildTypeButton(String label, bool isIncome) {
    final isSelected = _isIncome == isIncome;
    final c = isIncome ? Coinka.green : Coinka.red;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() { _isIncome = isIncome; if (!(_isIncome ? _incomeCategories : _expenseCategories).containsKey(_selectedCategory)) _selectedCategory = (_isIncome ? _incomeCategories : _expenseCategories).keys.first; }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? c : Colors.transparent, width: 1.5),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? c : context.ckHint)),
      ),
    );
  }

  Widget _buildCalculator() {
    const buttons = ['1','2','3','4','5','6','7','8','9','.','0','⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final btn = buttons[index];
        final isDelete = btn == '⌫';
        return GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); _onCalculatorTap(btn); },
          child: Container(
            decoration: BoxDecoration(
              color: isDelete ? context.ckS2 : context.ckCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.ckBorder),
            ),
            child: Center(child: Text(btn, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: isDelete ? Coinka.red : context.ckText))),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    final w = (MediaQuery.of(context).size.width - 32 - 24) / 4;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.entries.map((entry) {
        final isSelected = _selectedCategory == entry.key;
        final emoji = Coinka.emojiFor(entry.key, isIncome: _isIncome);
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = entry.key); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: w,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? Coinka.accentDim : context.ckCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? Coinka.accent : context.ckBorder, width: isSelected ? 1.5 : 1),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(entry.key,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Coinka.accent : context.ckHint),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
