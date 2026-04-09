import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final DateTime date;
  final DateTime? startTime; 
  final DateTime? endTime;  
  final String priority; // 'none', 'low', 'medium', 'high'
  final String category;
  final bool isDone;
  final List<SubtaskModel> subtasks;
  final bool hasReminder;
  final String repeatType; // 'none', 'daily', 'weekly', 'monthly'
  final String? note;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.priority = 'none',
    required this.category,
    this.isDone = false,
    this.subtasks = const [],
    this.hasReminder = false,
    this.repeatType = 'none',
    this.note,
    required this.createdAt,
  });

  // Геттеры для удобства
  int get completedSubtasks => subtasks.where((s) => s.isDone).length;
  int get totalSubtasks => subtasks.length;
  bool get hasSubtasks => subtasks.isNotEmpty;
  double get progress => hasSubtasks ? completedSubtasks / totalSubtasks : (isDone ? 1.0 : 0.0);
  
  // геттер: есть ли временной диапазон
  bool get hasTimeRange => startTime != null && endTime != null;
  
  // геттер: строка времени
  String get timeRangeString {
    if (!hasTimeRange) {
      if (startTime != null) {
        return '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
      }
      return '';
    }
    final start = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
    final end = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
  
  // Обратная совместимость
  DateTime? get time => startTime;

  Color getPriorityColor() {
    switch (priority) {
      case 'high':
        return const Color(0xFFef4444);
      case 'medium':
        return const Color(0xFFf59e0b);
      case 'low':
        return const Color(0xFF3b82f6);
      default:
        return const Color(0xFF94a3b8);
    }
  }

  IconData getPriorityIcon() {
    if (isDone) return Icons.check_circle;
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.flag;
      case 'low':
        return Icons.flag_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  String getPriorityLabel() {
    switch (priority) {
      case 'high':
        return 'Высокий';
      case 'medium':
        return 'Средний';
      case 'low':
        return 'Низкий';
      default:
        return 'Без приоритета';
    }
  }

  String getRepeatLabel() {
    switch (repeatType) {
      case 'daily':
        return 'Ежедневно';
      case 'weekly':
        return 'Еженедельно';
      case 'monthly':
        return 'Ежемесячно';
      default:
        return 'Не повторять';
    }
  }

  // Копирование с изменениями
  TaskModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? priority,
    String? category,
    bool? isDone,
    List<SubtaskModel>? subtasks,
    bool? hasReminder,
    String? repeatType,
    String? note,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      subtasks: subtasks ?? this.subtasks,
      hasReminder: hasReminder ?? this.hasReminder,
      repeatType: repeatType ?? this.repeatType,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'priority': priority,
      'category': category,
      'isDone': isDone,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'hasReminder': hasReminder,
      'repeatType': repeatType,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Создание из Map (Firestore)
  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] != null ? (map['startTime'] as Timestamp).toDate() : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      priority: map['priority'] ?? 'none',
      category: map['category'] ?? 'Работа',
      isDone: map['isDone'] ?? false,
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => SubtaskModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      hasReminder: map['hasReminder'] ?? false,
      repeatType: map['repeatType'] ?? 'none',
      note: map['note'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Создание из DocumentSnapshot
  factory TaskModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel.fromMap(doc.id, data);
  }
}

class SubtaskModel {
  final String title;
  bool isDone;

  SubtaskModel({
    required this.title,
    required this.isDone,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
    };
  }

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }

  SubtaskModel copyWith({
    String? title,
    bool? isDone,
  }) {
    return SubtaskModel(
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}