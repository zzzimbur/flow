import 'package:cloud_firestore/cloud_firestore.dart';

enum TemplateType {
  shift,
  task,
  transaction,
}

class TemplateModel {
  final String id;
  final String name;
  final TemplateType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  TemplateModel({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  // Создание из Firestore
  factory TemplateModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TemplateModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: _typeFromString(data['type'] ?? 'shift'),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': _typeToString(type),
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Копирование с изменениями
  TemplateModel copyWith({
    String? id,
    String? name,
    TemplateType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Получить иконку для типа
  static String getIconForType(TemplateType type) {
    switch (type) {
      case TemplateType.shift:
        return '💼';
      case TemplateType.task:
        return '✅';
      case TemplateType.transaction:
        return '💰';
    }
  }

  // Получить название типа
  static String getNameForType(TemplateType type) {
    switch (type) {
      case TemplateType.shift:
        return 'Смена';
      case TemplateType.task:
        return 'Задача';
      case TemplateType.transaction:
        return 'Операция';
    }
  }

  // Вспомогательные методы для конвертации типа
  static TemplateType _typeFromString(String typeString) {
    switch (typeString) {
      case 'shift':
        return TemplateType.shift;
      case 'task':
        return TemplateType.task;
      case 'transaction':
        return TemplateType.transaction;
      default:
        return TemplateType.shift;
    }
  }

  static String _typeToString(TemplateType type) {
    switch (type) {
      case TemplateType.shift:
        return 'shift';
      case TemplateType.task:
        return 'task';
      case TemplateType.transaction:
        return 'transaction';
    }
  }
}