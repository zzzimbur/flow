import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../widgets/ios_time_picker.dart';
import '../theme/coinka.dart';
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
  TimeOfDay? _startTime;
  String _priority = 'none';
  String _selectedCategory = 'Работа';
  bool _hasReminder = false;
  String _repeatType = 'none';
  DateTime? _repeatEndDate; // null = навсегда
  bool _isSaving = false;
  
  final List<Subtask> _subtasks = [];
  final _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Инициализация из параметров
    _selectedDate = widget.initialDate ?? DateTime.now();
    _startTime = widget.initialTime;
    
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
  InputDecoration _coinkaInput({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.ckHint, fontSize: 15),
    filled: true, fillColor: context.ckCard,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
  );

  Widget build(BuildContext context) {
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
                  Expanded(child: Text('Новая задача', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText,
                  ))),
                  GestureDetector(onTap: _saveAsTemplate, child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('📋', style: TextStyle(fontSize: 20)),
                  )),
                  GestureDetector(onTap: _loadFromTemplate, child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('📂', style: TextStyle(fontSize: 20)),
                  )),
                  const SizedBox(width: 8),
                  if (_isSaving)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Coinka.accent, strokeWidth: 2))
                  else
                    GestureDetector(
                      onTap: _saveTask,
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
                    // Название
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.ckText),
                      decoration: _coinkaInput(hint: 'Что нужно сделать?'),
                    ),
                    const SizedBox(height: 20),

                    // Приоритет
                    Text('ПРИОРИТЕТ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildPriorityChip('—', 'none', context.ckMuted),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Низкий', 'low', const Color(0xFF3b82f6)),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Средний', 'medium', const Color(0xFFf59e0b)),
                        const SizedBox(width: 8),
                        _buildPriorityChip('Высокий', 'high', Coinka.red),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Дата и время
                    _buildDateTimeSection(),
                    const SizedBox(height: 20),

                    // Категория
                    Text('КАТЕГОРИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Coinka.accentDim : context.ckCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Coinka.accent : context.ckBorder, width: isSelected ? 1.5 : 1),
                            ),
                            child: Text(cat, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected ? Coinka.accent : context.ckHint,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Повтор
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                      child: Row(
                        children: [
                          const Text('🔄', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Повтор', style: TextStyle(fontSize: 15, color: context.ckText, fontWeight: FontWeight.w600))),
                          DropdownButton<String>(
                            value: _repeatType, underline: const SizedBox(),
                            dropdownColor: context.ckCard,
                            style: TextStyle(fontSize: 14, color: context.ckHint, fontWeight: FontWeight.w600),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.ckHint),
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('Не повторять')),
                              DropdownMenuItem(value: 'daily', child: Text('Ежедневно')),
                              DropdownMenuItem(value: 'weekly', child: Text('Еженедельно')),
                              DropdownMenuItem(value: 'monthly', child: Text('Ежемесячно')),
                              DropdownMenuItem(value: 'yearly', child: Text('Ежегодно')),
                            ],
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _repeatType = v!;
                                if (v == 'none') _repeatEndDate = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Дата окончания повтора — только если выбран повтор
                    if (_repeatType != 'none') ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          DateTime picked = _repeatEndDate ?? DateTime.now().add(const Duration(days: 90));
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: context.ckCard,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (_) => SizedBox(
                              height: 320,
                              child: Column(children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    GestureDetector(
                                      onTap: () { Navigator.pop(context); setState(() => _repeatEndDate = null); },
                                      child: Text('Навсегда', style: TextStyle(color: Coinka.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                                    ),
                                    Text('До какой даты', style: TextStyle(color: context.ckHint, fontSize: 14)),
                                    GestureDetector(
                                      onTap: () { Navigator.pop(context); setState(() => _repeatEndDate = picked); },
                                      child: Text('Готово', style: TextStyle(color: Coinka.accent, fontSize: 15, fontWeight: FontWeight.w700)),
                                    ),
                                  ]),
                                ),
                                Expanded(
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: picked,
                                    minimumDate: DateTime.now().add(const Duration(days: 1)),
                                    maximumDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                    onDateTimeChanged: (d) => picked = d,
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.ckCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.ckBorder),
                          ),
                          child: Row(children: [
                            const Text('📅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              _repeatEndDate != null
                                ? 'До ${_repeatEndDate!.day.toString().padLeft(2,'0')}.${_repeatEndDate!.month.toString().padLeft(2,'0')}.${_repeatEndDate!.year}'
                                : 'Повторять навсегда',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: _repeatEndDate != null ? context.ckText : context.ckHint),
                            )),
                            Icon(Icons.chevron_right_rounded, color: context.ckHint, size: 18),
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Заметки
                    Text('ЗАМЕТКИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      style: TextStyle(color: context.ckText, fontSize: 15),
                      decoration: _coinkaInput(hint: 'Добавьте заметку...'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _priority = value); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : context.ckCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : context.ckBorder, width: isSelected ? 1.5 : 1),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: isSelected ? color : context.ckHint,
          )),
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime date) {
    final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month && _selectedDate.year == date.year;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedDate = date); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Coinka.accentDim : context.ckCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Coinka.accent : context.ckBorder, width: isSelected ? 1.5 : 1),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isSelected ? Coinka.accent : context.ckHint,
          )),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ДАТА И ВРЕМЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildQuickDateChip('Сегодня', DateTime.now()),
            const SizedBox(width: 8),
            _buildQuickDateChip('Завтра', DateTime.now().add(const Duration(days: 1))),
            const SizedBox(width: 8),
            _buildQuickDateChip('+ 7 дней', DateTime.now().add(const Duration(days: 7))),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _selectDate(true),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, color: Coinka.accent, size: 18),
                      const SizedBox(width: 10),
                      Text('${_selectedDate.day} ${coinkaMonths[_selectedDate.month - 1].toLowerCase()} ${_selectedDate.year}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.ckText)),
                    ]),
                    Icon(Icons.chevron_right_rounded, color: context.ckHint, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: context.ckBorder),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _selectStartTime(true),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.access_time_rounded, color: Coinka.accent, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _startTime != null
                          ? '${_startTime!.hour.toString().padLeft(2,'0')}:${_startTime!.minute.toString().padLeft(2,'0')}'
                          : 'Добавить время',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.ckText),
                      ),
                    ]),
                    Icon(Icons.chevron_right_rounded, color: context.ckHint, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.ckS2, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.ckBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: context.ckHint)),
            const SizedBox(height: 4),
            Text(
              time != null
                  ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : '--:--',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Coinka.accent),
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

      final taskData = {
        'title': _titleController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'startTime': startDateTime != null ? Timestamp.fromDate(startDateTime) : null,
        'priority': _priority,
        'category': _selectedCategory,
        'isDone': false,
        'subtasks': _subtasks.map((s) => s.toMap()).toList(),
        'hasReminder': _hasReminder,
        'repeatType': _repeatType,
        'repeatEndDate': (_repeatType != 'none' && _repeatEndDate != null)
            ? Timestamp.fromDate(_repeatEndDate!)
            : null,
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