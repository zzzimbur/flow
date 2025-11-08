import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'dart:math' as math;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const FlowApp(),
    ),
  );
}

// ENUMS
enum TaskType { paid, personal, admin }
enum Priority { high, medium, low }
enum TransactionType { income, expense }
enum PaymentType { hourly, perShift, unpaid }
enum AppTheme { light, dark, ocean, sunset, forest }

// MODELS
class Task {
  final String id;
  String title;
  String description;
  DateTime deadline;
  Priority priority;
  bool isDone;
  Color color;
  IconData icon;
  String? notes;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isDone,
    this.color = Colors.blue,
    this.icon = Icons.task_alt,
    this.notes,
  });
}

class Transaction {
  final String id;
  TransactionType type;
  double amount;
  String category;
  String description;
  DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });
}

class ExpenseCategory {
  final String name;
  double spent;
  double budget;
  Color color;

  ExpenseCategory({
    required this.name,
    required this.spent,
    required this.budget,
    required this.color,
  });

  double get remaining => budget - spent;
}

class WorkShift {
  final String id;
  DateTime date;
  String startTime;
  String endTime;
  String title;
  String? category;
  PaymentType paymentType;
  double? hourlyRate;
  double? shiftRate;
  double? bonus;
  double? expenses;
  Color color;
  IconData icon;
  String? notes;
  bool isAllDay;

  WorkShift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.category,
    required this.paymentType,
    this.hourlyRate,
    this.shiftRate,
    this.bonus,
    this.expenses,
    this.color = Colors.blue,
    this.icon = Icons.work,
    this.notes,
    this.isAllDay = false,
  });

  double get totalEarnings {
    if (paymentType == PaymentType.unpaid) return 0;
    
    double base = 0;
    if (paymentType == PaymentType.hourly && hourlyRate != null) {
      base = hours * hourlyRate!;
    } else if (paymentType == PaymentType.perShift && shiftRate != null) {
      base = shiftRate!;
    }
    
    return base + (bonus ?? 0) - (expenses ?? 0);
  }

  double get hours {
    if (isAllDay) return 24;
    
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    if (end.isBefore(start)) {
      return 24 - start.hour + end.hour + (end.minute - start.minute) / 60;
    }
    
    return (end.hour - start.hour) + (end.minute - start.minute) / 60;
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }
}

// STATE MANAGEMENT
class AppState extends ChangeNotifier {
  String userName = '';
  String userEmail = '';
  bool notifications = true;
  AppTheme currentTheme = AppTheme.light;
  String currency = 'RUB';
  
  final List<Task> _tasks = [];
  final List<Transaction> _transactions = [];
  final List<WorkShift> _shifts = [];
  final List<ExpenseCategory> _expenseCategories = [];

  DateTime statsStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime statsEndDate = DateTime.now();

  // TASKS
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _tasks.where((t) => 
    t.deadline.day == DateTime.now().day &&
    t.deadline.month == DateTime.now().month &&
    !t.isDone
  ).toList();
  List<Task> get activeTasks => _tasks.where((t) => !t.isDone).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isDone).toList();

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void toggleTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isDone = !task.isDone;
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // TRANSACTIONS
  List<Transaction> get transactions => _transactions;
  
  double getBalance({DateTime? start, DateTime? end}) {
    final filtered = _filterByDate(_transactions, start, end);
    double total = 0;
    for (var t in filtered) {
      total += t.type == TransactionType.income ? t.amount : -t.amount;
    }
    return total;
  }

  double getIncome({DateTime? start, DateTime? end}) {
    final filtered = _filterByDate(_transactions, start, end);
    return filtered
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);
  }

  double getExpense({DateTime? start, DateTime? end}) {
    final filtered = _filterByDate(_transactions, start, end);
    return filtered
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);
  }

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    notifyListeners();
  }

  // EXPENSE CATEGORIES
  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  void addExpenseCategory(ExpenseCategory category) {
    _expenseCategories.add(category);
    notifyListeners();
  }

  // WORK SHIFTS
  List<WorkShift> get shifts => _shifts;
  
  List<WorkShift> getShifts({DateTime? start, DateTime? end}) {
    return _filterByDate(_shifts, start, end);
  }

  double getTotalEarnings({DateTime? start, DateTime? end}) {
    final filtered = getShifts(start: start, end: end);
    return filtered.fold(0, (sum, shift) => sum + shift.totalEarnings);
  }

  double getTotalHours({DateTime? start, DateTime? end}) {
    final filtered = getShifts(start: start, end: end);
    return filtered.fold(0, (sum, shift) => sum + shift.hours);
  }

  int getShiftCount({DateTime? start, DateTime? end}) {
    return getShifts(start: start, end: end).length;
  }

  void addShift(WorkShift shift) {
    _shifts.add(shift);
    notifyListeners();
  }

  void deleteShift(String id) {
    _shifts.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<WorkShift> todayShifts(DateTime date) {
    return _shifts.where((s) => 
      s.date.day == date.day &&
      s.date.month == date.month &&
      s.date.year == date.year
    ).toList();
  }

  // SETTINGS
  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }

  void updateUserEmail(String email) {
    userEmail = email;
    notifyListeners();
  }

  void toggleNotifications() {
    notifications = !notifications;
    notifyListeners();
  }

  void changeTheme(AppTheme theme) {
    currentTheme = theme;
    notifyListeners();
  }

  void changeCurrency(String curr) {
    currency = curr;
    notifyListeners();
  }

  void updateStatsDateRange(DateTime start, DateTime end) {
    statsStartDate = start;
    statsEndDate = end;
    notifyListeners();
  }

  // HELPERS
  List<T> _filterByDate<T>(List<T> items, DateTime? start, DateTime? end) {
    if (start == null && end == null) return items;
    
    return items.where((item) {
      DateTime date;
      if (item is Transaction) {
        date = item.date;
      } else if (item is WorkShift) {
        date = item.date;
      } else {
        return true;
      }
      
      if (start != null && date.isBefore(start)) return false;
      if (end != null && date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  String get currencySymbol {
    switch (currency) {
      case 'RUB': return '₽';
      case 'USD': return '\$';
      case 'EUR': return '€';
      default: return '₽';
    }
  }
}

// MAIN APP
class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().currentTheme;
    
    return MaterialApp(
      title: 'Flow',
      theme: _getThemeData(theme),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          brightness: Brightness.light,
          useMaterial3: true,
        );
      case AppTheme.dark:
        return ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF111827),
          brightness: Brightness.dark,
          useMaterial3: true,
        );
      case AppTheme.ocean:
        return ThemeData(
          primarySwatch: Colors.cyan,
          scaffoldBackgroundColor: const Color(0xFFECFEFF),
          brightness: Brightness.light,
          useMaterial3: true,
        );
      case AppTheme.sunset:
        return ThemeData(
          primarySwatch: Colors.deepOrange,
          scaffoldBackgroundColor: const Color(0xFFFFF7ED),
          brightness: Brightness.light,
          useMaterial3: true,
        );
      case AppTheme.forest:
        return ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF0FDF4),
          brightness: Brightness.light,
          useMaterial3: true,
        );
    }
  }
}

// MAIN SCREEN
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FinanceScreen(),
    TasksScreen(),
    ScheduleScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Главная', isDark),
                _buildNavItem(1, Icons.attach_money_rounded, 'Финансы', isDark),
                _buildNavItem(2, Icons.check_box_rounded, 'Задачи', isDark),
                _buildNavItem(3, Icons.calendar_today_rounded, 'График', isDark),
                _buildNavItem(4, Icons.settings_rounded, 'Еще', isDark),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: Colors.blue,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Colors.blue 
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.blue 
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddMenuSheet(),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayTasks = state.todayTasks;
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime.now();
    
    final monthEarnings = state.getTotalEarnings(start: monthStart, end: monthEnd);
    final monthHours = state.getTotalHours(start: monthStart, end: monthEnd);
    final monthGoal = 150000.0;
    final remaining = monthGoal - monthEarnings;

    // Проверка на пустые данные
    final hasData = state.shifts.isNotEmpty || state.tasks.isNotEmpty || state.transactions.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.userName.isEmpty 
                  ? 'Добро пожаловать! 👋' 
                  : 'Доброе утро, ${state.userName} 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            if (!hasData) ...[
              // Пустое состояние
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.lightbulb_outline,
                      size: 80,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Начните работу с Flow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Добавьте первую задачу, смену или финансовую операцию, чтобы начать отслеживать свою продуктивность',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMenu(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Создать первую запись'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Основной контент
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'За месяц',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${monthHours.toStringAsFixed(1)} ч',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Заработано',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${state.currencySymbol}${_formatNumber(monthEarnings.toInt())}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Задач сегодня',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${todayTasks.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Смен',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.getShiftCount(start: monthStart, end: monthEnd)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (todayTasks.isNotEmpty) ...[
                const Text(
                  'Задачи на сегодня',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...todayTasks.take(3).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskItemWidget(task: task, compact: true),
                )),
                const SizedBox(height: 24),
              ],

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Цель на месяц: ${state.currencySymbol}${_formatNumber(monthGoal.toInt())}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (monthEarnings / monthGoal).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: isDark 
                            ? const Color(0xFF374151) 
                            : const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${state.currencySymbol}${_formatNumber(monthEarnings.toInt())} / осталось: ${state.currencySymbol}${_formatNumber(remaining.toInt())}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddMenuSheet(),
    );
  }
}

// Продолжение следует... (TaskItemWidget, FinanceScreen, TasksScreen, ScheduleScreen, SettingsScreen, AddMenuSheet и вспомогательные функции)

// TASK ITEM WIDGET
class TaskItemWidget extends StatelessWidget {
  final Task task;
  final bool compact;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => state.toggleTask(task.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isDone ? task.color : task.color.withOpacity(0.5),
                  width: 2,
                ),
                color: task.isDone ? task.color : Colors.transparent,
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: task.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(task.icon, size: 20, color: task.color),
        ],
      ),
    );
  }
}

// Placeholder screens for brevity - add full implementations
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool showHistory = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime.now();

    final income = state.getIncome(start: monthStart, end: monthEnd);
    final expense = state.getExpense(start: monthStart, end: monthEnd);
    final balance = income - expense;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header с кнопкой истории
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Финансы',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => showHistory = !showHistory),
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(showHistory ? 'Скрыть' : 'История'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Тёмная карточка баланса
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                      : [const Color(0xFF1F2937), const Color(0xFF111827)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Баланс',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.currencySymbol}${_formatNumber(balance.toInt())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Доходы',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${state.currencySymbol}${_formatNumber(income.toInt())}',
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Расходы',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '-${state.currencySymbol}${_formatNumber(expense.toInt())}',
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Две карточки доход/расход
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ДОХОД',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.currencySymbol}${_formatNumber(income.toInt())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'РАСХОДЫ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.currencySymbol}${_formatNumber(expense.toInt())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Категории расходов
            if (state.expenseCategories.isNotEmpty) ...[
              const Text(
                'Категории расходов',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...state.expenseCategories.map((category) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${state.currencySymbol}${_formatNumber(category.spent.toInt())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (category.spent / category.budget).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: isDark 
                            ? const Color(0xFF374151) 
                            : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(category.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Потрачено: ${state.currencySymbol}${_formatNumber(category.spent.toInt())} / Осталось: ${state.currencySymbol}${_formatNumber(category.remaining.toInt())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            // История операций (показывается только при showHistory = true)
            if (showHistory) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'История операций',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => _showDateRangePicker(context, state),
                    child: const Text('Период'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Нет операций',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                ...state.transactions.map((transaction) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${transaction.type == TransactionType.income ? '+' : '-'}${state.currencySymbol}${_formatNumber(transaction.amount.toInt())}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: transaction.type == TransactionType.income
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                )),
            ],
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, AppState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.statsStartDate,
        end: state.statsEndDate,
      ),
    );
    
    if (picked != null) {
      state.updateStatsDateRange(picked.start, picked.end);
    }
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class AddShiftSheet extends StatefulWidget {
  const AddShiftSheet({super.key});

  @override
  State<AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<AddShiftSheet> {
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final hourlyRateController = TextEditingController();
  final shiftRateController = TextEditingController();
  final bonusController = TextEditingController();
  final expensesController = TextEditingController();
  
  int startHour = 9;
  int startMinute = 0;
  int endHour = 17;
  int endMinute = 0;
  
  PaymentType paymentType = PaymentType.hourly;
  bool isAllDay = false;
  Color selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Новая смена',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Название',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        hintText: 'Категория (необязательно)',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Переключатель "Весь день"
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text('Весь день'),
                        value: isAllDay,
                        onChanged: (value) => setState(() => isAllDay = value),
                        activeColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    // iOS-стиль барабаны времени
                    if (!isAllDay) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showIOSTimePicker(
                                context,
                                startHour,
                                startMinute,
                                (hour, minute) {
                                  setState(() {
                                    startHour = hour;
                                    startMinute = minute;
                                  });
                                },
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Начало',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showIOSTimePicker(
                                context,
                                endHour,
                                endMinute,
                                (hour, minute) {
                                  setState(() {
                                    endHour = hour;
                                    endMinute = minute;
                                  });
                                },
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Конец',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Тип оплаты:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    
                    // Красивый переключатель типа оплаты
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildPaymentTypeButton('Почасовая', PaymentType.hourly),
                          _buildPaymentTypeButton('За смену', PaymentType.perShift),
                          _buildPaymentTypeButton('Без оплаты', PaymentType.unpaid),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    if (paymentType == PaymentType.hourly)
                      TextField(
                        controller: hourlyRateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Почасовая ставка',
                          prefixText: '${state.currencySymbol} ',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    if (paymentType == PaymentType.perShift)
                      TextField(
                        controller: shiftRateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Оплата за смену',
                          prefixText: '${state.currencySymbol} ',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    
                    if (paymentType != PaymentType.unpaid) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: bonusController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Доплата (необязательно)',
                          prefixText: '${state.currencySymbol} ',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: expensesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Расходы (необязательно)',
                          prefixText: '${state.currencySymbol} ',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildColorOption(Colors.blue),
                        _buildColorOption(Colors.red),
                        _buildColorOption(Colors.green),
                        _buildColorOption(Colors.orange),
                        _buildColorOption(Colors.purple),
                        _buildColorOption(Colors.pink),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Кнопка создать
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final shift = WorkShift(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: DateTime.now(),
                        startTime: '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}',
                        endTime: '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
                        title: titleController.text,
                        category: categoryController.text.isEmpty ? null : categoryController.text,
                        paymentType: paymentType,
                        hourlyRate: hourlyRateController.text.isEmpty ? null : double.tryParse(hourlyRateController.text),
                        shiftRate: shiftRateController.text.isEmpty ? null : double.tryParse(shiftRateController.text),
                        bonus: bonusController.text.isEmpty ? null : double.tryParse(bonusController.text),
                        expenses: expensesController.text.isEmpty ? null : double.tryParse(expensesController.text),
                        color: selectedColor,
                        icon: Icons.work,
                        isAllDay: isAllDay,
                      );
                      state.addShift(shift);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📅 Смена добавлена!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Создать',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeButton(String label, PaymentType type) {
    final isSelected = paymentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => paymentType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selectedColor == color
              ? Border.all(color: Colors.white, width: 4)
              : null,
          boxShadow: selectedColor == color
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
      ),
    );
  }

  // iOS-стиль барабан времени
  void _showIOSTimePicker(
    BuildContext context,
    int initialHour,
    int initialMinute,
    Function(int, int) onTimeSelected,
  ) {
    int selectedHour = initialHour;
    int selectedMinute = initialMinute;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        onTimeSelected(selectedHour, selectedMinute);
                        Navigator.pop(context);
                      },
                      child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: initialHour),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          selectedHour = index;
                        },
                        children: List.generate(24, (index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: initialMinute),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          selectedMinute = index;
                        },
                        children: List.generate(60, (index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 22),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  Color selectedColor = Colors.blue;
  final List<Color> colors = [
    const Color(0xFF007AFF), // iOS Blue
    const Color(0xFFFF3B30), // iOS Red
    const Color(0xFF34C759), // iOS Green
    const Color(0xFFFF9500), // iOS Orange
    const Color(0xFFAF52DE), // iOS Purple
    const Color(0xFFFF2D55), // iOS Pink
    const Color(0xFF5856D6), // iOS Indigo
    const Color(0xFFFFCC00), // iOS Yellow
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Новая задача',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Цвет с большими кружками
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: colors.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final color = colors[index];
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 32,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Название
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: titleController,
                        style: TextStyle(
                          fontSize: 17,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Название задачи',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Описание
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: descController,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Добавьте описание...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопка создать
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            selectedColor,
                            selectedColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (titleController.text.isNotEmpty) {
                              final task = Task(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleController.text,
                                description: descController.text,
                                deadline: DateTime.now(),
                                priority: Priority.medium,
                                isDone: false,
                                color: selectedColor,
                                icon: Icons.circle,
                              );
                              state.addTask(task);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('✨ Задача создана!'),
                                  backgroundColor: selectedColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              'Создать задачу',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksScreenState extends State<TasksScreen> {
  String selectedFilter = 'today';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    List<Task> filteredTasks;
    switch (selectedFilter) {
      case 'today':
        filteredTasks = state.todayTasks;
        break;
      case 'all':
        filteredTasks = state.tasks;
        break;
      case 'done':
        filteredTasks = state.completedTasks;
        break;
      default:
        filteredTasks = state.tasks;
    }

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Задачи',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddTaskSheet(context),
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // Фильтры в виде чипсов
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Сегодня', 'today', state.todayTasks.length, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Все', 'all', state.tasks.length, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Выполнено', 'done', state.completedTasks.length, isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Список задач
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет задач',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddTaskSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Создать задачу'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(filteredTasks[index].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            state.deleteTask(filteredTasks[index].id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Задача удалена')),
                            );
                          },
                          child: TaskItemWidget(task: filteredTasks[index]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count, bool isDark) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue 
              : (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddTaskSheet(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool showStats = false;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayShifts = state.todayShifts(selectedDate);
    final totalHours = todayShifts.fold(0.0, (sum, s) => sum + s.hours);
    final totalEarnings = todayShifts.fold(0.0, (sum, s) => sum + s.totalEarnings);

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime.now();
    final monthEarnings = state.getTotalEarnings(start: monthStart, end: monthEnd);
    final monthHours = state.getTotalHours(start: monthStart, end: monthEnd);
    final monthShifts = state.getShiftCount(start: monthStart, end: monthEnd);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'График работы',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Статистика'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Статистика (показывается при showStats = true)
            if (showStats) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Статистика работы',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showDateRangePicker(context, state),
                          child: const Text('Период'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Заработано за месяц:', 
                        '${state.currencySymbol}${_formatNumber(monthEarnings.toInt())}', 
                        Colors.green, isDark),
                    const SizedBox(height: 12),
                    _buildStatRow('Отработано часов:', 
                        '${monthHours.toStringAsFixed(1)} ч', 
                        Colors.blue, isDark),
                    const SizedBox(height: 12),
                    _buildStatRow('Количество смен:', 
                        '$monthShifts', 
                        Colors.purple, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Календарь недели
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMonth(selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() => selectedDate = DateTime.now()),
                            child: const Text('Сегодня'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.blue,
                            onPressed: () => _showAddShiftSheet(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _buildWeekDays(isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Смены на выбранный день
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (todayShifts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalHours.toStringAsFixed(1)}ч',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${state.currencySymbol}${_formatNumber(totalEarnings.toInt())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (todayShifts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет записей на этот день',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showAddShiftSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить смену'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...todayShifts.map((shift) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: shift.color.withOpacity(0.1),
                  border: Border.all(color: shift.color.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: shift.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(shift.icon, size: 20, color: shift.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shift.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: shift.color,
                            ),
                          ),
                        ),
                        Text(
                          '${state.currencySymbol}${_formatNumber(shift.totalEarnings.toInt())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: shift.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: shift.color),
                        const SizedBox(width: 4),
                        Text(
                          shift.isAllDay 
                              ? 'Весь день' 
                              : '${shift.startTime} - ${shift.endTime}',
                          style: TextStyle(fontSize: 13, color: shift.color),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${shift.hours.toStringAsFixed(1)}ч',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: shift.color,
                          ),
                        ),
                      ],
                    ),
                    if (shift.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        shift.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: shift.color.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWeekDays(bool isDark) {
    const weekDays = ['М', 'Т', 'С', 'Ч', 'П', 'С', 'В'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final isSelected = date.day == selectedDate.day &&
          date.month == selectedDate.month;
      final isToday = date.day == now.day && date.month == now.month;

      return GestureDetector(
        onTap: () => setState(() => selectedDate = date),
        child: Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.blue 
                : (isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekDays[index],
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.grey[400] : const Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? Colors.white 
                      : (isDark ? Colors.white : const Color(0xFF1F2937)),
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showDateRangePicker(BuildContext context, AppState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.statsStartDate,
        end: state.statsEndDate,
      ),
    );
    
    if (picked != null) {
      state.updateStatsDateRange(picked.start, picked.end);
    }
  }

  void _showAddShiftSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddShiftSheet(),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),

            // Секция "Аккаунт"
            _buildSettingsSection(
              context,
              'Аккаунт',
              [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Имя'),
                  subtitle: Text(state.userName.isEmpty ? 'Не указано' : state.userName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNameDialog(context, state),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(state.userEmail.isEmpty ? 'Не указан' : state.userEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEmailDialog(context, state),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Уведомления'),
                  value: state.notifications,
                  activeColor: Colors.blue,
                  onChanged: (value) => state.toggleNotifications(),
                ),
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            // Секция "Финансы"
            _buildSettingsSection(
              context,
              'Финансы',
              [
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Валюта'),
                  subtitle: Text(_getCurrencyName(state.currency)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCurrencyDialog(context, state),
                ),
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            // Секция "Оформление"
            _buildSettingsSection(
              context,
              'Оформление',
              [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Тема'),
                  subtitle: Text(_getThemeName(state.currentTheme)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context, state),
                ),
              ],
              isDark,
            ),
            const SizedBox(height: 32),

            // Кнопка выхода
            Center(
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Выход'),
                      content: const Text('Вы уверены, что хотите выйти?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Вы вышли из аккаунта')),
                            );
                          },
                          child: const Text(
                            'Выйти',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light: return 'Светлая';
      case AppTheme.dark: return 'Тёмная';
      case AppTheme.ocean: return 'Океан';
      case AppTheme.sunset: return 'Закат';
      case AppTheme.forest: return 'Лес';
    }
  }

  String _getCurrencyName(String currency) {
    switch (currency) {
      case 'RUB': return '₽ Рубль';
      case 'USD': return '\$ Доллар';
      case 'EUR': return '€ Евро';
      default: return '₽ Рубль';
    }
  }

  void _showNameDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                state.updateUserName(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Имя обновлено!')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.userEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                state.updateUserEmail(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email обновлён!')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите валюту'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption(context, state, 'RUB', '₽ Рубль'),
            _buildCurrencyOption(context, state, 'USD', '\$ Доллар'),
            _buildCurrencyOption(context, state, 'EUR', '€ Евро'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(BuildContext context, AppState state, String code, String name) {
    return ListTile(
      title: Text(name),
      trailing: state.currency == code ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        state.changeCurrency(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Валюта изменена на $name')),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, state, AppTheme.light, 'Светлая'),
            _buildThemeOption(context, state, AppTheme.dark, 'Тёмная'),
            _buildThemeOption(context, state, AppTheme.ocean, 'Океан'),
            _buildThemeOption(context, state, AppTheme.sunset, 'Закат'),
            _buildThemeOption(context, state, AppTheme.forest, 'Лес'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppState state, AppTheme theme, String name) {
    return ListTile(
      title: Text(name),
      trailing: state.currentTheme == theme ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        state.changeTheme(theme);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тема изменена на $name')),
        );
      },
    );
  }
}

class AddMenuSheet extends StatelessWidget {
  const AddMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Добавить',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.check_box,
              title: 'Новая задача',
              subtitle: 'Создать задачу с дедлайном',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const AddTaskSheet(),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.calendar_today,
              title: 'Смена в графике',
              subtitle: 'Запланировать рабочую смену',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const AddShiftSheet(),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.attach_money,
              title: 'Операция',
              subtitle: 'Добавить доход или расход',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const AddTransactionSheet(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[500] : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final amountController = TextEditingController();
  final descController = TextEditingController();
  final categoryController = TextEditingController();
  TransactionType selectedType = TransactionType.income;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = selectedType == TransactionType.income 
        ? const Color(0xFF34C759) 
        : const Color(0xFFFF3B30);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Новая операция',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Переключатель с анимацией
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: selectedType == TransactionType.income
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.45,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedType = TransactionType.income),
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward_rounded,
                                          color: selectedType == TransactionType.income
                                              ? Colors.white
                                              : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Доход',
                                          style: TextStyle(
                                            color: selectedType == TransactionType.income
                                                ? Colors.white
                                                : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedType = TransactionType.expense),
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward_rounded,
                                          color: selectedType == TransactionType.expense
                                              ? Colors.white
                                              : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Расход',
                                          style: TextStyle(
                                            color: selectedType == TransactionType.expense
                                                ? Colors.white
                                                : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Сумма - БОЛЬШОЕ поле
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: primaryColor.withOpacity(0.3),
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 20, top: 20),
                            child: Text(
                              state.currencySymbol,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Описание и категория в одной группе
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: descController,
                            style: TextStyle(
                              fontSize: 17,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Описание',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                              ),
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          ),
                          TextField(
                            controller: categoryController,
                            style: TextStyle(
                              fontSize: 17,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Категория',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                              ),
                              prefixIcon: Icon(
                                Icons.folder_outlined,
                                color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопка
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final amount = double.tryParse(amountController.text);
                            if (amount != null && descController.text.isNotEmpty) {
                              final transaction = Transaction(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                type: selectedType,
                                amount: amount,
                                category: categoryController.text.isEmpty 
                                    ? (selectedType == TransactionType.income ? 'Доход' : 'Расход')
                                    : categoryController.text,
                                description: descController.text,
                                date: DateTime.now(),
                              );
                              state.addTransaction(transaction);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedType == TransactionType.income 
                                        ? '💰 Доход добавлен!' 
                                        : '💸 Расход добавлен!',
                                  ),
                                  backgroundColor: primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              'Добавить операцию',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// UTILITIES
String _formatNumber(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

String _formatDate(DateTime date) {
  const months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];
  
  final now = DateTime.now();
  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return 'Сегодня';
  }
  
  return '${date.day} ${months[date.month - 1]}';
}

String _formatMonth(DateTime date) {
  const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  return '${months[date.month - 1]} ${date.year}';
}