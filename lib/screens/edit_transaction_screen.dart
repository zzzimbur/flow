import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../widgets/enhanced_glass_card.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_snackbar.dart';
import '../providers/subscription_provider.dart';

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
  });

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

  // Категории расходов
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

  // Категории доходов
  final Map<String, Map<String, dynamic>> _incomeCategories = {
    'Зарплата': {'icon': Icons.account_balance_wallet, 'color': const Color(0xFF10b981)},
    'Фриланс': {'icon': Icons.computer, 'color': const Color(0xFF3b82f6)},
    'Подработка': {'icon': Icons.work_outline, 'color': const Color(0xFF8b5cf6)},
    'Инвестиции': {'icon': Icons.trending_up, 'color': const Color(0xFF06b6d4)},
    'Подарок': {'icon': Icons.card_giftcard, 'color': const Color(0xFFec4899)},
    'Другое': {'icon': Icons.attach_money, 'color': const Color(0xFF64748b)},
  };

  final List<String> _accounts = ['Наличные', 'Карта', 'Сбережения'];

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    
    // Безопасная инициализация с проверкой на null
    _amountController = TextEditingController(
      text: widget.transactionData['amount']?.toString() ?? '0'
    );
    _descriptionController = TextEditingController(
      text: widget.transactionData['description']?.toString() ?? ''
    );
    
    // Инициализация даты
    if (widget.transactionData['date'] != null) {
      try {
        _selectedDate = (widget.transactionData['date'] as Timestamp).toDate();
      } catch (e) {
        print('Ошибка парсинга даты: $e');
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }
    
    // Остальные поля
    _selectedCategory = widget.transactionData['category']?.toString() ?? 'Другое';
    _isIncome = widget.transactionData['isIncome'] ?? false;
    _selectedAccount = widget.transactionData['account']?.toString() ?? 'Наличные';
    
    // Инициализация суммы
    final amount = (widget.transactionData['amount'] ?? 0.0).toDouble();
    _amount = amount.abs().toStringAsFixed(0);
    
    // Комментарий
    _commentController.text = widget.transactionData['comment']?.toString() ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: AnimatedBackground(
        isDark: isDark,
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
                    // Используем Expanded для текста
                    Expanded(
                      child: Text(
                        'Редактировать',
                        style: TextStyle(
                          fontSize: 18, // УМЕНЬШЕНО с 20
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Кнопка сохранения
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b7ff5)),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _saveTransaction,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
                        child: EnhancedGlassCard(
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
                        child: EnhancedGlassCard(
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
                        child: EnhancedGlassCard(
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
                        child: EnhancedGlassCard(
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
                      const SizedBox(height: 2),
                      // Кнопка удаления
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showDeleteConfirmation();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFef4444).withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFef4444).withOpacity(0.15),
                                      const Color(0xFFdc2626).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFef4444).withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFef4444).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFef4444),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Удалить операцию',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFef4444),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

    Future<void> _showDeleteConfirmation() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Иконка
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFef4444).withOpacity(0.2),
                              const Color(0xFFdc2626).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFef4444),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Заголовок
                      Text(
                        'Удалить операцию?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Описание
                      Text(
                        'Это действие нельзя отменить',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark 
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Кнопки
                      Row(
                        children: [
                          // Отмена
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'Отмена',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Удалить
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context, true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFef4444),
                                      Color(0xFFdc2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFef4444).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Удалить',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    if (result == true) {
      await _deleteTransaction();
    }
  }

  Widget _buildTypeButton(String label, bool isIncome, bool isDark) {
    final isSelected = _isIncome == isIncome;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isIncome = isIncome;
          
          // Проверяем, существует ли текущая категория в новом типе
          final categories = _isIncome ? _incomeCategories : _expenseCategories;
          if (!categories.containsKey(_selectedCategory)) {
            // Если категории нет, сбрасываем выбор
            _selectedCategory = '';
          }
        });
      },
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
    final picked = await IOSDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      isDark: isDark,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    // Проверка подписки
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    if (!subscriptionProvider.canCreateTransactions) {
      AppSnackbar.error(context, 'Создание транзакций доступно только с Premium подпиской');
      return;
    }
    
    // Валидация категории
    if (_selectedCategory.isEmpty) {
      AppSnackbar.error(context, 'Выберите категорию');
      return;
    }

    // Проверка, что категория существует в текущем типе
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    if (!categories.containsKey(_selectedCategory)) {
      AppSnackbar.error(context, 'Категория не найдена для данного типа операции');
      return;
    }

    if (_amount == '0' || _amount.isEmpty || _amount == '.') {
      AppSnackbar.error(context, 'Введите сумму');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      String cleanAmount = _amount;
      if (cleanAmount.endsWith('.')) {
        cleanAmount = cleanAmount.substring(0, cleanAmount.length - 1);
      }
      
      final amount = double.tryParse(cleanAmount);
      if (amount == null || amount <= 0) {
        throw Exception('Некорректная сумма');
      }

      final categories = _isIncome ? _incomeCategories : _expenseCategories;
      final categoryData = categories[_selectedCategory];
      
      if (categoryData == null) {
        throw Exception('Категория не найдена');
      }
      
      final transactionData = {
        'amount': _isIncome ? amount : -amount,
        'category': _selectedCategory,
        'categoryColor': (categoryData['color'] as Color).value,
        'categoryIcon': (categoryData['icon'] as IconData).codePoint,
        'account': _selectedAccount,
        'date': Timestamp.fromDate(DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        )),
        'comment': _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        'isIncome': _isIncome,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(widget.transactionId)
          .update(transactionData);

      if (mounted) {
        AppSnackbar.success(context, '✅ Операция обновлена!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        AppSnackbar.error(context, 'Ошибка: ${e.toString()}');
      }
    }
  }

  Future<void> _confirmDelete() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1e293b).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          title: Text(
            'Удалить операцию?',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1e293b),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Это действие нельзя отменить',
            style: TextStyle(
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Удалить',
                style: TextStyle(color: Color(0xFFef4444)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _deleteTransaction();
    }
  }

  Future<void> _deleteTransaction() async {
    setState(() => _isDeleting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(widget.transactionId)
          .delete();

      if (mounted) {
        AppSnackbar.success(context, '✅ Операция удалена!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      
      if (mounted) {
        AppSnackbar.error(context, 'Ошибка: ${e.toString()}');
      }
    }
  }
}
