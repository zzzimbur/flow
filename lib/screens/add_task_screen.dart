import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_glass_card.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_snackbar.dart';
import '../services/template_service.dart';
import '../models/template_model.dart';
import '../providers/subscription_provider.dart';

class AddTaskScreen extends StatefulWidget {

  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const AddTaskScreen({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;  // время начала
  TimeOfDay? _endTime;    // время окончания
  bool _hasTimeRange = false;  // есть ли диапазон времени
  
  String _priority = 'none';
  String _selectedCategory = 'Работа';
  bool _hasReminder = false;
  String _repeatType = 'none';
  bool _isSaving = false;
  
  final List<Subtask> _subtasks = [];
  final _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Инициализация из параметров
    _selectedDate = widget.initialDate ?? DateTime.now();
    _startTime = widget.initialTime;
    
    // Конец задачи - через 1 час
    if (_startTime != null) {
      final endHour = (_startTime!.hour + 1) % 24;
      _endTime = TimeOfDay(hour: endHour, minute: _startTime!.minute);
    }
  }

  final List<String> _categories = [
    'Работа',
    'Личное',
    'Покупки',
    'Здоровье',
    'Обучение',
    'Дом',
  ];

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
                        'Новая задача',
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
                    const SizedBox(width: 8),
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
                        onPressed: _saveTask,
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название задачи
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: TextField(
                          controller: _titleController,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1e293b),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Что нужно сделать?',
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Приоритет
                      _buildSectionTitle('Приоритет', isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPriorityChip('Без приоритета', 'none', Colors.grey, isDark),
                          const SizedBox(width: 8),
                          _buildPriorityChip('Низкий', 'low', const Color(0xFF3b82f6), isDark),
                          const SizedBox(width: 8),
                          _buildPriorityChip('Средний', 'medium', const Color(0xFFf59e0b), isDark),
                          const SizedBox(width: 8),
                          _buildPriorityChip('Высокий', 'high', const Color(0xFFef4444), isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Дата и время
                      _buildDateTimeSection(isDark),
                      const SizedBox(height: 24),

                      // Категория
                      _buildSectionTitle('Категория', isDark),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = category);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF8b7ff5)
                                    : (isDark
                                        ? const Color(0xFF1e293b).withOpacity(0.5)
                                        : Colors.white.withOpacity(0.7)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF8b7ff5)
                                      : Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : const Color(0xFF1e293b)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Повтор
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.repeat,
                                  color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Повтор',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  ),
                                ),
                              ],
                            ),
                            DropdownButton<String>(
                              value: _repeatType,
                              underline: const SizedBox(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
                              ),
                              dropdownColor: isDark ? const Color(0xFF1e293b) : Colors.white,
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('Не повторять')),
                                DropdownMenuItem(value: 'daily', child: Text('Ежедневно')),
                                DropdownMenuItem(value: 'weekly', child: Text('Еженедельно')),
                                DropdownMenuItem(value: 'monthly', child: Text('Ежемесячно')),
                                DropdownMenuItem(value: 'yearly', child: Text('Ежегодно')),
                              ],
                              onChanged: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _repeatType = value!);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Заметки
                      _buildSectionTitle('Заметки', isDark),
                      const SizedBox(height: 12),
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 4,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1e293b),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Добавьте заметку...',
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                            ),
                            border: InputBorder.none,
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF1e293b),
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color, bool isDark) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _priority = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? const Color(0xFF1e293b).withOpacity(0.5) : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(Icons.flag, color: Colors.white, size: 14),
              if (isSelected) const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1e293b)),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime date, bool isDark) {
    final isSelected = _selectedDate.day == date.day &&
        _selectedDate.month == date.month &&
        _selectedDate.year == date.year;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedDate = date);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8b7ff5)
                : (isDark ? const Color(0xFF1e293b).withOpacity(0.5) : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF8b7ff5) : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1e293b)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Дата и время', isDark),
        const SizedBox(height: 12),
        
        Row(
          children: [
            _buildQuickDateChip('Сегодня', DateTime.now(), isDark),
            const SizedBox(width: 8),
            _buildQuickDateChip(
              'Завтра',
              DateTime.now().add(const Duration(days: 1)),
              isDark,
            ),
            const SizedBox(width: 8),
            _buildQuickDateChip(
              'След. неделя',
              DateTime.now().add(const Duration(days: 7)),
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),

        EnhancedGlassCard(
          padding: const EdgeInsets.all(16),
          color: isDark
              ? const Color(0xFF1e293b).withOpacity(0.5)
              : Colors.white.withOpacity(0.7),
          child: Column(
            children: [
              // Дата
              InkWell(
                onTap: () => _selectDate(isDark),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF1e293b),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
              ),
              const SizedBox(height: 16),
              
              // Переключатель диапазона времени
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Временной диапазон',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                  Switch(
                    value: _hasTimeRange,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _hasTimeRange = value);
                    },
                    activeColor: const Color(0xFF8b7ff5),
                  ),
                ],
              ),
              
              if (_hasTimeRange) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeButton(
                        'Начало',
                        _startTime,
                        isDark,
                        () => _selectStartTime(isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward,
                      color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeButton(
                        'Конец',
                        _endTime,
                        isDark,
                        () => _selectEndTime(isDark),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectStartTime(isDark),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _startTime != null
                                ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                                : 'Добавить время',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF1e293b),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeButton(
    String label,
    TimeOfDay? time,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time != null
                  ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : '--:--',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isDark) async {
    HapticFeedback.lightImpact();
    
    final picked = await IOSDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      isDark: isDark,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(bool isDark) async {
    HapticFeedback.lightImpact();
    
    final picked = await IOSTimePicker.show(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      isDark: isDark,
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }
  
  Future<void> _selectEndTime(bool isDark) async {
    HapticFeedback.lightImpact();
    
    final picked = await IOSTimePicker.show(
      context: context,
      initialTime: _endTime ?? (_startTime?.replacing(hour: _startTime!.hour + 1) ?? TimeOfDay.now()),
      isDark: isDark,
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Введите название задачи');
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

      // Создаём DateTime для начального времени
      DateTime? startDateTime;
      if (_startTime != null) {
        startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _startTime!.hour,
          _startTime!.minute,
        );
      }
      
      // Создаём DateTime для конечного времени
      DateTime? endDateTime;
      if (_hasTimeRange && _endTime != null) {
        endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final taskData = {
        'title': _titleController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'startTime': startDateTime != null ? Timestamp.fromDate(startDateTime) : null,
        'endTime': endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
        'priority': _priority,
        'category': _selectedCategory,
        'isDone': false,
        'subtasks': _subtasks.map((s) => s.toMap()).toList(),
        'hasReminder': _hasReminder,
        'repeatType': _repeatType,
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add(taskData);

      HapticFeedback.heavyImpact();
      
      if (mounted) {
        AppSnackbar.success(context, '✅ Задача создана!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Ошибка сохранения задачи: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.error(context, 'Ошибка сохранения задачи');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _saveAsTemplate() async {
    // проверка подписки
    // final subscriptionProvider = context.read<SubscriptionProvider>();
    // if (!subscriptionProvider.canUseTemplates) {
    //   subscriptionProvider.showPremiumDialog(context, 'templates');
    //   return;
    // }    

    if (_titleController.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Введите название задачи');
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

      final taskData = {
        'title': _titleController.text.trim(),
        'priority': _priority,
        'category': _selectedCategory,
        'hasReminder': _hasReminder,
        'repeatType': _repeatType,
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      };

      final templateService = TemplateService();
      final templateId = await templateService.createTemplateFromTask(
        userId: userId,
        name: templateName.trim(),
        taskData: taskData,
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
  
  Future<void> _loadFromTemplate() async {
    HapticFeedback.mediumImpact();
    
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId.isEmpty) {
      AppSnackbar.error(context, 'Пользователь не авторизован');
      return;
    }
    
    final templateService = TemplateService();
    final templates = await templateService.getTemplates(userId, type: TemplateType.task);
    
    if (templates.isEmpty) {
      AppSnackbar.error(context, 'Нет сохраненных шаблонов');
      return;
    }
    
    final selectedTemplate = await _showTemplatePickerDialog(templates);
    
    if (selectedTemplate != null) {
      setState(() {
        final data = selectedTemplate.data;
        
        _titleController.text = data['title'] ?? '';
        _priority = data['priority'] ?? 'none';
        _selectedCategory = data['category'] ?? 'Работа';
        _hasReminder = data['hasReminder'] ?? false;
        _repeatType = data['repeatType'] ?? 'none';
        _noteController.text = data['note'] ?? '';
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
}

class Subtask {
  String title;
  bool isDone;

  Subtask({required this.title, required this.isDone});

  Map<String, dynamic> toMap() {
    return {'title': title, 'isDone': isDone};
  }
}