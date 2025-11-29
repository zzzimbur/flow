// app_provider.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/transaction.dart';
import '../models/shift.dart';

class AppProvider extends ChangeNotifier {
  List<Task> _tasks = [
    Task(id: 1, title: 'Встреча с клиентом', time: '14:00', done: false, category: 'Работа'),
    Task(id: 2, title: 'Закончить отчёт', time: '16:30', done: false, category: 'Работа'),
    Task(id: 3, title: 'Тренировка', time: '19:00', done: false, category: 'Личное'),
    Task(id: 4, title: 'Купить продукты', time: '20:00', done: true, category: 'Личное'),
  ];

  List<TransactionModel> _transactions = [
    TransactionModel(id: 1, title: 'Зарплата', amount: 45000, type: 'income', category: 'Работа', date: 'Сегодня'),
    TransactionModel(id: 2, title: 'Продукты', amount: -2300, type: 'expense', category: 'Продукты', date: 'Вчера'),
    TransactionModel(id: 3, title: 'Фриланс', amount: 15000, type: 'income', category: 'Работа', date: '2 дня назад'),
    TransactionModel(id: 4, title: 'Кафе', amount: -850, type: 'expense', category: 'Развлечения', date: '3 дня назад'),
  ];

  List<Shift> _shifts = [
    Shift(id: 1, title: 'Работа в офисе', hours: 8, earnings: 3200, date: 'Сегодня'),
    Shift(id: 2, title: 'Фриланс проект', hours: 4, earnings: 2500, date: 'Вчера'),
  ];

  Map<String, dynamic> get stats {
    return {
      'monthEarnings': 85400,
      'monthHours': 168,
      'monthShifts': 22,
      'todayTasks': _tasks.where((t) => !t.done).length,
    };
  }

  List<Task> get tasks => _tasks;
  List<TransactionModel> get transactions => _transactions;
  List<Shift> get shifts => _shifts;

  void addTask(Task task) {
    _tasks.add(task.copyWith(id: _tasks.length + 1));
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void toggleTaskDone(int id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(done: !_tasks[index].done);
      notifyListeners();
    }
  }

  void addTransaction(TransactionModel tx) {
    _transactions.add(tx.copyWith(id: _transactions.length + 1));
    notifyListeners();
  }

  void updateTransaction(TransactionModel updatedTx) {
    final index = _transactions.indexWhere((t) => t.id == updatedTx.id);
    if (index != -1) {
      _transactions[index] = updatedTx;
      notifyListeners();
    }
  }

  void addShift(Shift shift) {
    _shifts.add(shift.copyWith(id: _shifts.length + 1));
    notifyListeners();
  }

  void updateShift(Shift updatedShift) {
    final index = _shifts.indexWhere((s) => s.id == updatedShift.id);
    if (index != -1) {
      _shifts[index] = updatedShift;
      notifyListeners();
    }
  }
}

extension NumExtension on num {
  String toLocaleString() {
    return toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}