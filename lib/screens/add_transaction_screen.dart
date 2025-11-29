// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/transaction.dart';
import 'dart:ui' as ui;

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? txToEdit;

  const AddTransactionScreen({super.key, this.txToEdit});

  static void show(BuildContext context, {TransactionModel? txToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(txToEdit: txToEdit),
    );
  }

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _dateController;
  String _type = 'income';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.txToEdit?.title ?? '');
    _amountController = TextEditingController(text: widget.txToEdit?.amount.abs().toString() ?? '');
    _categoryController = TextEditingController(text: widget.txToEdit?.category ?? '');
    _dateController = TextEditingController(text: widget.txToEdit?.date ?? '');
    _type = widget.txToEdit?.type ?? 'income';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      int amount = int.parse(_amountController.text);
      if (_type == 'expense') amount = -amount;

      final tx = TransactionModel(
        id: widget.txToEdit?.id ?? 0,
        title: _titleController.text,
        amount: amount,
        type: _type,
        category: _categoryController.text,
        date: _dateController.text,
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.txToEdit != null) {
        provider.updateTransaction(tx);
      } else {
        provider.addTransaction(tx);
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
                    widget.txToEdit != null ? 'Редактировать операцию' : 'Добавить операцию',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (value) => value!.isEmpty ? 'Введите название' : null,
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Сумма'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Введите сумму' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Доход')),
                      DropdownMenuItem(value: 'expense', child: Text('Расход')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _type = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Тип'),
                  ),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    validator: (value) => value!.isEmpty ? 'Введите категорию' : null,
                  ),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Дата'),
                    validator: (value) => value!.isEmpty ? 'Введите дату' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveTransaction,
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