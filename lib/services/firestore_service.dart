import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ==================== НАСТРОЙКИ ПОЛЬЗОВАТЕЛЯ ====================
  
  // Получить настройки пользователя
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }
  
  // Обновить настройки пользователя
  Future<bool> updateUserSettings(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('Error updating user settings: $e');
      return false;
    }
  }
  
  // Стрим настроек пользователя
  Stream<DocumentSnapshot> getUserSettingsStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
  
  // ==================== ЗАДАЧИ ====================
  
  // Добавить задачу
  Future<String?> addTask(String userId, Map<String, dynamic> taskData) async {
    try {
      taskData['createdAt'] = FieldValue.serverTimestamp();
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add(taskData);
      return docRef.id;
    } catch (e) {
      print('Error adding task: $e');
      return null;
    }
  }
  
  // Получить все задачи пользователя
  Future<List<Map<String, dynamic>>> getTasks(String userId, DateTime startOfMonth, DateTime endOfMonth) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }
  
  // Стрим задач
  Stream<QuerySnapshot> getTasksStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Обновить задачу
  Future<bool> updateTask(String userId, String taskId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }
  
  // Удалить задачу
  Future<bool> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
  
  // ==================== ТРАНЗАКЦИИ ====================
  
  // Добавить транзакцию
  Future<String?> addTransaction(String userId, Map<String, dynamic> transactionData) async {
    try {
      transactionData['createdAt'] = FieldValue.serverTimestamp();
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(transactionData);
      return docRef.id;
    } catch (e) {
      print('Error adding transaction: $e');
      return null;
    }
  }
  
  // Получить все транзакции пользователя
  Future<List<Map<String, dynamic>>> getTransactions(String userId, DateTime startOfMonth, DateTime endOfMonth) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }
  
  // Стрим транзакций
  Stream<QuerySnapshot> getTransactionsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }
  
  // Получить транзакции за период
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting transactions by date: $e');
      return [];
    }
  }
  
  // Обновить транзакцию
  Future<bool> updateTransaction(String userId, String transactionId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }
  
  // Удалить транзакцию
  Future<bool> deleteTransaction(String userId, String transactionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }
  
  // ==================== СМЕНЫ ====================
  
  // Добавить смену
  Future<String?> addShift(String userId, Map<String, dynamic> shiftData) async {
    try {
      shiftData['createdAt'] = FieldValue.serverTimestamp();
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .add(shiftData);
      return docRef.id;
    } catch (e) {
      print('Error adding shift: $e');
      return null;
    }
  }
  
  // Получить все смены пользователя
  Future<List<Map<String, dynamic>>> getShifts(String userId, DateTime startOfMonth, DateTime endOfMonth) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting shifts: $e');
      return [];
    }
  }
  
  // Стрим смен
  Stream<QuerySnapshot> getShiftsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('shifts')
        .orderBy('date', descending: true)
        .snapshots();
  }
  
  // Получить смены за месяц
  Future<List<Map<String, dynamic>>> getShiftsByMonth(
    String userId,
    int year,
    int month,
  ) async {
    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error getting shifts by month: $e');
      return [];
    }
  }
  
  // Обновить смену
  Future<bool> updateShift(String userId, String shiftId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .doc(shiftId)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating shift: $e');
      return false;
    }
  }
  
  // Удалить смену
  Future<bool> deleteShift(String userId, String shiftId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .doc(shiftId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting shift: $e');
      return false;
    }
  }
  
  // ==================== СТАТИСТИКА ====================
  
  // Получить статистику за месяц
  Future<Map<String, dynamic>> getMonthlyStats(String userId, int year, int month) async {
    try {
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      // Получаем транзакции за месяц
      QuerySnapshot transactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      int totalIncome = 0;
      int totalExpense = 0;
      
      for (var doc in transactionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int amount = data['amount'] ?? 0;
        
        if (amount > 0) {
          totalIncome += amount;
        } else {
          totalExpense += amount.abs();
        }
      }
      
      // Получаем смены за месяц
      QuerySnapshot shiftsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      double totalHoursDouble = 0;
      int totalShifts = shiftsSnapshot.docs.length;

      for (var doc in shiftsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        try {
          final startTime = (data['startTime'] as Timestamp).toDate();
          final endTime = (data['endTime'] as Timestamp).toDate();
          totalHoursDouble += endTime.difference(startTime).inMinutes / 60.0;
        } catch (_) {}
      }
      int totalHours = totalHoursDouble.round();
      
      // Получаем задачи
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('isDone', isEqualTo: false)
          .get();
      
      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
        'totalHours': totalHours,
        'totalShifts': totalShifts,
        'activeTasks': tasksSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting monthly stats: $e');
      return {
        'totalIncome': 0,
        'totalExpense': 0,
        'balance': 0,
        'totalHours': 0,
        'totalShifts': 0,
        'activeTasks': 0,
      };
    }
  }

  // ==================== БУХГАЛТЕР: все сотрудники ====================

  /// Получить список всех пользователей с ролью employee
  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting employees: $e');
      return [];
    }
  }

  /// Получить смены конкретного сотрудника за месяц
  Future<List<Map<String, dynamic>>> getEmployeeShiftsByMonth(
    String employeeId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(employeeId)
          .collection('shifts')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting employee shifts: $e');
      return [];
    }
  }

  /// Сводный отчёт по всем сотрудникам за месяц
  Future<List<Map<String, dynamic>>> getMonthlyReportForAccountant(
    int year,
    int month,
  ) async {
    try {
      final employees = await getAllEmployees();
      final List<Map<String, dynamic>> report = [];

      for (final employee in employees) {
        final employeeId = employee['id'] as String;
        final shifts = await getEmployeeShiftsByMonth(employeeId, year, month);

        double totalHours = 0;
        double totalEarnings = 0;
        int shiftsCount = shifts.length;

        for (final shift in shifts) {
          try {
            final startTime = (shift['startTime'] as Timestamp).toDate();
            final endTime = (shift['endTime'] as Timestamp).toDate();
            final hours = endTime.difference(startTime).inMinutes / 60.0;
            totalHours += hours;

            final paymentType = shift['paymentType'] ?? 'hourly';
            if (paymentType == 'hourly') {
              final rate = (shift['hourlyRate'] ?? 0.0).toDouble();
              final paid = (shift['paidTime'] ?? 0.0).toDouble();
              totalEarnings += rate * (paid > 0 ? paid : hours);
            } else if (paymentType == 'perShift') {
              totalEarnings += (shift['shiftRate'] ?? 0.0).toDouble();
            }
            totalEarnings += (shift['bonus'] ?? 0.0).toDouble();
            totalEarnings -= (shift['expenses'] ?? 0.0).toDouble();
          } catch (_) {}
        }

        report.add({
          'employeeId': employeeId,
          'name': employee['name'] ?? 'Без имени',
          'email': employee['email'] ?? '',
          'totalHours': totalHours,
          'totalEarnings': totalEarnings,
          'shiftsCount': shiftsCount,
          'shifts': shifts,
        });
      }

      return report;
    } catch (e) {
      print('Error getting monthly report: $e');
      return [];
    }
  }
}