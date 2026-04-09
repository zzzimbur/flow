import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _userId => _auth.currentUser?.uid;

  /// Загрузка целей из Firebase
  Future<void> loadGoals(String userId) async {
    if (_userId == null) {
      _error = 'Пользователь не авторизован';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .orderBy('createdAt', descending: true)
          .get();

      _goals = snapshot.docs
          .map((doc) => GoalModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Ошибка загрузки целей: $e';
      debugPrint('Error loading goals: $e');
      _goals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Добавление новой цели
  Future<bool> addGoal(GoalModel goal) async {
    if (_userId == null) {
      _error = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .add(goal.toMap());

      final newGoal = goal.copyWith(id: docRef.id);
      _goals.insert(0, newGoal);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка создания цели: $e';
      debugPrint('Error adding goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Обновление цели
  Future<bool> updateGoal(GoalModel goal) async {
    if (_userId == null) {
      _error = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .doc(goal.id)
          .update({
        'name': goal.name,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'icon': goal.icon,
        'percentage': goal.percentage,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления цели: $e';
      debugPrint('Error updating goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Обновление прогресса цели (вызывается при создании операции)
  Future<void> updateGoalProgress(String goalId, double amount) async {
    if (_userId == null) return;

    try {
      final goalIndex = _goals.indexWhere((g) => g.id == goalId);
      if (goalIndex == -1) {
        debugPrint('Goal not found: $goalId');
        return;
      }

      final goal = _goals[goalIndex];
      final newAmount = (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .doc(goalId)
          .update({
        'currentAmount': newAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _goals[goalIndex] = goal.copyWith(
        currentAmount: newAmount,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating goal progress: $e');
      _error = 'Ошибка обновления прогресса: $e';
      notifyListeners();
    }
  }

  /// Автоматическое распределение по целям (вызывается при создании дохода)
  Future<void> distributeToGoals(double incomeAmount) async {
    if (_userId == null || incomeAmount <= 0) return;

    try {
      for (var goal in _goals) {
        // Пропускаем уже достигнутые цели
        if (goal.currentAmount >= goal.targetAmount) {
          debugPrint('Goal ${goal.name} already reached, skipping');
          continue;
        }

        // Вычисляем вклад в цель
        final contribution = incomeAmount * (goal.percentage / 100);
        debugPrint('Distributing ${contribution.toStringAsFixed(2)} ₽ to ${goal.name}');

        await updateGoalProgress(goal.id, contribution);
      }
    } catch (e) {
      debugPrint('Error distributing to goals: $e');
      _error = 'Ошибка распределения по целям: $e';
      notifyListeners();
    }
  }

  /// Вычитание из целей (вызывается при создании расхода)
  Future<void> deductFromGoals(double expenseAmount) async {
    if (_userId == null || expenseAmount <= 0) return;

    try {
      // Вычисляем общий процент всех активных целей
      final activeGoals = _goals.where((g) => g.currentAmount > 0).toList();
      
      if (activeGoals.isEmpty) {
        debugPrint('No active goals to deduct from');
        return;
      }

      final totalPercentage = activeGoals.fold<double>(
        0.0,
        (sum, goal) => sum + goal.percentage,
      );

      if (totalPercentage == 0) {
        debugPrint('Total percentage is 0, skipping deduction');
        return;
      }

      // Вычитаем пропорционально из каждой цели
      for (var goal in activeGoals) {
        final deduction = expenseAmount * (goal.percentage / totalPercentage);
        debugPrint('Deducting ${deduction.toStringAsFixed(2)} ₽ from ${goal.name}');

        await updateGoalProgress(goal.id, -deduction);
      }
    } catch (e) {
      debugPrint('Error deducting from goals: $e');
      _error = 'Ошибка вычитания из целей: $e';
      notifyListeners();
    }
  }

  /// Удаление цели
  Future<bool> deleteGoal(String goalId) async {
    if (_userId == null) {
      _error = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .doc(goalId)
          .delete();

      _goals.removeWhere((g) => g.id == goalId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления цели: $e';
      debugPrint('Error deleting goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Получить цель по ID
  GoalModel? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((g) => g.id == goalId);
    } catch (e) {
      return null;
    }
  }

  /// Получить общий прогресс всех целей (в процентах)
  double getTotalProgress() {
    if (_goals.isEmpty) return 0.0;

    final totalProgress = _goals.fold<double>(
      0.0,
      (sum, goal) => sum + (goal.currentAmount / goal.targetAmount),
    );

    return (totalProgress / _goals.length * 100).clamp(0.0, 100.0);
  }

  /// Получить общую сумму всех целей
  double getTotalTargetAmount() {
    return _goals.fold<double>(
      0.0,
      (sum, goal) => sum + goal.targetAmount,
    );
  }

  /// Получить общую накопленную сумму
  double getTotalCurrentAmount() {
    return _goals.fold<double>(
      0.0,
      (sum, goal) => sum + goal.currentAmount,
    );
  }

  /// Получить количество достигнутых целей
  int getCompletedGoalsCount() {
    return _goals.where((g) => g.currentAmount >= g.targetAmount).length;
  }

  /// Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Сбросить состояние
  void reset() {
    _goals = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}