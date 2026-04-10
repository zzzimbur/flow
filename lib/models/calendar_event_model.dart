import 'package:flutter/material.dart';

enum CalendarEventType {
  shift,
  task,
  transaction,
}

abstract class CalendarEvent {
  final String id;
  final String title;
  DateTime get startTime;
  DateTime? get endTime; //null для точечных событий
  final DateTime date;
  final CalendarEventType type;
  final Color color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.color,
  });

  // Метод для получения времени события (если есть)
  String? getTimeString();
  
  // Метод для получения описания события
  String getDescription();
  
  // Метод для получения иконки события
  IconData getIcon();
  
  // Копирование события с новой датой
  CalendarEvent copyWithDate(DateTime newDate);
}

class ShiftEvent extends CalendarEvent {
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final double hourlyRate;
  final double paidTime;
  final double bonus;
  final double expenses;
  final double shiftRate;
  final String paymentType;
  final bool isFilled;
  final IconData icon;
  final String? note;

  ShiftEvent({
    required String id,
    required String title,
    required DateTime date,
    required Color color,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.hourlyRate = 0.0,
    this.paidTime = 0.0,
    this.bonus = 0.0,
    this.expenses = 0.0,
    this.shiftRate = 0.0,
    this.paymentType = 'hourly',
    this.isFilled = false,
    this.icon = Icons.work_outline,
    this.note,
  }) : super(
          id: id,
          title: title,
          date: date,
          type: CalendarEventType.shift,
          color: color,
        );

  double get totalHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  double get totalEarnings {
    double earnings = 0.0;
    if (paymentType == 'hourly') {
      earnings = hourlyRate * (paidTime > 0 ? paidTime : totalHours);
    } else if (paymentType == 'perShift') {
      earnings = shiftRate;
    }
    return earnings + bonus - expenses;
  }

  @override
  String? getTimeString() {
    if (isAllDay) return 'Весь день';
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  @override
  String getDescription() {
    return '${totalHours.toStringAsFixed(1)}ч • ₽${totalEarnings.toStringAsFixed(0)}';
  }

  @override
  IconData getIcon() => icon;

  @override
  ShiftEvent copyWithDate(DateTime newDate) {
    final timeDiff = startTime.difference(date);
    return ShiftEvent(
      id: id,
      title: title,
      date: newDate,
      color: color,
      category: category,
      startTime: newDate.add(timeDiff),
      endTime: newDate.add(endTime.difference(date)),
      isAllDay: isAllDay,
      hourlyRate: hourlyRate,
      paidTime: paidTime,
      bonus: bonus,
      expenses: expenses,
      shiftRate: shiftRate,
      paymentType: paymentType,
      isFilled: isFilled,
      icon: icon,
      note: note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'category': category,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay,
      'hourlyRate': hourlyRate,
      'paidTime': paidTime,
      'bonus': bonus,
      'expenses': expenses,
      'shiftRate': shiftRate,
      'paymentType': paymentType,
      'isFilled': isFilled,
      'color': color.value,
      'icon': icon.codePoint,
      'note': note,
    };
  }

  factory ShiftEvent.fromMap(Map<String, dynamic> map) {
    return ShiftEvent(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      color: Color(map['color']),
      category: map['category'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      isAllDay: map['isAllDay'] ?? false,
      hourlyRate: map['hourlyRate']?.toDouble() ?? 0.0,
      paidTime: map['paidTime']?.toDouble() ?? 0.0,
      bonus: map['bonus']?.toDouble() ?? 0.0,
      expenses: map['expenses']?.toDouble() ?? 0.0,
      shiftRate: map['shiftRate']?.toDouble() ?? 0.0,
      paymentType: map['paymentType'] ?? 'hourly',
      isFilled: map['isFilled'] ?? false,
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      note: map['note'],
    );
  }
}

class TaskEvent extends CalendarEvent {
  final DateTime? time;
  final String priority;
  final String category;
  final bool isDone;
  final List<Subtask> subtasks;
  final bool hasReminder;
  final String repeatType;
  final String? note;

  TaskEvent({
    required String id,
    required String title,
    required DateTime date,
    required Color color,
    this.time,
    this.priority = 'none',
    required this.category,
    this.isDone = false,
    this.subtasks = const [],
    this.hasReminder = false,
    this.repeatType = 'none',
    this.note,
  }) : super(
          id: id,
          title: title,
          date: date,
          type: CalendarEventType.task,
          color: color,
        );

  int get completedSubtasks => subtasks.where((s) => s.isDone).length;
  int get totalSubtasks => subtasks.length;
  bool get hasSubtasks => subtasks.isNotEmpty;
  double get progress => hasSubtasks ? completedSubtasks / totalSubtasks : (isDone ? 1.0 : 0.0);

  @override
  String? getTimeString() {
    if (time == null) return null;
    return '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
  }

  @override
  String getDescription() {
    if (hasSubtasks) {
      return '$completedSubtasks/$totalSubtasks подзадач';
    }
    return category;
  }

  @override
  IconData getIcon() {
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

  @override
  TaskEvent copyWithDate(DateTime newDate) {
    DateTime? newTime;
    if (time != null) {
      newTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        time!.hour,
        time!.minute,
      );
    }
    
    return TaskEvent(
      id: id,
      title: title,
      date: newDate,
      color: color,
      time: newTime,
      priority: priority,
      category: category,
      isDone: isDone,
      subtasks: subtasks,
      hasReminder: hasReminder,
      repeatType: repeatType,
      note: note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'time': time?.toIso8601String(),
      'priority': priority,
      'category': category,
      'isDone': isDone,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'hasReminder': hasReminder,
      'repeatType': repeatType,
      'note': note,
      'color': color.value,
    };
  }

  factory TaskEvent.fromMap(Map<String, dynamic> map) {
    return TaskEvent(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      color: Color(map['color'] ?? 0xFF3b82f6),
      time: map['time'] != null ? DateTime.parse(map['time']) : null,
      priority: map['priority'] ?? 'none',
      category: map['category'],
      isDone: map['isDone'] ?? false,
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      hasReminder: map['hasReminder'] ?? false,
      repeatType: map['repeatType'] ?? 'none',
      note: map['note'],
    );
  }
  
  @override
  DateTime get startTime {
    if (time != null) return time!;
    return DateTime(date.year, date.month, date.day, 0, 0);
  }

  @override
  DateTime? get endTime {
    if (time != null) return time!.add(const Duration(hours: 1));
    return null;
  }
}

class Subtask {
  final String title;
  bool isDone;

  Subtask({
    required this.title,
    required this.isDone,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      title: map['title'],
      isDone: map['isDone'] ?? false,
    );
  }
}