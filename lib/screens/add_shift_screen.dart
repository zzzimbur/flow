// lib/screens/add_shift_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/shift.dart';
import 'dart:ui' as ui;

class AddShiftScreen extends StatefulWidget {
  final Shift? shiftToEdit;

  const AddShiftScreen({super.key, this.shiftToEdit});

  static void show(BuildContext context, {Shift? shiftToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddShiftScreen(shiftToEdit: shiftToEdit),
    );
  }

  @override
  _AddShiftScreenState createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _hoursController;
  late TextEditingController _earningsController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.shiftToEdit?.title ?? '');
    _hoursController = TextEditingController(text: widget.shiftToEdit?.hours.toString() ?? '');
    _earningsController = TextEditingController(text: widget.shiftToEdit?.earnings.toString() ?? '');
    _dateController = TextEditingController(text: widget.shiftToEdit?.date ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hoursController.dispose();
    _earningsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _saveShift() {
    if (_formKey.currentState!.validate()) {
      final shift = Shift(
        id: widget.shiftToEdit?.id ?? 0,
        title: _titleController.text,
        hours: int.parse(_hoursController.text),
        earnings: int.parse(_earningsController.text),
        date: _dateController.text,
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.shiftToEdit != null) {
        provider.updateShift(shift);
      } else {
        provider.addShift(shift);
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
                    widget.shiftToEdit != null ? 'Редактировать смену' : 'Добавить смену',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (value) => value!.isEmpty ? 'Введите название' : null,
                  ),
                  TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(labelText: 'Часы'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Введите часы' : null,
                  ),
                  TextFormField(
                    controller: _earningsController,
                    decoration: const InputDecoration(labelText: 'Заработок'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Введите заработок' : null,
                  ),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Дата'),
                    validator: (value) => value!.isEmpty ? 'Введите дату' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveShift,
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