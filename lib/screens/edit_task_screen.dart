import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/ios_time_picker.dart';
import '../utils/app_snackbar.dart';
import '../theme/coinka.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _hasTimeRange = false;

  late String _priority;
  late String _selectedCategory;
  late String _repeatType;
  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _categories = ['Работа', 'Личное', 'Покупки', 'Здоровье', 'Обучение', 'Дом'];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _noteController = TextEditingController(text: t.note ?? '');
    _selectedDate = t.date;
    _startTime = t.startTime != null ? TimeOfDay(hour: t.startTime!.hour, minute: t.startTime!.minute) : null;
    _endTime = t.endTime != null ? TimeOfDay(hour: t.endTime!.hour, minute: t.endTime!.minute) : null;
    _hasTimeRange = t.endTime != null;
    _priority = t.priority;
    _selectedCategory = _categories.contains(t.category) ? t.category : 'Работа';
    _repeatType = t.repeatType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InputDecoration _coinkaInput({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.ckHint, fontSize: 15),
    filled: true, fillColor: context.ckCard,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.ckBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Coinka.accent, width: 1.5)),
  );

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
    final picked = await IOSDatePicker.show(context: context, initialDate: _selectedDate, isDark: context.isDark);
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectStartTime() async {
    HapticFeedback.lightImpact();
    final picked = await IOSTimePicker.show(context: context, initialTime: _startTime ?? TimeOfDay.now(), isDark: context.isDark);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _selectEndTime() async {
    HapticFeedback.lightImpact();
    final picked = await IOSTimePicker.show(context: context, initialTime: _endTime ?? (_startTime?.replacing(hour: _startTime!.hour + 1) ?? TimeOfDay.now()), isDark: context.isDark);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Введите название задачи');
      return;
    }
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) throw Exception('Пользователь не авторизован');

      DateTime? startDateTime;
      if (_startTime != null) {
        startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime!.hour, _startTime!.minute);
      }
      DateTime? endDateTime;
      if (_hasTimeRange && _endTime != null) {
        endDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime!.hour, _endTime!.minute);
      }

      await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('tasks').doc(widget.task.id)
          .update({
        'title': _titleController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'startTime': startDateTime != null ? Timestamp.fromDate(startDateTime) : null,
        'endTime': endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
        'priority': _priority,
        'category': _selectedCategory,
        'repeatType': _repeatType,
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      HapticFeedback.heavyImpact();
      if (mounted) {
        AppSnackbar.success(context, '✅ Задача обновлена!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) AppSnackbar.error(context, 'Ошибка сохранения задачи');
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
              Text('Удалить задачу?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ctx.ckText)),
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
    if (ok == true) _deleteTask();
  }

  Future<void> _deleteTask() async {
    setState(() => _isDeleting = true);
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) throw Exception('Пользователь не авторизован');
      await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('tasks').doc(widget.task.id)
          .delete();
      HapticFeedback.heavyImpact();
      if (mounted) {
        AppSnackbar.success(context, '🗑️ Задача удалена');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) AppSnackbar.error(context, 'Ошибка удаления');
    }
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
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(icon: Icon(Icons.close_rounded, color: context.ckHint), onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); }),
                Expanded(child: Text('Редактировать задачу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText))),
                if (_isDeleting)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Coinka.red, strokeWidth: 2)))
                else
                  GestureDetector(onTap: _confirmDelete, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('🗑️', style: TextStyle(fontSize: 20)))),
                const SizedBox(width: 4),
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
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.ckText),
                      decoration: _coinkaInput(hint: 'Что нужно сделать?'),
                    ),
                    const SizedBox(height: 20),

                    Text('ПРИОРИТЕТ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _buildPriorityChip('—', 'none', context.ckMuted),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Низкий', 'low', const Color(0xFF3b82f6)),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Средний', 'medium', const Color(0xFFf59e0b)),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Высокий', 'high', Coinka.red),
                    ]),
                    const SizedBox(height: 20),

                    _buildDateTimeSection(),
                    const SizedBox(height: 20),

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
                            child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Coinka.accent : context.ckHint)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
                      child: Row(children: [
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
                          onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _repeatType = v!); },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

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
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? color : context.ckHint)),
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
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Coinka.accent : context.ckHint)),
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
        Row(children: [
          _buildQuickDateChip('Сегодня', DateTime.now()),
          const SizedBox(width: 8),
          _buildQuickDateChip('Завтра', DateTime.now().add(const Duration(days: 1))),
          const SizedBox(width: 8),
          _buildQuickDateChip('+ 7 дней', DateTime.now().add(const Duration(days: 7))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
          child: Column(
            children: [
              GestureDetector(
                onTap: _selectDate,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Временной диапазон', style: TextStyle(fontSize: 15, color: context.ckText, fontWeight: FontWeight.w600)),
                  CupertinoSwitch(value: _hasTimeRange, activeColor: Coinka.accent, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasTimeRange = v); }),
                ],
              ),
              if (_hasTimeRange) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildTimeButton('Начало', _startTime, _selectStartTime)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, color: context.ckHint, size: 18)),
                  Expanded(child: _buildTimeButton('Конец', _endTime, _selectEndTime)),
                ]),
              ] else ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectStartTime,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.access_time_rounded, color: Coinka.accent, size: 18),
                        const SizedBox(width: 10),
                        Text(_startTime != null ? '${_startTime!.hour.toString().padLeft(2,'0')}:${_startTime!.minute.toString().padLeft(2,'0')}' : 'Добавить время',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.ckText)),
                      ]),
                      Icon(Icons.chevron_right_rounded, color: context.ckHint, size: 20),
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
              time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '--:--',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Coinka.accent),
            ),
          ],
        ),
      ),
    );
  }
}
