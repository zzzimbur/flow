// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../screens/add_task_screen.dart';
import '../models/task.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    for (var task in tasks) {
      grouped.putIfAbsent(task.category, () => []).add(task);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final tasks = appProvider.tasks;
    final grouped = _groupTasks(tasks);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Задачи', style: Theme.of(context).textTheme.headlineLarge),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Show settings
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Все', 'Сегодня', 'Выполнено'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(filter),
                      backgroundColor: filter == 'Все' ? Theme.of(context).primaryColor : Colors.grey[300],
                      labelStyle: TextStyle(color: filter == 'Все' ? Colors.white : Colors.grey[800]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: grouped.entries.map((entry) {
                final category = entry.key;
                final categoryTasks = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.toUpperCase(), style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...categoryTasks.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              AddTaskScreen.show(context, taskToEdit: task);
                            },
                            child: GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: task.done,
                                      onChanged: (value) {
                                        appProvider.toggleTaskDone(task.id);
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                  decoration: task.done ? TextDecoration.lineThrough : null,
                                                  color: task.done ? Colors.grey[400] : Colors.grey[800],
                                                ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(task.time, style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}