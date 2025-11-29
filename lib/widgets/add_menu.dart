// lib/widgets/add_menu.dart
import 'package:flutter/material.dart';
import '../screens/add_task_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/add_shift_screen.dart';
import 'dart:ui' as ui;

class AddMenu extends StatelessWidget {
  const AddMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.6),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Добавить', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.white),
                title: const Text('Задачу'),
                subtitle: const Text('Создать новую задачу'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  AddTaskScreen.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.white),
                title: const Text('Операцию'),
                subtitle: const Text('Доход или расход'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  AddTransactionScreen.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.white),
                title: const Text('Смену'),
                subtitle: const Text('Добавить в график'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  AddShiftScreen.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}