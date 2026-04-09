import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Типы целей
enum GoalType {
  income,          // Цель по доходу
  expenseLimit,    // Лимит расходов
  saving,          // Накопление
  categoryLimit,   // Лимит по категории
}

// Периоды целей
enum GoalPeriod {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

class Goal {
  final String id;
  final String userId;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double currentAmount;
  final GoalPeriod period;
  final String? category; // Для categoryLimit
  final DateTime? startDate; // Для custom период
  final DateTime? endDate;   // Для custom период
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.period,
    this.category,
    this.startDate,
    this.endDate,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  // Прогресс в процентах
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return ((currentAmount / targetAmount) * 100).clamp(0.0, 100.0);
  }

  // Осталось до цели
  double get remaining {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  // Превышен ли лимит
  bool get isOverLimit {
    return type == GoalType.expenseLimit || type == GoalType.categoryLimit
        ? currentAmount > targetAmount
        : false;
  }

  // Достигнута ли цель
  bool get isAchieved {
    return type == GoalType.income || type == GoalType.saving
        ? currentAmount >= targetAmount
        : false;
  }

  // Получить дату начала периода
  DateTime getPeriodStart() {
    final now = DateTime.now();
    
    switch (period) {
      case GoalPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case GoalPeriod.weekly:
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
      case GoalPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case GoalPeriod.yearly:
        return DateTime(now.year, 1, 1);
      case GoalPeriod.custom:
        return startDate ?? now;
    }
  }

  // Получить дату окончания периода
  DateTime getPeriodEnd() {
    final now = DateTime.now();
    
    switch (period) {
      case GoalPeriod.daily:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case GoalPeriod.weekly:
        final weekday = now.weekday;
        final daysUntilSunday = 7 - weekday;
        return DateTime(now.year, now.month, now.day, 23, 59, 59)
            .add(Duration(days: daysUntilSunday));
      case GoalPeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case GoalPeriod.yearly:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case GoalPeriod.custom:
        return endDate ?? now.add(const Duration(days: 30));
    }
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: GoalType.values.firstWhere(
        (e) => e.toString() == 'GoalType.${map['type']}',
        orElse: () => GoalType.expenseLimit,
      ),
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      period: GoalPeriod.values.firstWhere(
        (e) => e.toString() == 'GoalPeriod.${map['period']}',
        orElse: () => GoalPeriod.monthly,
      ),
      category: map['category'],
      startDate: map['startDate'] != null 
          ? (map['startDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      color: Color(map['color'] ?? 0xFF8b7ff5),
      icon: Icons.flag,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'period': period.toString().split('.').last,
      'category': category,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? name,
    GoalType? type,
    double? targetAmount,
    double? currentAmount,
    GoalPeriod? period,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      period: period ?? this.period,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GoalsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _userId => _auth.currentUser?.uid;

  /// Загрузить все цели
  Future<void> loadGoals() async {
    if (_userId == null) {
      _errorMessage = 'Пользователь не авторизован';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .orderBy('createdAt', descending: true)
          .get();

      _goals = snapshot.docs
          .map((doc) => Goal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Сбросить цели, у которых закончился период
      await _resetExpiredGoals();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Ошибка загрузки целей: $e';
      debugPrint('Error loading goals: $e');
      _goals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Создать новую цель
  Future<bool> createGoal({
    required String userId,
    required String name,
    required GoalType type,
    required double targetAmount,
    required GoalPeriod period,
    String? category,
    DateTime? customStartDate,
    DateTime? customEndDate,
    required Color color,
    required IconData icon,
  }) async {
    if (_userId == null) {
      _errorMessage = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final goal = Goal(
        id: '',
        userId: userId,
        name: name,
        type: type,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        period: period,
        category: category,
        startDate: customStartDate,
        endDate: customEndDate,
        color: color,
        icon: icon,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .add(goal.toMap());

      _goals.insert(0, goal.copyWith(id: docRef.id));
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка создания цели: $e';
      debugPrint('Error creating goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Обновить прогресс цели при добавлении транзакции
  Future<void> updateGoalProgress(String goalId, double amount) async {
    if (_userId == null) return;

    try {
      final goalIndex = _goals.indexWhere((g) => g.id == goalId);
      if (goalIndex == -1) return;

      final goal = _goals[goalIndex];
      final newAmount = goal.currentAmount + amount;

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
    }
  }

  /// Обновить цель при добавлении транзакции
  Future<void> handleTransaction({
    required String type, // 'income' или 'expense'
    required double amount,
    String? category,
  }) async {
    for (var goal in _goals) {
      // Проверяем, находится ли цель в активном периоде
      if (!_isGoalActive(goal)) continue;

      bool shouldUpdate = false;
      double updateAmount = 0.0;

      // Определяем, нужно ли обновлять цель
      switch (goal.type) {
        case GoalType.income:
          if (type == 'income') {
            shouldUpdate = true;
            updateAmount = amount;
          }
          break;

        case GoalType.expenseLimit:
          if (type == 'expense') {
            shouldUpdate = true;
            updateAmount = amount;
          }
          break;

        case GoalType.categoryLimit:
          if (type == 'expense' && category == goal.category) {
            shouldUpdate = true;
            updateAmount = amount;
          }
          break;

        case GoalType.saving:
          // Накопление обновляется отдельно через GoalProvider
          break;
      }

      if (shouldUpdate) {
        await updateGoalProgress(goal.id, updateAmount);
      }
    }
  }

  /// Проверить, активна ли цель (в пределах периода)
  bool _isGoalActive(Goal goal) {
    final now = DateTime.now();
    final periodStart = goal.getPeriodStart();
    final periodEnd = goal.getPeriodEnd();
    
    return now.isAfter(periodStart) && now.isBefore(periodEnd);
  }

  /// Сбросить цели с истекшим периодом
  Future<void> _resetExpiredGoals() async {
    if (_userId == null) return;

    final now = DateTime.now();
    final batch = _firestore.batch();

    for (var goal in _goals) {
      final periodEnd = goal.getPeriodEnd();
      
      if (now.isAfter(periodEnd) && goal.currentAmount != 0.0) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('goals')
            .doc(goal.id);

        batch.update(docRef, {
          'currentAmount': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    try {
      await batch.commit();
      
      // Обновляем локальный список
      _goals = _goals.map((goal) {
        final periodEnd = goal.getPeriodEnd();
        if (now.isAfter(periodEnd)) {
          return goal.copyWith(currentAmount: 0.0, updatedAt: now);
        }
        return goal;
      }).toList();
      
    } catch (e) {
      debugPrint('Error resetting expired goals: $e');
    }
  }

  /// Удалить цель
  Future<bool> deleteGoal(String goalId) async {
    if (_userId == null) {
      _errorMessage = 'Пользователь не авторизован';
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
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка удаления цели: $e';
      debugPrint('Error deleting goal: $e');
      notifyListeners();
      return false;
    }
  }

  /// Получить цели по типу
  List<Goal> getGoalsByType(GoalType type) {
    return _goals.where((g) => g.type == type).toList();
  }

  /// Получить активные цели
  List<Goal> getActiveGoals() {
    return _goals.where((g) => _isGoalActive(g)).toList();
  }

  /// Получить цели с превышенным лимитом
  List<Goal> getOverLimitGoals() {
    return _goals.where((g) => g.isOverLimit).toList();
  }

  /// Получить достигнутые цели
  List<Goal> getAchievedGoals() {
    return _goals.where((g) => g.isAchieved).toList();
  }

  /// Очистить ошибку
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Сбросить провайдер
  void reset() {
    _goals = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}