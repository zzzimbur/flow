import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/task_model.dart';
import '../theme/coinka.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';

/// Вкладка «Задачи»: счётчики, фильтр-чипы, список с чекбоксами.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _isLoading = true;
  String _filter = 'all'; // all | today | week | overdue
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Последние 3 месяца + всё будущее
      final from = DateTime.now().subtract(const Duration(days: 90));
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .orderBy('date', descending: false)
          .get();

      if (!mounted) return;
      setState(() {
        _tasks = snap.docs.map(TaskModel.fromSnapshot).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки задач: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(TaskModel task) async {
    HapticFeedback.lightImpact();
    final userId = context.read<AuthProvider>().userId;
    if (userId.isEmpty) return;

    final markingDone = !task.isDone;

    // Оптимистичное обновление
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) {
        _tasks[i] = task.copyWith(isDone: markingDone);
      }
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .update({'isDone': markingDone});

    // Если задача отмечена выполненной и у неё есть повтор — создаём следующее вхождение
    if (markingDone && task.repeatType != 'none') {
      final nextDate = _nextRepeatDate(task.date, task.repeatType);
      final endDate = task.repeatEndDate;
      if (endDate == null || !nextDate.isAfter(endDate)) {
        final ref = FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks');
        await ref.add({
          'title': task.title,
          'date': Timestamp.fromDate(nextDate),
          'startTime': task.startTime != null
              ? Timestamp.fromDate(DateTime(nextDate.year, nextDate.month, nextDate.day,
                  task.startTime!.hour, task.startTime!.minute))
              : null,
          'priority': task.priority,
          'category': task.category,
          'isDone': false,
          'subtasks': task.subtasks.map((s) => {'title': s.title, 'isDone': false}).toList(),
          'hasReminder': task.hasReminder,
          'repeatType': task.repeatType,
          'repeatEndDate': endDate != null ? Timestamp.fromDate(endDate) : null,
          'note': task.note,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _loadTasks();
      }
    }
  }

  DateTime _nextRepeatDate(DateTime from, String repeatType) {
    switch (repeatType) {
      case 'daily': return from.add(const Duration(days: 1));
      case 'weekly': return from.add(const Duration(days: 7));
      case 'monthly': return DateTime(from.year, from.month + 1, from.day);
      case 'yearly': return DateTime(from.year + 1, from.month, from.day);
      default: return from.add(const Duration(days: 1));
    }
  }

  bool _isOverdue(TaskModel t) {
    if (t.isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return t.date.isBefore(today);
  }

  List<TaskModel> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_filter) {
      case 'today':
        return _tasks
            .where((t) =>
                t.date.year == today.year &&
                t.date.month == today.month &&
                t.date.day == today.day)
            .toList();
      case 'week':
        final weekEnd = today.add(const Duration(days: 7));
        return _tasks
            .where((t) => !t.date.isBefore(today) && t.date.isBefore(weekEnd))
            .toList();
      case 'overdue':
        return _tasks.where(_isOverdue).toList();
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _tasks.where((t) => !t.isDone).length;
    final done = _tasks.where((t) => t.isDone).length;
    final overdue = _tasks.where(_isOverdue).length;

    return Container(
      color: context.ckBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CoinkaHeader(
              title: 'Задачи',
              trailing: GestureDetector(
                onTap: _openAddTask,
                child: const Text(
                  '+ Добавить',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Coinka.accent,
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTasks,
                color: Coinka.accent,
                backgroundColor: context.ckS2,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // Счётчики
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Row(
                        children: [
                          _buildCounter('$active', 'Активных', context.ckText),
                          const SizedBox(width: 10),
                          _buildCounter('$done', 'Готово', Coinka.accent),
                          const SizedBox(width: 10),
                          _buildCounter('$overdue', 'Просроч.', Coinka.red),
                        ],
                      ),
                    ),
                    // Фильтр-чипы
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Row(
                        children: [
                          _buildChip('Все', 'all'),
                          _buildChip('Сегодня', 'today'),
                          _buildChip('Неделя', 'week'),
                          _buildChip('Просроченные', 'overdue'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Coinka.accent,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (_filtered.isEmpty)
                      const CoinkaEmpty(
                        emoji: '✅',
                        text: 'Нет задач.\nСамое время отдохнуть — или добавить новую!',
                      )
                    else
                      ..._filtered.map(_buildTaskItem),
                    CoinkaAddButton(
                      label: 'Новая задача',
                      onTap: _openAddTask,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTask() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    ).then((result) {
      if (result == true) _loadTasks();
    });
  }

  Widget _buildCounter(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ckCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.ckBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.ckHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final on = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: on ? Coinka.accentDim : context.ckS2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? const Color(0x4D00E5B3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? Coinka.accent : context.ckHint,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    final overdue = _isOverdue(task);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
        ).then((result) {
          if (result == true) _loadTasks();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.ckBorder)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleDone(task),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isDone ? Coinka.green : Colors.transparent,
                    border: Border.all(
                      color: task.isDone ? Coinka.green : context.ckMuted,
                      width: 2,
                    ),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.black)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: task.isDone ? context.ckHint : context.ckText,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: context.ckHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.date.day} ${coinkaMonths[task.date.month - 1].toLowerCase()}'
                    '${task.timeRangeString.isNotEmpty ? ' · ${task.timeRangeString}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: overdue ? Coinka.red : context.ckHint,
                    ),
                  ),
                ],
              ),
            ),
            if (task.priority != 'none')
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.getPriorityColor(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
