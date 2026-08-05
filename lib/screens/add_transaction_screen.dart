import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
import '../theme/coinka.dart';

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
    final currency = context.read<SettingsProvider>().currencySymbol;
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
                    child: Text('Новая операция', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText,
                    )),
                  ),
                  GestureDetector(
                    onTap: _scanReceipt,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('📄', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveAsTemplate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('📋', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadFromTemplate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('📂', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isSaving)
                    const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Coinka.accent, strokeWidth: 2))
                  else
                    GestureDetector(
                      onTap: _saveTransaction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Готово', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                        )),
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
                      child: Row(
                        children: [
                          Expanded(child: _buildTypeButton('Расход', false)),
                          Expanded(child: _buildTypeButton('Доход', true)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Сумма
                    Center(
                      child: Column(
                        children: [
                          Text(_isIncome ? 'Доход' : 'Расход',
                            style: TextStyle(fontSize: 13, color: context.ckHint)),
                          const SizedBox(height: 6),
                          Text('$_amount $currency',
                            style: TextStyle(
                              fontSize: 48, fontWeight: FontWeight.w800,
                              color: amountColor, letterSpacing: -1,
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Калькулятор
                    _buildCalculator(),
                    const SizedBox(height: 20),

                    // Категории
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('КАТЕГОРИЯ', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: context.ckHint, letterSpacing: 0.8,
                        )),
                        GestureDetector(
                          onTap: () => _showAddCategoryDialog(true),
                          child: const Text('+ Новая',
                            style: TextStyle(fontSize: 13, color: Coinka.accent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryGrid(),
                    const SizedBox(height: 20),

                    // Счёт
                    Text('СЧЁТ', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.ckCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.ckBorder),
                      ),
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
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.ckCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.ckBorder),
                        ),
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

                    // Вклад в цель (только для доходов)
                    if (_isIncome) ...[
                      const SizedBox(height: 16),
                      Consumer<GoalProvider>(
                        builder: (context, goalProvider, _) {
                          final goals = goalProvider.goals;
                          if (goals.isEmpty) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.ckCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.ckBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Внести в цель', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.ckText)),
                                    CupertinoSwitch(
                                      value: _contributeToCertainGoal,
                                      activeColor: Coinka.accent,
                                      onChanged: (v) => setState(() { _contributeToCertainGoal = v; if (!v) _selectedGoalId = null; }),
                                    ),
                                  ],
                                ),
                                if (_contributeToCertainGoal) ...[
                                  const SizedBox(height: 12),
                                  ...goals.map((goal) {
                                    final isSelected = _selectedGoalId == goal.id;
                                    return GestureDetector(
                                      onTap: goal.isCompleted ? null : () => setState(() => _selectedGoalId = isSelected ? null : goal.id),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Coinka.accentDim : context.ckS2,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isSelected ? Coinka.accent : Colors.transparent),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(goal.icon, style: const TextStyle(fontSize: 22)),
                                            const SizedBox(width: 10),
                                            Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(goal.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.ckText)),
                                                const SizedBox(height: 3),
                                                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                                                  value: goal.progress,
                                                  backgroundColor: context.ckMuted,
                                                  valueColor: const AlwaysStoppedAnimation(Coinka.accent),
                                                  minHeight: 3,
                                                )),
                                              ],
                                            )),
                                            if (isSelected) const Icon(Icons.check_circle_rounded, color: Coinka.accent, size: 20),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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

  Future<void> _scanReceipt() async {
    final sub = context.read<SubscriptionProvider>();
    if (!sub.canScanReceipt) {
      sub.showPremiumDialog(context, 'receipt_scan');
      return;
    }
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (img == null || !mounted) return;

    final scaffoldMsg = ScaffoldMessenger.of(context);
    scaffoldMsg.showSnackBar(const SnackBar(
      content: Text('Анализирую чек…'),
      duration: Duration(seconds: 10),
    ));

    try {
      final bytes = await img.readAsBytes();
      final b64 = base64Encode(bytes);
      final resp = await http.post(
        Uri.parse('https://flow-bot-rosy.vercel.app/api/ai/receipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageBase64': b64, 'mediaType': 'image/jpeg'}),
      ).timeout(const Duration(seconds: 25));

      scaffoldMsg.hideCurrentSnackBar();

      if (resp.statusCode != 200) throw Exception('Сервер вернул ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        if (data['amount'] != null) _amount = data['amount'].toString();
        if (data['category'] != null) {
          _isIncome = false;
          _selectedCategory = data['category'].toString();
        }
        if (data['name'] != null) {
          _commentController.text = data['name'].toString();
        }
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      scaffoldMsg.hideCurrentSnackBar();
      if (mounted) {
        scaffoldMsg.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
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



  Widget _buildTypeButton(String label, bool isIncome) {
    final isSelected = _isIncome == isIncome;
    final c = isIncome ? Coinka.green : Coinka.red;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _isIncome = isIncome); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? c : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: isSelected ? c : context.ckHint,
          ),
        ),
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
            child: Center(child: Text(btn,
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600,
                color: isDelete ? Coinka.red : context.ckText,
              ),
            )),
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
              border: Border.all(
                color: isSelected ? Coinka.accent : context.ckBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(entry.key,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isSelected ? Coinka.accent : context.ckHint,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
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
