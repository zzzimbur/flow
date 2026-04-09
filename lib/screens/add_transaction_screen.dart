import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_glass_card.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../utils/app_snackbar.dart';
import '../providers/goal_provider.dart';
import '../providers/goals_provider.dart';
import '../services/template_service.dart';
import '../models/template_model.dart';
import '../providers/subscription_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

final Map<int, IconData> _materialIconMap = {
  Icons.shopping_cart.codePoint: Icons.shopping_cart,
  Icons.restaurant.codePoint: Icons.restaurant,
  Icons.directions_car.codePoint: Icons.directions_car,
  Icons.movie.codePoint: Icons.movie,
  Icons.medical_services.codePoint: Icons.medical_services,
  Icons.school.codePoint: Icons.school,
  Icons.checkroom.codePoint: Icons.checkroom,
  Icons.home.codePoint: Icons.home,
  Icons.account_balance_wallet.codePoint: Icons.account_balance_wallet,
  Icons.computer.codePoint: Icons.computer,
  Icons.work_outline.codePoint: Icons.work_outline,
  Icons.trending_up.codePoint: Icons.trending_up,
  Icons.card_giftcard.codePoint: Icons.card_giftcard,
  Icons.attach_money.codePoint: Icons.attach_money,
};


class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = false;
  String _amount = '0';
  String _selectedCategory = '';
  final _commentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedAccount = 'Наличные';
  bool _isSaving = false;

  // Для вкладки "Вклад в цель"
  String? _selectedGoalId;
  bool _contributeToCertainGoal = false;


  // Категории расходов
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomCategories();
    });
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Новая операция',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                    ),
                    // кнопка шаблона
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_add_outlined,
                        color: Color(0xFF8b7ff5),
                      ),
                      onPressed: _saveAsTemplate,
                      tooltip: 'Сохранить как шаблон',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_outlined,
                        color: Color(0xFF8b7ff5),
                      ),
                      onPressed: _loadFromTemplate,
                      tooltip: 'Загрузить из шаблона',
                    ),
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

                      // Категории с кнопкой добавления
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Категория',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  ),
                                ),
                                // КНОПКА "НОВАЯ КАТЕГОРИЯ"
                                TextButton.icon(
                                  onPressed: () => _showAddCategoryDialog(isDark),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: Color(0xFF8b7ff5),
                                  ),
                                  label: const Text(
                                    'Новая',
                                    style: TextStyle(
                                      color: Color(0xFF8b7ff5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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
                      // Вклад в цель (только для доходов)
                      if (_isIncome) ...[
                        const SizedBox(height: 16),
                        Padding(
                          
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Consumer<GoalProvider>(
                            builder: (context, goalProvider, _) {
                              final goals = goalProvider.goals;
                              
                              if (goals.isEmpty) {
                                return const SizedBox();
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Переключатель "Внести в конкретную цель"
                                  EnhancedGlassCard(
                                    padding: const EdgeInsets.all(16),
                                    color: isDark
                                        ? const Color(0xFF1e293b).withOpacity(0.5)
                                        : Colors.white.withOpacity(0.7),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.flag_outlined,
                                          color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Внести в конкретную цель',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Помимо автоматического распределения',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: _contributeToCertainGoal,
                                          onChanged: (value) {
                                            setState(() {
                                              _contributeToCertainGoal = value;
                                              if (!value) {
                                                _selectedGoalId = null;
                                              }
                                            });
                                          },
                                          activeColor: const Color(0xFF8b7ff5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Выбор цели (если переключатель включен)
                                  if (_contributeToCertainGoal) ...[
                                    const SizedBox(height: 12),
                                    EnhancedGlassCard(
                                      padding: const EdgeInsets.all(16),
                                      color: isDark
                                          ? const Color(0xFF1e293b).withOpacity(0.5)
                                          : Colors.white.withOpacity(0.7),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Выберите цель',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...goals.map((goal) {
                                            final isSelected = _selectedGoalId == goal.id;
                                            final progress = goal.progress;
                                            final isCompleted = goal.isCompleted;
                                            
                                            return GestureDetector(
                                              onTap: isCompleted ? null : () {
                                                setState(() {
                                                  _selectedGoalId = isSelected ? null : goal.id;
                                                });
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF8b7ff5).withOpacity(0.15)
                                                      : (isDark 
                                                          ? const Color(0xFF0f172a).withOpacity(0.5)
                                                          : Colors.white.withOpacity(0.5)),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? const Color(0xFF8b7ff5)
                                                        : (isCompleted
                                                            ? const Color(0xFF059669)
                                                            : Colors.transparent),
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Иконка/Эмодзи
                                                    Text(
                                                      goal.icon,
                                                      style: const TextStyle(fontSize: 24),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    
                                                    // Информация о цели
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  goal.name,
                                                                  style: TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                                                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              if (isCompleted)
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFF059669).withOpacity(0.2),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                  ),
                                                                  child: Text(
                                                                    'Достигнута',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: isDark ? const Color(0xFF34d399) : const Color(0xFF047857),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                '₽${goal.currentAmount.toStringAsFixed(0)}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                                                ),
                                                              ),
                                                              Text(
                                                                ' / ₽${goal.targetAmount.toStringAsFixed(0)}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                '${goal.progressPercentage.toStringAsFixed(0)}%',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: isCompleted
                                                                      ? const Color(0xFF059669)
                                                                      : const Color(0xFF8b7ff5),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 6),
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(4),
                                                            child: LinearProgressIndicator(
                                                              value: progress,
                                                              backgroundColor: isDark 
                                                                  ? const Color(0xFF334155)
                                                                  : const Color(0xFFe2e8f0),
                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                isCompleted 
                                                                    ? const Color(0xFF059669)
                                                                    : const Color(0xFF8b7ff5),
                                                              ),
                                                              minHeight: 4,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    // Чекбокс
                                                    if (isSelected && !isCompleted)
                                                      const Icon(
                                                        Icons.check_circle,
                                                        color: Color(0xFF8b7ff5),
                                                        size: 24,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    
                                    // Поле для ввода суммы вклада
                                    if (_selectedGoalId != null) ...[
                                      const SizedBox(height: 12),
                                      EnhancedGlassCard(
                                        padding: const EdgeInsets.all(16),
                                        color: isDark
                                            ? const Color(0xFF1e293b).withOpacity(0.5)
                                            : Colors.white.withOpacity(0.7),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 16,
                                                  color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Эта сумма будет добавлена к цели дополнительно к автоматическому распределению',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ],
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

  Future<String?> _showTemplateNameDialog() async {
      final controller = TextEditingController();
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final isDark = settings.isDarkMode;

      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Название шаблона',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
            decoration: InputDecoration(
              hintText: 'Например: Дневная смена',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8b7ff5), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b7ff5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Создать'),
            ),
          ],
        ),
      );
    }

  Future<void> _saveAsTemplate() async {
    // проверка подписки
    // final subscriptionProvider = context.read<SubscriptionProvider>();
    // if (!subscriptionProvider.canUseTemplates) {
    //   subscriptionProvider.showPremiumDialog(context, 'templates');
    //   return;
    // }    

    if (_selectedCategory.isEmpty) {
      AppSnackbar.error(context, 'Выберите категорию');
      return;
    }

    HapticFeedback.mediumImpact();

    final templateName = await _showTemplateNameDialog();
    
    if (templateName == null || templateName.trim().isEmpty) {
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      final categories = _isIncome ? _incomeCategories : _expenseCategories;
      final categoryData = categories[_selectedCategory];

      final transactionData = {
        'category': _selectedCategory,
        'categoryColor': (categoryData?['color'] as Color?)?.value,
        'categoryIcon': categoryData?['icon'] as int?,
        'account': _selectedAccount,
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        'isIncome': _isIncome,
      };

      final templateService = TemplateService();
      final templateId = await templateService.createTemplateFromTransaction(
        userId: userId,
        name: templateName.trim(),
        transactionData: transactionData,
      );

      if (templateId != null) {
        HapticFeedback.heavyImpact();
        AppSnackbar.success(context, '✅ Шаблон "${templateName}" создан!');
      } else {
        AppSnackbar.error(context, 'Ошибка создания шаблона');
      }
    } catch (e) {
      print('Ошибка сохранения шаблона: $e');
      AppSnackbar.error(context, 'Ошибка: ${e.toString()}');
    }
  }

  Future<void> _loadFromTemplate() async {
    HapticFeedback.mediumImpact();
    
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId.isEmpty) {
      AppSnackbar.error(context, 'Пользователь не авторизован');
      return;
    }
    
    final templateService = TemplateService();
    final templates = await templateService.getTemplates(userId, type: TemplateType.transaction);
    
    if (templates.isEmpty) {
      AppSnackbar.error(context, 'Нет сохраненных шаблонов');
      return;
    }
    
    final selectedTemplate = await _showTemplatePickerDialog(templates);
    
    if (selectedTemplate != null) {
      setState(() {
        final data = selectedTemplate.data;
        
        _selectedCategory = data['category'] ?? '';
        _selectedAccount = data['account'] ?? 'Наличные';
        _isIncome = data['isIncome'] ?? false;
        _commentController.text = data['comment'] ?? '';
      });
      
      AppSnackbar.success(context, '✅ Шаблон "${selectedTemplate.name}" загружен');
    }
  }

  Future<TemplateModel?> _showTemplatePickerDialog(List<TemplateModel> templates) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    
    return await showDialog<TemplateModel>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Выбрать шаблон',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(
                  template.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                onTap: () => Navigator.pop(context, template),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }  

  // кастомные категории
  Future<void> _loadCustomCategories() async {
  try {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId.isEmpty) return;
    
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('customCategories')
        .get();
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String;
      final iconCode = data['icon'] as int;
      final colorValue = data['color'] as int;
      final isIncome = data['isIncome'] as bool;
      
      final category = {
        'icon': iconCode,
        'color': Color(colorValue),
      };
      
      if (isIncome) {
        _incomeCategories[name] = category;
      } else {
        _expenseCategories[name] = category;
      }
    }
    
      setState(() {});
  } catch (e) {
      print('Ошибка загрузки категорий: $e');
    }
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
        final int iconCode = entry.value['icon'] as int;
        final icon = _materialIconMap[iconCode] ?? Icons.help_outline;

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

  // ДИАЛОГ ДОБАВЛЕНИЯ КАТЕГОРИИ
  void _showAddCategoryDialog(bool isDark) {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = const Color(0xFF8b7ff5);
    
    // Список иконок на выбор
    final availableIcons = [
      Icons.category,
      Icons.shopping_bag,
      Icons.fastfood,
      Icons.local_gas_station,
      Icons.phone_android,
      Icons.pets,
      Icons.sports_esports,
      Icons.flight,
      Icons.hotel,
      Icons.music_note,
      Icons.book,
      Icons.fitness_center,
    ];
    
    // Список цветов на выбор
    final availableColors = [
      const Color(0xFF8b7ff5),
      const Color(0xFF3b82f6),
      const Color(0xFF10b981),
      const Color(0xFFf59e0b),
      const Color(0xFFef4444),
      const Color(0xFFec4899),
      const Color(0xFF06b6d4),
      const Color(0xFF8b5cf6),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
          title: Text(
            'Новая категория',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Название',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Выбор иконки
                Text(
                  'Иконка',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withOpacity(0.2)
                              : (isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? selectedColor : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Выбор цвета
                Text(
                  'Цвет',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableColors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    final authProvider = context.read<AuthProvider>();
                    final userId = authProvider.userId;
                    
                    if (userId.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }
                    
                    // Сохраняем в Firebase
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('customCategories')
                        .add({
                      'name': nameController.text,
                      'icon': selectedIcon.codePoint,
                      'color': selectedColor.value,
                      'isIncome': _isIncome,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    
                    // Добавляем локально
                    setState(() {
                      if (_isIncome) {
                        _incomeCategories[nameController.text] = {
                          'icon': selectedIcon,
                          'color': selectedColor,
                        };
                      } else {
                        _expenseCategories[nameController.text] = {
                          'icon': selectedIcon,
                          'color': selectedColor,
                        };
                      }
                      _selectedCategory = nameController.text;
                    });
                    
                    Navigator.pop(context);
                    
                    // Показываем успешное сообщение
                    if (context.mounted) {
                      AppSnackbar.success(context, '✅ Категория добавлена!');
                    }
                  } catch (e) {
                    print('Ошибка сохранения категории: $e');
                    Navigator.pop(context);
                    if (context.mounted) {
                      AppSnackbar.error(context, 'Ошибка сохранения категории');
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b7ff5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
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

    // Валидация суммы
    if (_amount == '0' || _amount.isEmpty || _amount == '.') {
      AppSnackbar.error(context, 'Введите сумму');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

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
        'categoryIcon': categoryData['icon'] as int,
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
        'createdAt': FieldValue.serverTimestamp(),
        'goalId': _selectedGoalId,
        'contributeToCertainGoal': _contributeToCertainGoal,
      };

      print('Сохранение транзакции для пользователя: $userId');
      print('Данные транзакции: $transactionData');

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(transactionData);
      
      print('Транзакция создана с ID: ${docRef.id}');

      HapticFeedback.heavyImpact();
      
      try {
        final goalProvider = context.read<GoalProvider>();
        
        if (_isIncome) {
          // Автоматическое распределение по целям
          await goalProvider.distributeToGoals(amount);
          print('✅ Доход распределён по целям автоматически');
          
          // Дополнительный вклад в конкретную цель
          if (_contributeToCertainGoal && _selectedGoalId != null) {
            await goalProvider.updateGoalProgress(_selectedGoalId!, amount);
            print('✅ Дополнительный вклад в цель $_selectedGoalId');
          }
        } else {
          // Вычитаем расход из накопительных целей
          await goalProvider.deductFromGoals(amount);
          print('✅ Расход вычтен из целей');
        }
        
        // Обновляем лимиты (если есть GoalsProvider)
        try {
          final goalsProvider = context.read<GoalsProvider>();
          await goalsProvider.handleTransaction(
            type: _isIncome ? 'income' : 'expense',
            amount: amount,
            category: _selectedCategory,
          );
          print('✅ Лимиты обновлены');
        } catch (e) {
          print('⚠️ GoalsProvider не найден: $e');
        }
      } catch (e) {
        print('⚠️ Ошибка обновления целей: $e');
      }

      if (mounted) {
        AppSnackbar.success(context, '✅ Операция сохранена!');
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('Ошибка сохранения операции: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isSaving = false);
      
      if (mounted) {
        AppSnackbar.error(context, 'Ошибка: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
