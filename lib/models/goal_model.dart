import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow/providers/goals_provider.dart';

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final double percentage; // Процент от доходов, который идёт в эту цель
  final DateTime createdAt;
  final DateTime? updatedAt;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.icon = '🎯',
    this.percentage = 10.0,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Прогресс достижения цели (от 0.0 до 1.0)
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Прогресс в процентах (от 0 до 100)
  double get progressPercentage {
    return progress * 100;
  }

  /// Остаток до цели
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  /// Цель достигнута?
  bool get isCompleted {
    return currentAmount >= targetAmount;
  }

  /// Создание копии с изменёнными полями
  GoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    double? percentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Создание из Map (десериализация из Firebase)
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: _toString(map['id']), // ИСПРАВЛЕНО: безопасное преобразование в String
      name: _toString(map['name'], defaultValue: ''),
      targetAmount: _toDouble(map['targetAmount']),
      currentAmount: _toDouble(map['currentAmount']),
      icon: _toString(map['icon'], defaultValue: '🎯'),
      percentage: _toDouble(map['percentage'], defaultValue: 10.0),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  /// Преобразование в Map (сериализация для Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'percentage': percentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Преобразование в Map для обновления (без createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'percentage': percentage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'percentage': percentage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Создание из JSON
  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: _toString(json['id']),
      name: _toString(json['name'], defaultValue: ''),
      targetAmount: _toDouble(json['targetAmount']),
      currentAmount: _toDouble(json['currentAmount']),
      icon: _toString(json['icon'], defaultValue: '🎯'),
      percentage: _toDouble(json['percentage'], defaultValue: 10.0),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Вспомогательный метод для безопасного преобразования в String
  static String _toString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  /// Вспомогательный метод для безопасного преобразования в double
  static double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Вспомогательный метод для безопасного преобразования в DateTime
  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() {
    return 'GoalModel(id: $id, name: $name, target: $targetAmount, current: $currentAmount, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  GoalType? get type => null;

  GoalPeriod? get period => null;

  String? get category => null;

  DateTime? get startDate => null;

  DateTime? get endDate => null;

  Color? get color => null;
}