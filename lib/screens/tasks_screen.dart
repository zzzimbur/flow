import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

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
                const Text(
                  'Задачи',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {},
                    color: const Color(0xFF64748b),
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
                  _buildFilterChip('Все', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('Сегодня', 1),
                  const SizedBox(width: 8),
                  _buildFilterChip('Выполнено', 2),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Задачи по категориям
            _buildCategorySection('Работа'),
            const SizedBox(height: 16),
            _buildCategorySection('Личное'),
            
            const SizedBox(height: 100), // Отступ для навигации
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
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
          color: isSelected ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748b),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryTasks = _tasks.where((task) => task.category == category).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748b),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ...categoryTasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTaskItem(task),
        )).toList(),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
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
                color: task.isDone ? const Color(0xFF1e293b) : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? const Color(0xFF1e293b) : const Color(0xFF94a3b8),
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
                    color: const Color(0xFF1e293b),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF94a3b8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF94a3b8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.time,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748b),
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