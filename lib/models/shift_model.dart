import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShiftModel {
  final String id;
  final String name;
  final String category;
  final DateTime date;
  final bool isAllDay;
  final DateTime startTime;
  final DateTime endTime;
  final String paymentType; // 'hourly', 'perShift', 'unpaid'
  final double hourlyRate;
  final double paidTime;
  final double bonus;
  final double expenses;
  final double shiftRate;
  final bool isFilled;
  final Color color;
  final IconData icon;
  final String? emoji;
  final String? note;
  final DateTime createdAt;

  ShiftModel({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    this.isAllDay = false,
    required this.startTime,
    required this.endTime,
    this.paymentType = 'hourly',
    this.hourlyRate = 0.0,
    this.paidTime = 0.0,
    this.bonus = 0.0,
    this.expenses = 0.0,
    this.shiftRate = 0.0,
    this.isFilled = false,
    this.color = const Color(0xFF8b7ff5),
    this.icon = Icons.work_outline,
    this.emoji,
    this.note,
    required this.createdAt,
  });

  double get totalHours {
    Duration duration = endTime.difference(startTime);
    
    // если смена через полночь
    if (duration.isNegative) {
      duration = duration + const Duration(days: 1);
    }
    
    return duration.inMinutes / 60.0;
  }

  double get totalEarnings {
    if (paymentType == 'unpaid') return 0.0;
    
    double earnings = 0.0;
    if (paymentType == 'hourly') {
      final hoursToUse = paidTime > 0 ? paidTime : totalHours;
      earnings = hourlyRate * hoursToUse;
    } else if (paymentType == 'perShift') {
      earnings = shiftRate;
    }
    
    return earnings + bonus - expenses;
  }

  String get timeRange {
    if (isAllDay) return 'Весь день';
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  String getPaymentTypeLabel() {
    switch (paymentType) {
      case 'hourly':
        return 'Почасовая';
      case 'perShift':
        return 'За смену';
      case 'unpaid':
        return 'Без оплаты';
      default:
        return 'Неизвестно';
    }
  }

  // Копирование с изменениями
  ShiftModel copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? date,
    bool? isAllDay,
    DateTime? startTime,
    DateTime? endTime,
    String? paymentType,
    double? hourlyRate,
    double? paidTime,
    double? bonus,
    double? expenses,
    double? shiftRate,
    bool? isFilled,
    Color? color,
    IconData? icon,
    String? note,
    DateTime? createdAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      date: date ?? this.date,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      paymentType: paymentType ?? this.paymentType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      paidTime: paidTime ?? this.paidTime,
      bonus: bonus ?? this.bonus,
      expenses: expenses ?? this.expenses,
      shiftRate: shiftRate ?? this.shiftRate,
      isFilled: isFilled ?? this.isFilled,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'date': Timestamp.fromDate(date),
      'isAllDay': isAllDay,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'paymentType': paymentType,
      'hourlyRate': hourlyRate,
      'paidTime': paidTime,
      'bonus': bonus,
      'expenses': expenses,
      'shiftRate': shiftRate,
      'isFilled': isFilled,
      'color': color.value,
      'icon': icon.codePoint,
      'emoji': emoji,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Создание из Map (Firestore)
  factory ShiftModel.fromMap(String id, Map<String, dynamic> map) {
    return ShiftModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      isAllDay: map['isAllDay'] ?? false,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      paymentType: map['paymentType'] ?? 'hourly',
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      paidTime: (map['paidTime'] ?? 0.0).toDouble(),
      bonus: (map['bonus'] ?? 0.0).toDouble(),
      expenses: (map['expenses'] ?? 0.0).toDouble(),
      shiftRate: (map['shiftRate'] ?? 0.0).toDouble(),
      isFilled: map['isFilled'] ?? false,
      color: Color(map['color'] ?? 0xFF8b7ff5),
      icon: Icons.work_outline,
      emoji: map['emoji'],
      note: map['note'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Создание из DocumentSnapshot
  factory ShiftModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftModel.fromMap(doc.id, data);
  }
}

// Статистика по сменам
class ShiftStatistics {
  final int totalShifts;
  final double totalHours;
  final double totalEarnings;
  final double averageHoursPerShift;
  final double averageEarningsPerShift;
  final double averageHourlyRate;

  ShiftStatistics({
    required this.totalShifts,
    required this.totalHours,
    required this.totalEarnings,
  })  : averageHoursPerShift = totalShifts > 0 ? totalHours / totalShifts : 0,
        averageEarningsPerShift = totalShifts > 0 ? totalEarnings / totalShifts : 0,
        averageHourlyRate = totalHours > 0 ? totalEarnings / totalHours : 0;

  factory ShiftStatistics.fromShifts(List<ShiftModel> shifts) {
    if (shifts.isEmpty) {
      return ShiftStatistics(
        totalShifts: 0,
        totalHours: 0,
        totalEarnings: 0,
      );
    }

    double totalHours = 0;
    double totalEarnings = 0;

    for (var shift in shifts) {
      totalHours += shift.totalHours;
      totalEarnings += shift.totalEarnings;
    }

    return ShiftStatistics(
      totalShifts: shifts.length,
      totalHours: totalHours,
      totalEarnings: totalEarnings,
    );
  }
}