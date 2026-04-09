import 'dart:ui';

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
import '../models/task_model.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  
  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late bool _hasTimeRange;
  
  late String _priority;
  late String _selectedCategory;
  late bool _hasReminder;
  late String _repeatType;
  bool _isSaving = false;
  
  final List<String> _categories = [
    'Работа',
    'Личное',
    'Покупки',
    'Здоровье',
    'Обучение',
    'Дом',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _noteController = TextEditingController(text: widget.task.note ?? '');
    
    _selectedDate = widget.task.date;
    _startTime = widget.task.startTime != null 
        ? TimeOfDay(hour: widget.task.startTime!.hour, minute: widget.task.startTime!.minute)
        : null;
    _endTime = widget.task.endTime != null
        ? TimeOfDay(hour: widget.task.endTime!.hour, minute: widget.task.endTime!.minute)
        : null;
    _hasTimeRange = widget.task.hasTimeRange;
    
    _priority = widget.task.priority;
    _selectedCategory = widget.task.category;
    _hasReminder = widget.task.hasReminder;
    _repeatType = widget.task.repeatType;
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white : const Color(0xFF1e293b)),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(  // <-- ДОБАВИЛ Expanded
                    child: Text(
                      'Редактировать задачу',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                      overflow: TextOverflow.ellipsis, 
                    ),
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      _buildDateTimeSection(isDark),
                      const SizedBox(height: 24),

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
                                      'Удалить задачу',
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
                        'Удалить задачу?',
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
      await _deleteTask();
    }
  }

  Future<void> _deleteTask() async {
    HapticFeedback.heavyImpact();
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(widget.task.id)
          .delete();
      
      if (mounted) {
        AppSnackbar.success(context, '✅ Задача удалена');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Ошибка удаления: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Ошибка удаления');
      }
    }
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
        'hasReminder': _hasReminder,
        'repeatType': _repeatType,
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(widget.task.id)
          .update(taskData);

      HapticFeedback.heavyImpact();
      
      if (mounted) {
        AppSnackbar.success(context, '✅ Задача обновлена!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Ошибка обновления задачи: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.error(context, 'Ошибка обновления задачи');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}