import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String _priority = 'none'; // none, low, medium, high
  String _selectedCategory = 'Работа';
  bool _hasReminder = false;
  String _repeatType = 'none'; // none, daily, weekly, monthly
  
  final List<Subtask> _subtasks = [];
  final _subtaskController = TextEditingController();

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
                      'Новая задача',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                    const Spacer(),
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
                      GlassCard(
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
                      _buildSectionTitle('Дата и время', isDark),
                      const SizedBox(height: 12),
                      
                      // Быстрый выбор даты
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

                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => _selectDate(context, isDark),
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
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _selectTime(context, isDark),
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
                                        _selectedTime != null
                                            ? _selectedTime!.format(context)
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
                        ),
                      ),
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
                            onTap: () => setState(() => _selectedCategory = category),
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

                      // Подзадачи
                      _buildSectionTitle('Подзадачи', isDark),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: Column(
                          children: [
                            ..._subtasks.map((subtask) => _buildSubtaskItem(subtask, isDark)).toList(),
                            TextField(
                              controller: _subtaskController,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Добавить подзадачу',
                                hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.add,
                                  color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _subtasks.add(Subtask(title: value, isDone: false));
                                    _subtaskController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Напоминание
                      GlassCard(
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
                                  Icons.notifications_outlined,
                                  color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Напомнить',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  ),
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: _hasReminder,
                              activeColor: const Color(0xFF8b7ff5),
                              onChanged: (value) {
                                setState(() {
                                  _hasReminder = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Повтор
                      GlassCard(
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
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _repeatType = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Заметки
                      _buildSectionTitle('Заметки', isDark),
                      const SizedBox(height: 12),
                      GlassCard(
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
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : (isDark ? const Color(0xFF1e293b).withOpacity(0.5) : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(Icons.flag, color: Colors.white, size: 16),
              if (isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1e293b)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        onTap: () => setState(() => _selectedDate = date),
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

  Widget _buildSubtaskItem(Subtask subtask, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                subtask.isDone = !subtask.isDone;
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: subtask.isDone ? const Color(0xFF8b7ff5) : Colors.transparent,
                border: Border.all(
                  color: subtask.isDone ? const Color(0xFF8b7ff5) : (isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8)),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: subtask.isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
                decoration: subtask.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
            onPressed: () {
              setState(() {
                _subtasks.remove(subtask);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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

  Future<void> _selectTime(BuildContext context, bool isDark) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask() {
    // TODO: Сохранить задачу в Firebase
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }
}

class Subtask {
  String title;
  bool isDone;

  Subtask({required this.title, required this.isDone});
}