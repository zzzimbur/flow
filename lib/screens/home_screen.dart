// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../screens/add_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final stats = appProvider.stats;
    final undoneTasks = appProvider.tasks.where((t) => !t.done).toList();
    final dateFormat = DateFormat('d MMMM', 'ru_RU');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Добро пожаловать', style: Theme.of(context).textTheme.headlineLarge),
                    Text(
                      dateFormat.format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Show settings
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('За месяц', style: Theme.of(context).textTheme.bodySmall),
                            Text('${stats['monthHours']}ч', style: Theme.of(context).textTheme.headlineMedium),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Заработано', style: Theme.of(context).textTheme.bodySmall),
                            Text('₽${NumberFormat('#,###', 'ru_RU').format(stats['monthEarnings'])}', style: Theme.of(context).textTheme.headlineMedium),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Задач сегодня', style: Theme.of(context).textTheme.bodySmall),
                            Text(stats['todayTasks'].toString(), style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Смен в месяце', style: Theme.of(context).textTheme.bodySmall),
                            Text(stats['monthShifts'].toString(), style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (undoneTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Задачи на сегодня', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Column(
                children: undoneTasks.take(3).map((task) => GestureDetector(
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
                                Text(task.title, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500)),
                                Text(task.time, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Цель на месяц: ₽150,000', style: Theme.of(context).textTheme.bodyMedium),
                        Text('57%', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.57,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Осталось: ₽${(150000 - stats['monthEarnings']).toLocaleString()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}