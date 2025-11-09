// ============================================
// FLOW APP - ЧАСТЬ 1 из 4
// Модели, State Management, Main App, MainScreen
// ============================================

import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
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
enum RepeatType { never, daily, weekly, monthly }

// MODELS
class Task {
  final String id;
  String title;
  String description;
  DateTime deadline;
  TimeOfDay? time;
  String? location;
  String? category;
  List<String> tags;
  Priority priority;
  bool isDone;
  Color color;
  IconData icon;
  String? notes;
  DateTime? reminderTime;
  RepeatType repeatType;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.time,
    this.location,
    this.category,
    this.tags = const [],
    required this.priority,
    required this.isDone,
    this.color = Colors.blue,
    this.icon = Icons.task_alt,
    this.notes,
    this.reminderTime,
    this.repeatType = RepeatType.never,
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
  
  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<ExpenseCategory> get expenseCategories => _expenseCategories;

  void addExpenseCategory(ExpenseCategory category) {
    _expenseCategories.add(category);
    notifyListeners();
  }

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
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          brightness: Brightness.light,
          useMaterial3: true,
        );
      case AppTheme.dark:
        return ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF0A0E27),
          brightness: Brightness.dark,
          useMaterial3: true,
        );
      case AppTheme.ocean:
        return ThemeData(
          primarySwatch: Colors.cyan,
          scaffoldBackgroundColor: const Color(0xFFE0F7FA),
          brightness: Brightness.light,
          useMaterial3: true,
        );
      case AppTheme.sunset:
        return ThemeData(
          primarySwatch: Colors.deepOrange,
          scaffoldBackgroundColor: const Color(0xFFFFF3E0),
          brightness: Brightness.light,
          useMaterial3: true,
        );
      case AppTheme.forest:
        return ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFE8F5E9),
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  final List<Widget> _screens = const [
    HomeScreen(),
    FinanceScreen(),
    TasksScreen(),
    ScheduleScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                    ? [
                        const Color(0xFF1a1a2e).withOpacity(0.95),
                        const Color(0xFF16213e).withOpacity(0.95),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.90),
                      ],
              ),
              border: Border(
                top: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Главная', isDark),
                    _buildNavItem(1, Icons.attach_money_rounded, 'Финансы', isDark),
                    _buildNavItem(2, Icons.check_box_rounded, 'Задачи', isDark),
                    _buildNavItem(3, Icons.calendar_today_rounded, 'График', isDark),
                    _buildNavItem(4, Icons.settings_rounded, 'Ещё', isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              _fabController.forward().then((_) => _fabController.reverse());
              HapticFeedback.mediumImpact();
              _showAddMenu(context);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.15),
                    const Color(0xFF764ba2).withOpacity(0.15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(isSelected ? 1.1 : 1.0),
              child: Icon(
                icon,
                color: isSelected 
                    ? const Color(0xFF667eea)
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFF667eea)
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

String _formatShortDate(DateTime date) {
  final now = DateTime.now();
  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return 'Сегодня';
  }
  final tomorrow = now.add(const Duration(days: 1));
  if (date.day == tomorrow.day && date.month == tomorrow.month) {
    return 'Завтра';
  }
  return '${date.day}.${date.month}.${date.year}';
}

String _formatMonth(DateTime date) {
  const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  return '${months[date.month - 1]} ${date.year}';
}


// ============================================
// FLOW APP - ЧАСТЬ 2 из 4 (ИСПРАВЛЕНО)
// HomeScreen, FinanceScreen, TaskItemWidget
// ВСТАВЬТЕ ЭТОТ КОД ПОСЛЕ ЧАСТИ 1
// ============================================

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

    final hasData = state.shifts.isNotEmpty || state.tasks.isNotEmpty || state.transactions.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Приветствие с анимацией
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.userName.isEmpty 
                        ? 'Добро пожаловать! 👋' 
                        : 'Доброе утро, ${state.userName} 👋',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(DateTime.now()),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (!hasData) ...[
              // Пустое состояние
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667eea).withOpacity(0.1),
                            const Color(0xFF764ba2).withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 80,
                        color: const Color(0xFF667eea),
                      ),
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
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showAddMenu(context),
                          borderRadius: BorderRadius.circular(16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Создать первую запись',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
              ),
            ] else ...[
              // Основной контент
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF667eea).withOpacity(0.9),
                            const Color(0xFF764ba2).withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'За месяц',
                                  '${monthHours.toStringAsFixed(1)} ч',
                                  Icons.access_time_rounded,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Заработано',
                                  '${state.currencySymbol}${_formatNumber(monthEarnings.toInt())}',
                                  Icons.trending_up_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (todayTasks.isNotEmpty) ...[
                Text(
                  'Задачи на сегодня',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                ...todayTasks.take(3).map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskItemWidget(task: task, compact: true),
                )),
                const SizedBox(height: 24),
              ],

              // Цель на месяц
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.04),
                              ]
                            : [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
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
                              Color(0xFF667eea),
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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

// TASK ITEM WIDGET
class TaskItemWidget extends StatefulWidget {
  final Task task;
  final bool compact;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.compact = false,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    state.toggleTask(widget.task.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.task.isDone
                          ? LinearGradient(
                              colors: [
                                widget.task.color,
                                widget.task.color.withOpacity(0.7),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: widget.task.color,
                        width: 2.5,
                      ),
                    ),
                    child: widget.task.isDone
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: widget.task.isDone 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark 
                                ? Colors.grey[400] 
                                : const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (widget.task.time != null || widget.task.location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (widget.task.time != null) ...[
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: widget.task.color.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.time!.format(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.task.color.withOpacity(0.8),
                                ),
                              ),
                            ],
                            if (widget.task.location != null) ...[
                              if (widget.task.time != null) 
                                const SizedBox(width: 12),
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: widget.task.color.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.task.location!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.task.color.withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.task.color.withOpacity(0.2),
                        widget.task.color.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.task.icon,
                    size: 20,
                    color: widget.task.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FINANCE SCREEN
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String selectedFilter = 'month';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;
    
    switch (selectedFilter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    final income = state.getIncome(start: startDate, end: endDate);
    final expense = state.getExpense(start: startDate, end: endDate);
    final balance = income - expense;
    final transactions = state.transactions.where((t) {
      if (t.date.isBefore(startDate)) return false;
      if (t.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Финансы',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddTransactionSheet(context),
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  color: const Color(0xFF667eea),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Сегодня', 'today', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Неделя', 'week', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Месяц', 'month', isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Баланс карточка
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF667eea).withOpacity(0.9),
                              const Color(0xFF764ba2).withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Баланс',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${state.currencySymbol}${_formatNumber(balance.toInt())}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildBalanceItem(
                                    'Доходы',
                                    '${state.currencySymbol}${_formatNumber(income.toInt())}',
                                    const Color(0xFF43e97b),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildBalanceItem(
                                    'Расходы',
                                    '${state.currencySymbol}${_formatNumber(expense.toInt())}',
                                    const Color(0xFFfa709a),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Заголовок транзакций
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Операции',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '${transactions.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Список транзакций
                  if (transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF667eea).withOpacity(0.1),
                                    const Color(0xFF764ba2).withOpacity(0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.attach_money_outlined,
                                size: 64,
                                color: const Color(0xFF667eea),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет операций',
                              style: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _showAddTransactionSheet(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Добавить операцию'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...transactions.map((transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(transaction.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          state.deleteTransaction(transaction.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Операция удалена'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          Colors.white.withOpacity(0.08),
                                          Colors.white.withOpacity(0.04),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.9),
                                          Colors.white.withOpacity(0.7),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: transaction.type == TransactionType.income
                                            ? [const Color(0xFF43e97b), const Color(0xFF43e97b).withOpacity(0.7)]
                                            : [const Color(0xFFfa709a), const Color(0xFFfa709a).withOpacity(0.7)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      transaction.type == TransactionType.income
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.category,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(transaction.date),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${transaction.type == TransactionType.income ? '+' : '-'}${state.currencySymbol}${_formatNumber(transaction.amount.toInt())}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: transaction.type == TransactionType.income
                                          ? const Color(0xFF43e97b)
                                          : const Color(0xFFfa709a),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isSelected 
              ? null 
              : isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent
                : isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : isDark 
                    ? Colors.white.withOpacity(0.7) 
                    : Colors.black.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddTransactionSheet(),
    );
  }
}


// ============================================
// FLOW APP - ЧАСТЬ 3 из 4  
// TasksScreen, ScheduleScreen, SettingsScreen
// ВСТАВЬТЕ ЭТОТ КОД ПОСЛЕ ЧАСТИ 2
// ============================================

// TASKS SCREEN
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Задачи',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddTaskSheet(context),
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  color: const Color(0xFF667eea),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
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

          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea).withOpacity(0.1),
                                const Color(0xFF764ba2).withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: const Color(0xFF667eea),
                          ),
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
                    physics: const BouncingScrollPhysics(),
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            state.deleteTask(filteredTasks[index].id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Задача удалена'),
                                behavior: SnackBarBehavior.floating,
                              ),
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
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isSelected 
              ? null 
              : isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent
                : isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : isDark 
                    ? Colors.white.withOpacity(0.7) 
                    : Colors.black.withOpacity(0.7),
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

// SCHEDULE SCREEN
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

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime.now();
    final monthEarnings = state.getTotalEarnings(start: monthStart, end: monthEnd);
    final monthHours = state.getTotalHours(start: monthStart, end: monthEnd);
    final monthShifts = state.getShiftCount(start: monthStart, end: monthEnd);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'График работы',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: Icon(
                    showStats ? Icons.calendar_today : Icons.bar_chart,
                    color: const Color(0xFF667eea),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (showStats) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.04),
                              ]
                            : [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Статистика работы',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Заработано за месяц:', 
                          '${state.currencySymbol}${_formatNumber(monthEarnings.toInt())}', 
                          const Color(0xFF4facfe),
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Отработано часов:', 
                          '${monthHours.toStringAsFixed(1)} ч', 
                          const Color(0xFF667eea),
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Количество смен:', 
                          '$monthShifts', 
                          const Color(0xFFf093fb),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.04),
                            ]
                          : [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
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
                          TextButton(
                            onPressed: () => setState(() => selectedDate = DateTime.now()),
                            child: const Text('Сегодня'),
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
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (todayShifts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667eea).withOpacity(0.1),
                              const Color(0xFF764ba2).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: const Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет записей на этот день',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...todayShifts.map((shift) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            shift.color.withOpacity(0.15),
                            shift.color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: shift.color.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [shift.color, shift.color.withOpacity(0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(shift.icon, size: 20, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
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
                          const SizedBox(height: 12),
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
                        ],
                      ),
                    ),
                  ),
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
    const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final isSelected = date.day == selectedDate.day &&
          date.month == selectedDate.month;
      final isToday = date.day == now.day && date.month == now.month;

      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => selectedDate = date);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  )
                : null,
            color: isSelected 
                ? null 
                : isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
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
                    color: isSelected ? Colors.white : const Color(0xFF667eea),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// SETTINGS SCREEN
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),

            _buildSettingsSection(
              context,
              'Аккаунт',
              [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Имя',
                  subtitle: state.userName.isEmpty ? 'Не указано' : state.userName,
                  isDark: isDark,
                  onTap: () => _showNameDialog(context, state),
                ),
                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: state.userEmail.isEmpty ? 'Не указан' : state.userEmail,
                  isDark: isDark,
                  onTap: () => _showEmailDialog(context, state),
                ),
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            _buildSettingsSection(
              context,
              'Финансы',
              [
                _buildSettingsTile(
                  icon: Icons.currency_exchange,
                  title: 'Валюта',
                  subtitle: _getCurrencyName(state.currency),
                  isDark: isDark,
                  onTap: () => _showCurrencyDialog(context, state),
                ),
              ],
              isDark,
            ),
            const SizedBox(height: 16),

            _buildSettingsSection(
              context,
              'Оформление',
              [
                _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Тема',
                  subtitle: _getThemeName(state.currentTheme),
                  isDark: isDark,
                  onTap: () => _showThemeDialog(context, state),
                ),
              ],
              isDark,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
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
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
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
      trailing: state.currency == code ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      onTap: () {
        state.changeCurrency(code);
        Navigator.pop(context);
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
      trailing: state.currentTheme == theme ? const Icon(Icons.check, color: Color(0xFF667eea)) : null,
      onTap: () {
        state.changeTheme(theme);
        Navigator.pop(context);
      },
    );
  }
}

// ============================================
// FLOW APP - ЧАСТЬ 4 из 4 (ФИНАЛЬНАЯ)
// AddMenuSheet, AddTaskSheet (РАСШИРЕННАЯ), AddShiftSheet, AddTransactionSheet
// ВСТАВЬТЕ ЭТОТ КОД ПОСЛЕ ЧАСТИ 3
// ============================================

// ADD MENU SHEET
class AddMenuSheet extends StatelessWidget {
  const AddMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1a1a2e).withOpacity(0.95),
                      const Color(0xFF16213e).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFF5F7FA).withOpacity(0.95),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Добавить',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  context,
                  icon: Icons.check_box_rounded,
                  title: 'Новая задача',
                  subtitle: 'Создать задачу с дедлайном',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
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
                  icon: Icons.calendar_today_rounded,
                  title: 'Смена в графике',
                  subtitle: 'Запланировать рабочую смену',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  ),
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
                  icon: Icons.attach_money_rounded,
                  title: 'Операция',
                  subtitle: 'Добавить доход или расход',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
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
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? Colors.white.withOpacity(0.6) 
                          : Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isDark 
                  ? Colors.white.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ADD TASK SHEET - РАСШИРЕННАЯ ВЕРСИЯ СО ВСЕМИ ПОЛЯМИ
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> 
    with SingleTickerProviderStateMixin {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final categoryController = TextEditingController();
  
  Color selectedColor = const Color(0xFF667eea);
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  Priority selectedPriority = Priority.medium;
  RepeatType selectedRepeat = RepeatType.never;
  DateTime? reminderTime;
  List<String> tags = [];
  final tagController = TextEditingController();
  
  late AnimationController _pulseController;
  
  final List<Color> colors = [
    const Color(0xFF667eea),
    const Color(0xFFf093fb),
    const Color(0xFF4facfe),
    const Color(0xFF43e97b),
    const Color(0xFFfa709a),
    const Color(0xFFfeca57),
    const Color(0xFFff6348),
    const Color(0xFF5f27cd),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    categoryController.dispose();
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0f0c29),
                  const Color(0xFF302b63),
                  selectedColor.withOpacity(0.3),
                ]
              : [
                  const Color(0xFFF5F7FA),
                  selectedColor.withOpacity(0.1),
                  selectedColor.withOpacity(0.2),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              isDark ? Colors.white : Colors.black,
                              selectedColor,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Новая задача',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Выбор цвета
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: colors.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final color = colors[index];
                              final isSelected = selectedColor == color;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedColor = color);
                                  HapticFeedback.mediumImpact();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  width: isSelected ? 70 : 60,
                                  height: isSelected ? 70 : 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isSelected)
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color.withOpacity(
                                                      0.6 * _pulseController.value,
                                                    ),
                                                    blurRadius: 30 + 
                                                        (15 * _pulseController.value),
                                                    spreadRadius: 5 + 
                                                        (5 * _pulseController.value),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              color,
                                              color.withOpacity(0.7),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              isSelected ? 0.6 : 0.2,
                                            ),
                                            width: isSelected ? 3 : 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 32,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Название
                        _buildGlassField(
                          controller: titleController,
                          hint: 'Название задачи',
                          icon: Icons.title_rounded,
                          isDark: isDark,
                          color: selectedColor,
                        ),
                        const SizedBox(height: 12),
                        
                        // Описание
                        _buildGlassField(
                          controller: descController,
                          hint: 'Добавьте описание...',
                          icon: Icons.subject_rounded,
                          isDark: isDark,
                          color: selectedColor,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        
                        // Дата и время
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoTile(
                                label: 'Дата',
                                value: _formatShortDate(selectedDate),
                                icon: Icons.calendar_today_rounded,
                                color: selectedColor,
                                isDark: isDark,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() => selectedDate = date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoTile(
                                label: 'Время',
                                value: selectedTime?.format(context) ?? 'Не задано',
                                icon: Icons.access_time_rounded,
                                color: selectedColor,
                                isDark: isDark,
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() => selectedTime = time);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Место
                        _buildGlassField(
                          controller: locationController,
                          hint: 'Добавить место',
                          icon: Icons.location_on_rounded,
                          isDark: isDark,
                          color: selectedColor,
                        ),
                        const SizedBox(height: 12),
                        
                        // Категория
                        _buildGlassField(
                          controller: categoryController,
                          hint: 'Категория',
                          icon: Icons.folder_rounded,
                          isDark: isDark,
                          color: selectedColor,
                        ),
                        const SizedBox(height: 20),
                        
                        // Теги
                        Text(
                          'Теги',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...tags.map((tag) => _buildTag(tag, isDark)),
                            _buildAddTagButton(isDark),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Приоритет
                        Text(
                          'Приоритет',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPriorityChip(
                              'Высокий',
                              Priority.high,
                              Colors.red,
                              isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildPriorityChip(
                              'Средний',
                              Priority.medium,
                              Colors.orange,
                              isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildPriorityChip(
                              'Низкий',
                              Priority.low,
                              Colors.green,
                              isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Напоминание
                        _buildInfoTile(
                          label: 'Напоминание',
                          value: reminderTime != null
                              ? '${_formatShortDate(reminderTime!)} ${TimeOfDay.fromDateTime(reminderTime!).format(context)}'
                              : 'Не установлено',
                          icon: Icons.notifications_rounded,
                          color: selectedColor,
                          isDark: isDark,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: selectedDate,
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  reminderTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Повтор
                        Text(
                          'Повтор',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildRepeatChip('Никогда', RepeatType.never, isDark),
                              const SizedBox(width: 8),
                              _buildRepeatChip('Ежедневно', RepeatType.daily, isDark),
                              const SizedBox(width: 8),
                              _buildRepeatChip('Еженедельно', RepeatType.weekly, isDark),
                              const SizedBox(width: 8),
                              _buildRepeatChip('Ежемесячно', RepeatType.monthly, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Кнопка создать
                        _buildGlassButton(
                          context: context,
                          label: 'Создать задачу',
                          color: selectedColor,
                          isDark: isDark,
                          onTap: () {
                            if (titleController.text.isNotEmpty) {
                              final task = Task(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleController.text,
                                description: descController.text,
                                deadline: selectedDate,
                                time: selectedTime,
                                location: locationController.text.isEmpty 
                                    ? null 
                                    : locationController.text,
                                category: categoryController.text.isEmpty 
                                    ? null 
                                    : categoryController.text,
                                tags: tags,
                                priority: selectedPriority,
                                isDone: false,
                                color: selectedColor,
                                icon: _getPriorityIcon(selectedPriority),
                                reminderTime: reminderTime,
                                repeatType: selectedRepeat,
                              );
                              state.addTask(task);
                              Navigator.pop(context);
                              
                              // Улучшенное уведомление
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                selectedColor,
                                                selectedColor.withOpacity(0.5),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Задача создана!',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                titleController.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white.withOpacity(0.9),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  backgroundColor: isDark 
                                      ? const Color(0xFF1F2937) 
                                      : const Color(0xFF374151),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                  elevation: 8,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color color,
    int maxLines = 1,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: maxLines > 1 ? 15 : 17,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark 
                    ? Colors.white.withOpacity(0.4) 
                    : Colors.black.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                icon,
                color: color.withOpacity(0.8),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: maxLines > 1 ? 16 : 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color.withOpacity(0.8), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark 
                            ? Colors.white.withOpacity(0.6) 
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedColor.withOpacity(0.2),
            selectedColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => tags.remove(tag)),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: selectedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTagButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Добавить тег'),
            content: TextField(
              controller: tagController,
              decoration: const InputDecoration(
                hintText: 'Введите название тега',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() => tags.add(value));
                  tagController.clear();
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (tagController.text.isNotEmpty) {
                    setState(() => tags.add(tagController.text));
                    tagController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Добавить'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.08) 
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.2) 
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 16,
              color: selectedColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Добавить тег',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, Priority priority, Color color, bool isDark) {
    final isSelected = selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedPriority = priority);
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  )
                : null,
            color: isSelected 
                ? null 
                : isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected 
                  ? color 
                  : isDark 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.black.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? Colors.white 
                  : isDark 
                      ? Colors.white.withOpacity(0.7) 
                      : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatChip(String label, RepeatType type, bool isDark) {
    final isSelected = selectedRepeat == type;
    return GestureDetector(
      onTap: () {
        setState(() => selectedRepeat = type);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    selectedColor,
                    selectedColor.withOpacity(0.7),
                  ],
                )
              : null,
          color: isSelected 
              ? null 
              : isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? selectedColor 
                : isDark 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : isDark 
                    ? Colors.white.withOpacity(0.7) 
                    : Colors.black.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4 + (0.1 * _pulseController.value)),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Icons.priority_high_rounded;
      case Priority.medium:
        return Icons.circle;
      case Priority.low:
        return Icons.arrow_downward_rounded;
    }
  }
}

// ADD SHIFT SHEET (сокращенная версия из оригинала)
class AddShiftSheet extends StatefulWidget {
  const AddShiftSheet({super.key});

  @override
  State<AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<AddShiftSheet> {
  final titleController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
              : [Colors.white, const Color(0xFFF5F7FA)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Добавление смены',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Название смены',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Добавить логику создания смены
                Navigator.pop(context);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}

// ADD TRANSACTION SHEET
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
        ? const Color(0xFF4facfe)
        : const Color(0xFFf093fb);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0f0c29), const Color(0xFF302b63)]
              : [const Color(0xFFF5F7FA), Colors.white],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Новая операция',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Переключатель дохода/расхода
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
                                width: MediaQuery.of(context).size.width * 0.43,
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
                      
                      // Сумма
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
                      
                      // Описание и категория
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

