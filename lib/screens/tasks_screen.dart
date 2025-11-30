import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedFilter = 0;
  
  final List<Task> _tasks = [
    Task('Встреча с клиентом', '14:00', false, 'Работа'),
    Task('Закончить отчёт', '16:30', false, 'Работа'),
    Task('Тренировка', '19:00', false, 'Личное'),
    Task('Купить продукты', '20:00', true, 'Личное'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Задачи',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Фильтры
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Все', 0, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Сегодня', 1, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Выполнено', 2, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Задачи по категориям
            _buildCategorySection('Работа', isDark),
            const SizedBox(height: 16),
            _buildCategorySection('Личное', isDark),
            
            const SizedBox(height: 100), // Отступ для навигации
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isDark) {
    final isSelected = _selectedFilter == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b))
              : (isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white
                : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, bool isDark) {
    final categoryTasks = _tasks.where((task) => task.category == category).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...categoryTasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTaskItem(task, isDark),
        )).toList(),
      ],
    );
  }

  Widget _buildTaskItem(Task task, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                task.isDone = !task.isDone;
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: task.isDone 
                    ? (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b))
                    : Colors.transparent,
                border: Border.all(
                  color: task.isDone 
                      ? (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b))
                      : (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF94a3b8)),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isDone
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark 
                        ? (task.isDone ? const Color(0xFF64748b) : Colors.white)
                        : const Color(0xFF1e293b),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.time,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Task {
  final String title;
  final String time;
  bool isDone;
  final String category;

  Task(this.title, this.time, this.isDone, this.category);
}