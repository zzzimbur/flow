import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/template_model.dart';

class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить все шаблоны пользователя
  Future<List<TemplateModel>> getTemplates(String userId, {TemplateType? type}) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('templates')
          .orderBy('updatedAt', descending: true);

      // Фильтр по типу если указан
      if (type != null) {
        final typeString = _typeToString(type);
        query = query.where('type', isEqualTo: typeString);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => TemplateModel.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Ошибка загрузки шаблонов: $e');
      return [];
    }
  }

  // Сохранить новый шаблон
  Future<String?> saveTemplate({
    required String userId,
    required String name,
    required TemplateType type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final now = DateTime.now();
      final template = TemplateModel(
        id: '',
        name: name,
        type: type,
        data: data,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('templates')
          .add(template.toMap());

      return docRef.id;
    } catch (e) {
      print('Ошибка сохранения шаблона: $e');
      return null;
    }
  }

  // Обновить шаблон
  Future<bool> updateTemplate({
    required String userId,
    required String templateId,
    String? name,
    Map<String, dynamic>? data,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (data != null) updates['data'] = data;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('templates')
          .doc(templateId)
          .update(updates);

      return true;
    } catch (e) {
      print('Ошибка обновления шаблона: $e');
      return false;
    }
  }

  // Удалить шаблон
  Future<bool> deleteTemplate(String userId, String templateId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('templates')
          .doc(templateId)
          .delete();

      return true;
    } catch (e) {
      print('Ошибка удаления шаблона: $e');
      return false;
    }
  }

  // Получить один шаблон
  Future<TemplateModel?> getTemplate(String userId, String templateId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('templates')
          .doc(templateId)
          .get();

      if (doc.exists) {
        return TemplateModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка загрузки шаблона: $e');
      return null;
    }
  }

  // Stream для отслеживания шаблонов в реальном времени
  Stream<List<TemplateModel>> templatesStream(String userId, {TemplateType? type}) {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('templates')
        .orderBy('updatedAt', descending: true);

    if (type != null) {
      final typeString = _typeToString(type);
      query = query.where('type', isEqualTo: typeString);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TemplateModel.fromSnapshot(doc)).toList();
    });
  }

  // Вспомогательный метод для конвертации типа
  String _typeToString(TemplateType type) {
    switch (type) {
      case TemplateType.shift:
        return 'shift';
      case TemplateType.task:
        return 'task';
      case TemplateType.transaction:
        return 'transaction';
    }
  }

  // Создать шаблон из смены
  Future<String?> createTemplateFromShift({
    required String userId,
    required String name,
    required Map<String, dynamic> shiftData,
  }) async {
    // Убираем поля которые не должны быть в шаблоне
    final templateData = Map<String, dynamic>.from(shiftData);
    templateData.remove('id');
    templateData.remove('date');
    templateData.remove('startTime');
    templateData.remove('endTime');
    templateData.remove('createdAt');

    return await saveTemplate(
      userId: userId,
      name: name,
      type: TemplateType.shift,
      data: templateData,
    );
  }

  // Создать шаблон из задачи
  Future<String?> createTemplateFromTask({
    required String userId,
    required String name,
    required Map<String, dynamic> taskData,
  }) async {
    final templateData = Map<String, dynamic>.from(taskData);
    templateData.remove('id');
    templateData.remove('date');
    templateData.remove('startTime');
    templateData.remove('endTime');
    templateData.remove('createdAt');
    templateData.remove('isDone');

    return await saveTemplate(
      userId: userId,
      name: name,
      type: TemplateType.task,
      data: templateData,
    );
  }

  // Создать шаблон из транзакции
  Future<String?> createTemplateFromTransaction({
    required String userId,
    required String name,
    required Map<String, dynamic> transactionData,
  }) async {
    final templateData = Map<String, dynamic>.from(transactionData);
    templateData.remove('id');
    templateData.remove('date');
    templateData.remove('createdAt');
    templateData.remove('amount'); // Сумму не сохраняем

    return await saveTemplate(
      userId: userId,
      name: name,
      type: TemplateType.transaction,
      data: templateData,
    );
  }
}