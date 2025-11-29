// lib/screens/add_task_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import 'dart:ui' as ui;

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  static void show(BuildContext context, {Task? taskToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskScreen(taskToEdit: taskToEdit),
    );
  }

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late TextEditingController _categoryController;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskToEdit?.title ?? '');
    _timeController = TextEditingController(text: widget.taskToEdit?.time ?? '');
    _categoryController = TextEditingController(text: widget.taskToEdit?.category ?? '');
    _done = widget.taskToEdit?.done ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.taskToEdit?.id ?? 0,
        title: _titleController.text,
        time: _timeController.text,
        done: _done,
        category: _categoryController.text,
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.taskToEdit != null) {
        provider.updateTask(task);
      } else {
        provider.addTask(task);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.6),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.taskToEdit != null ? 'Редактировать задачу' : 'Добавить задачу',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (value) => value!.isEmpty ? 'Введите название' : null,
                  ),
                  TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(labelText: 'Время'),
                    validator: (value) => value!.isEmpty ? 'Введите время' : null,
                  ),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    validator: (value) => value!.isEmpty ? 'Введите категорию' : null,
                  ),
                  SwitchListTile(
                    title: const Text('Выполнено'),
                    value: _done,
                    onChanged: (bool value) {
                      setState(() {
                        _done = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}