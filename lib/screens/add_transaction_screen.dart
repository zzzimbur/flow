import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = false; // false = расход, true = доход
  String _amount = '0';
  String _selectedCategory = '';
  final _commentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedAccount = 'Наличные';

  final Map<String, Map<String, dynamic>> _expenseCategories = {
    'Продукты': {'icon': Icons.shopping_cart, 'color': const Color(0xFF10b981)},
    'Транспорт': {'icon': Icons.directions_car, 'color': const Color(0xFF3b82f6)},
    'Развлечения': {'icon': Icons.movie, 'color': const Color(0xFFf59e0b)},
    'Здоровье': {'icon': Icons.medical_services, 'color': const Color(0xFFef4444)},
    'Образование': {'icon': Icons.school, 'color': const Color(0xFF8b5cf6)},
    'Кафе': {'icon': Icons.restaurant, 'color': const Color(0xFFf97316)},
    'Одежда': {'icon': Icons.checkroom, 'color': const Color(0xFFec4899)},
    'Дом': {'icon': Icons.home, 'color': const Color(0xFF06b6d4)},
  };

  final Map<String, Map<String, dynamic>> _incomeCategories = {
    'Зарплата': {'icon': Icons.account_balance_wallet, 'color': const Color(0xFF10b981)},
    'Фриланс': {'icon': Icons.computer, 'color': const Color(0xFF3b82f6)},
    'Подработка': {'icon': Icons.work_outline, 'color': const Color(0xFF8b5cf6)},
    'Инвестиции': {'icon': Icons.trending_up, 'color': const Color(0xFF06b6d4)},
    'Подарок': {'icon': Icons.card_giftcard, 'color': const Color(0xFFec4899)},
    'Другое': {'icon': Icons.attach_money, 'color': const Color(0xFF64748b)},
  };

  final List<String> _accounts = ['Наличные', 'Карта', 'Сбережения'];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0f172a), const Color(0xFF1e293b)]
                : [const Color(0xFFf8fafc), const Color(0xFFe2e8f0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Хедер
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Новая операция',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveTransaction,
                      child: const Text(
                        'Готово',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8b7ff5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Контент
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Тип операции (Доход/Расход)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(4),
                          color: isDark
                              ? const Color(0xFF1e293b).withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton('Расход', false, isDark),
                              ),
                              Expanded(
                                child: _buildTypeButton('Доход', true, isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Сумма
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              _isIncome ? 'Доход' : 'Расход',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₽$_amount',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _isIncome
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFef4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Калькулятор
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildCalculator(isDark),
                      ),
                      const SizedBox(height: 24),

                      // Категории
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Категория',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCategoryGrid(isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Счёт
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          color: isDark
                              ? const Color(0xFF1e293b).withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Счёт',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButton<String>(
                                value: _selectedAccount,
                                isExpanded: true,
                                underline: const SizedBox(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1e293b) : Colors.white,
                                items: _accounts.map((account) {
                                  return DropdownMenuItem(
                                    value: account,
                                    child: Text(account),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAccount = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Дата
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          color: isDark
                              ? const Color(0xFF1e293b).withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          child: InkWell(
                            onTap: () => _selectDate(context, isDark),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Дата',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Комментарий
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          color: isDark
                              ? const Color(0xFF1e293b).withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          child: TextField(
                            controller: _commentController,
                            maxLines: 3,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1e293b),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Добавить комментарий...',
                              hintStyle: TextStyle(
                                color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isIncome, bool isDark) {
    final isSelected = _isIncome == isIncome;
    return GestureDetector(
      onTap: () => setState(() => _isIncome = isIncome),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isIncome ? const Color(0xFF10b981) : const Color(0xFFef4444))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculator(bool isDark) {
    final buttons = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '⌫',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final button = buttons[index];
        return GestureDetector(
          onTap: () => _onCalculatorTap(button),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                button,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    final categories = _isIncome ? _incomeCategories : _expenseCategories;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.entries.map((entry) {
        final isSelected = _selectedCategory == entry.key;
        final color = entry.value['color'] as Color;
        final icon = entry.value['icon'] as IconData;

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = entry.key),
          child: Container(
            width: (MediaQuery.of(context).size.width - 64) / 3,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : (isDark
                      ? const Color(0xFF1e293b).withOpacity(0.3)
                      : Colors.white.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.white.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _onCalculatorTap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          _amount += value;
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF8b7ff5),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1e293b) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    // TODO: Сохранить транзакцию в Firebase
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}