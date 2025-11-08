import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const FlowApp(),
    ),
  );
}

class NotificationService {
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'flow_channel',
      'Flow Notifications',
      channelDescription: 'Уведомления о задачах и целях',
      importance: Importance.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// STATE MANAGEMENT
enum TaskType { paid, personal, admin }
enum Priority { high, medium, low }
enum TransactionType { income, expense }
enum TemplateType { task, schedule }

class Task {
  final String id;
  String title;
  String description;
  DateTime deadline;
  TaskType type;
  int hours;
  int rate;
  bool isDone;
  Priority priority;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.type,
    required this.hours,
    required this.rate,
    required this.isDone,
    required this.priority,
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

class ScheduleSession {
  final String id;
  DateTime date;
  String startTime;
  String endTime;
  String client;
  String title;
  int hours;
  int rate;

  ScheduleSession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.client,
    required this.title,
    required this.hours,
    required this.rate,
  });
}

class Template {
  final String id;
  String name;
  String icon;
  TemplateType type;
  int hours;
  int rate;

  Template({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.hours,
    required this.rate,
  });
}

class AppState extends ChangeNotifier {
  String userName = 'Даниил';
  String userEmail = 'daniil@flow.app';
  int hourlyRate = 750;
  bool isPremium = false;
  bool notifications = true;
  bool darkMode = false;
  bool sync = true;
  
  final List<Task> _tasks = [];
  final List<Transaction> _transactions = [];
  final List<ScheduleSession> _schedule = [];
  final List<Template> _templates = [];

  AppState() {
    _initializeData();
  }

  void _initializeData() {
    _tasks.addAll([
      Task(
        id: '1',
        title: 'Подготовить отчёт',
        description: 'Клиент: Савои',
        deadline: DateTime.now(),
        type: TaskType.paid,
        hours: 2,
        rate: 750,
        isDone: false,
        priority: Priority.high,
      ),
      Task(
        id: '2',
        title: 'Дизайн лендинга',
        description: 'Клиент: TechStart',
        deadline: DateTime.now(),
        type: TaskType.paid,
        hours: 4,
        rate: 800,
        isDone: false,
        priority: Priority.high,
      ),
      Task(
        id: '3',
        title: 'Созвон с клиентом',
        description: '14:00 - 15:00',
        deadline: DateTime.now(),
        type: TaskType.paid,
        hours: 1,
        rate: 750,
        isDone: true,
        priority: Priority.medium,
      ),
      Task(
        id: '4',
        title: 'Купить продукты',
        description: 'Личное',
        deadline: DateTime.now(),
        type: TaskType.personal,
        hours: 0,
        rate: 0,
        isDone: false,
        priority: Priority.low,
      ),
    ]);

    _transactions.addAll([
      Transaction(
        id: '1',
        type: TransactionType.income,
        amount: 12000,
        category: 'Работа',
        description: 'Работа: Дизайн лендинга',
        date: DateTime.now(),
      ),
      Transaction(
        id: '2',
        type: TransactionType.expense,
        amount: 2450,
        category: 'Еда',
        description: 'Продукты',
        date: DateTime.now(),
      ),
      Transaction(
        id: '3',
        type: TransactionType.income,
        amount: 3750,
        category: 'Работа',
        description: 'Работа: Консультация',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    _schedule.addAll([
      ScheduleSession(
        id: '1',
        date: DateTime.now(),
        startTime: '10:00',
        endTime: '14:00',
        client: 'TechStart',
        title: 'Дизайн лендинга',
        hours: 4,
        rate: 800,
      ),
      ScheduleSession(
        id: '2',
        date: DateTime.now(),
        startTime: '14:00',
        endTime: '15:00',
        client: 'Савои',
        title: 'Созвон',
        hours: 1,
        rate: 750,
      ),
      ScheduleSession(
        id: '3',
        date: DateTime.now(),
        startTime: '16:00',
        endTime: '20:00',
        client: 'StartupX',
        title: 'Кодинг проекта',
        hours: 4,
        rate: 850,
      ),
    ]);

    _templates.addAll([
      Template(
        id: '1',
        name: 'Встреча с клиентом',
        icon: '💼',
        type: TemplateType.task,
        hours: 1,
        rate: 750,
      ),
      Template(
        id: '2',
        name: 'Дизайн лендинга',
        icon: '🎨',
        type: TemplateType.task,
        hours: 4,
        rate: 800,
      ),
      Template(
        id: '3',
        name: 'Код-ревью',
        icon: '💻',
        type: TemplateType.task,
        hours: 2,
        rate: 850,
      ),
      Template(
        id: '4',
        name: 'Рабочий день (8 часов)',
        icon: '📅',
        type: TemplateType.schedule,
        hours: 8,
        rate: 750,
      ),
    ]);
  }

  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _tasks.where((t) => 
    t.deadline.day == DateTime.now().day &&
    t.deadline.month == DateTime.now().month
  ).toList();
  List<Task> get activeTasks => _tasks.where((t) => !t.isDone).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isDone).toList();
  List<Task> get paidTasks => _tasks.where((t) => t.type == TaskType.paid).toList();

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
  
  double get balance {
    double total = 0;
    for (var t in _transactions) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total;
  }

  double get monthIncome {
    return _transactions
      .where((t) => t.type == TransactionType.income && 
                   t.date.month == DateTime.now().month)
      .fold(0, (sum, t) => sum + t.amount);
  }

  double get monthExpense {
    return _transactions
      .where((t) => t.type == TransactionType.expense && 
                   t.date.month == DateTime.now().month)
      .fold(0, (sum, t) => sum + t.amount);
  }

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    notifyListeners();
  }

  List<ScheduleSession> get schedule => _schedule;
  
  List<ScheduleSession> todaySchedule(DateTime date) {
    return _schedule.where((s) => 
      s.date.day == date.day &&
      s.date.month == date.month &&
      s.date.year == date.year
    ).toList();
  }

  int get weekHours {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _schedule
      .where((s) => s.date.isAfter(weekStart))
      .fold(0, (sum, s) => sum + s.hours);
  }

  void addScheduleSession(ScheduleSession session) {
    _schedule.add(session);
    notifyListeners();
  }

  List<Template> get templates => _templates;

  void updateSettings({
    bool? notificationsValue,
    bool? darkModeValue,
    bool? syncValue,
    int? rateValue,
    bool? premiumValue,
  }) {
    if (notificationsValue != null) notifications = notificationsValue;
    if (darkModeValue != null) darkMode = darkModeValue;
    if (syncValue != null) sync = syncValue;
    if (rateValue != null) hourlyRate = rateValue;
    if (premiumValue != null) isPremium = premiumValue;
    notifyListeners();
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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                _buildNavItem(0, Icons.home_rounded, 'Главная'),
                _buildNavItem(1, Icons.attach_money_rounded, 'Финансы'),
                _buildNavItem(2, Icons.check_box_rounded, 'Задачи'),
                _buildNavItem(3, Icons.calendar_today_rounded, 'График'),
                _buildNavItem(4, Icons.settings_rounded, 'Еще'),
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

  Widget _buildNavItem(int index, IconData icon, String label) {
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
              color: isSelected ? Colors.blue : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : Colors.grey[400],
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
    final todayTasks = state.todayTasks;
    final todayHours = todayTasks
      .where((t) => t.type == TaskType.paid && !t.isDone)
      .fold(0, (sum, t) => sum + t.hours);
    final todayEarnings = todayTasks
      .where((t) => t.type == TaskType.paid && !t.isDone)
      .fold(0, (sum, t) => sum + (t.hours * t.rate));
    final completedCount = todayTasks.where((t) => t.isDone).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доброе утро, ${state.userName} 👋',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Today Summary Card
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
                            'Сегодня запланировано',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$todayHours ч',
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
                            'Прогноз дохода',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₽${_formatNumber(todayEarnings)}',
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
                            'Выполнено задач',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount из ${todayTasks.length}',
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
                            'Ставка',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₽${state.hourlyRate}/час',
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
            const SizedBox(height: 20),

            // Monthly Overview
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.trending_up,
                    title: 'ДОХОД ЗА МЕСЯЦ',
                    value: '₽${_formatNumber(state.monthIncome.toInt())}',
                    subtitle: '↑ 15% от плана',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                    ),
                    iconColor: const Color(0xFF16A34A),
                    textColor: const Color(0xFF166534),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.access_time,
                    title: 'ОТРАБОТАНО',
                    value: '${state.weekHours * 4} ч',
                    subtitle: 'Осталось 16 ч',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                    ),
                    iconColor: const Color(0xFF9333EA),
                    textColor: const Color(0xFF6B21A8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Задачи на сегодня',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '$completedCount из ${todayTasks.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (todayTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Нет задач на сегодня',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            else
              ...todayTasks.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskItemWidget(task: task, compact: true),
              )),

            const SizedBox(height: 24),

            // Financial Goal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Цель на месяц: ₽150,000',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        '${((state.monthIncome / 150000) * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.monthIncome / 150000,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Осталось ₽${_formatNumber((150000 - state.monthIncome).toInt())} • ~${((150000 - state.monthIncome) / state.hourlyRate).toInt()} часа работы',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Gradient gradient,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// TASK ITEM WIDGET
class TaskItemWidget extends StatelessWidget {
  final Task task;
  final bool compact;
  final VoidCallback? onDelete;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.compact = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    Color getBorderColor() {
      switch (task.type) {
        case TaskType.paid:
          return const Color(0xFF3B82F6);
        case TaskType.personal:
          return const Color(0xFFF97316);
        case TaskType.admin:
          return const Color(0xFF8B5CF6);
      }
    }

    Color getBackgroundColor() {
      switch (task.type) {
        case TaskType.paid:
          return const Color(0xFFEFF6FF);
        case TaskType.personal:
          return const Color(0xFFFFF7ED);
        case TaskType.admin:
          return const Color(0xFFF5F3FF);
      }
    }

    Color getTextColor() {
      switch (task.type) {
        case TaskType.paid:
          return const Color(0xFF1E40AF);
        case TaskType.personal:
          return const Color(0xFFC2410C);
        case TaskType.admin:
          return const Color(0xFF6B21A8);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getBorderColor().withOpacity(0.3)),
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
                  color: task.isDone ? getBorderColor() : getBorderColor().withOpacity(0.5),
                  width: 2,
                ),
                color: task.isDone ? getBorderColor() : Colors.transparent,
              ),
              child: task.isDone
                  ? Icon(Icons.check, size: 16, color: getBackgroundColor())
                  : null,
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
                    color: getTextColor(),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: getTextColor().withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (task.type == TaskType.paid && task.hours > 0) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${task.hours}ч',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: getTextColor(),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₽${_formatNumber(task.hours * task.rate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: getTextColor().withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
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
  bool showStats = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Финансы',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Статистика'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (showStats) ...[
              _buildFinanceStats(state),
              const SizedBox(height: 20),
            ],

            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1F2937), Color(0xFF111827)],
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
                    '₽${_formatNumber(state.balance.toInt())}',
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
                            '+₽${_formatNumber(state.monthIncome.toInt())}',
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
                            '-₽${_formatNumber(state.monthExpense.toInt())}',
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

            // Income vs Expenses
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
                          '₽${_formatNumber(state.monthIncome.toInt())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.weekHours * 4} часа • ₽${((state.monthIncome) / (state.weekHours * 4)).toInt()}/ч',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF16A34A),
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
                          '₽${_formatNumber(state.monthExpense.toInt())}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((state.monthExpense / state.monthIncome) * 100).toInt()}% от дохода',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            const Text(
              'Последние операции',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),

            ...state.transactions.take(5).map((transaction) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(transaction.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${transaction.type == TransactionType.income ? '+' : '-'}₽${_formatNumber(transaction.amount.toInt())}',
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
        ),
      ),
    );
  }

  Widget _buildFinanceStats(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Финансовая аналитика',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Средний доход/месяц',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₽${_formatNumber((state.monthIncome * 0.95).toInt())}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            '+12%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Эффективная ставка',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B21A8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₽${((state.monthIncome) / (state.weekHours * 4)).toInt()}/ч',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF581C87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            '+1.5%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    
    List<Task> filteredTasks;
    switch (selectedFilter) {
      case 'today':
        filteredTasks = state.todayTasks;
        break;
      case 'all':
        filteredTasks = state.tasks;
        break;
      case 'paid':
        filteredTasks = state.paidTasks;
        break;
      case 'personal':
        filteredTasks = state.tasks.where((t) => t.type == TaskType.personal).toList();
        break;
      case 'done':
        filteredTasks = state.completedTasks;
        break;
      default:
        filteredTasks = state.tasks;
    }

    final totalHours = filteredTasks
        .where((t) => t.type == TaskType.paid && !t.isDone)
        .fold(0, (sum, t) => sum + t.hours);
    final totalEarnings = filteredTasks
        .where((t) => t.type == TaskType.paid && !t.isDone)
        .fold(0, (sum, t) => sum + (t.hours * t.rate));

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Задачи',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showTemplates(context),
                  icon: const Icon(Icons.repeat, size: 18),
                  label: const Text('Шаблоны'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
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
                          'Активных задач',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.activeTasks.length}',
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
                          'Потенциал дохода',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₽${_formatNumber(totalEarnings)}',
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Оплачиваемых часов: ${totalHours}ч',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Выполнено: ${state.completedTasks.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Сегодня', 'today', state.todayTasks.length),
                const SizedBox(width: 8),
                _buildFilterChip('Все', 'all', state.tasks.length),
                const SizedBox(width: 8),
                _buildFilterChip('Оплачиваемые', 'paid', state.paidTasks.length),
                const SizedBox(width: 8),
                _buildFilterChip('Личные', 'personal',
                    state.tasks.where((t) => t.type == TaskType.personal).length),
                const SizedBox(width: 8),
                _buildFilterChip('Выполнено', 'done', state.completedTasks.length),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tasks List
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text(
                      'Нет задач в этой категории',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskItemWidget(
                          task: filteredTasks[index],
                          onDelete: () {
                            state.deleteTask(filteredTasks[index].id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Задача удалена')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  void _showTemplates(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const TemplatesSheet(),
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
    final todaySchedule = state.todaySchedule(selectedDate);
    final totalHours = todaySchedule.fold(0, (sum, s) => sum + s.hours);
    final totalEarnings = todaySchedule.fold(0, (sum, s) => sum + (s.hours * s.rate));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'График работы',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Статистика'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (showStats) ...[
              _buildScheduleStats(state),
              const SizedBox(height: 20),
            ],

            // Weekly Summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
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
                            'Неделя 44',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${state.weekHours} часов',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
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
                            '₽${_formatNumber(state.weekHours * state.hourlyRate)}',
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Рабочих дней',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '5 из 7',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar Week View
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    children: _buildWeekDays(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Schedule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Запланировано',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${totalHours}ч • ₽${_formatNumber(totalEarnings)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (todaySchedule.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Нет записей на этот день',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            else
              ...todaySchedule.map((session) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session.client,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₽${_formatNumber(session.hours * session.rate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            Text(
                              '${session.hours}ч × ₽${session.rate}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF1E40AF)),
                        const SizedBox(width: 4),
                        Text(
                          '${session.startTime} - ${session.endTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),

            const SizedBox(height: 20),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Этот месяц',
                    '${state.weekHours * 4}ч',
                    const Color(0xFFEFF6FF),
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    'Заработано',
                    '₽${_formatNumber(state.monthIncome.toInt())}',
                    const Color(0xFFF0FDF4),
                    const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    'Проектов',
                    '8',
                    const Color(0xFFF5F3FF),
                    const Color(0xFF9333EA),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStats(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика работы',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Всего отработано',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.weekHours * 4} ч',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3730A3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            '+8% к прошлому месяцу',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Самый продуктивный день',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Пт, 25 окт',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '10 часов работы',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF16A34A).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekDays() {
    const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
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
            color: isSelected ? Colors.blue : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekDays[index],
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1F2937),
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
}

// SETTINGS SCREEN
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),

            // Premium Upsell
            if (!state.isPremium)
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Flow Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Разблокируйте все возможности',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPremiumFeature('⚡', 'Неограниченные проекты и клиенты'),
                    const SizedBox(height: 8),
                    _buildPremiumFeature('📊', 'Расширенная аналитика и прогнозы'),
                    const SizedBox(height: 8),
                    _buildPremiumFeature('🛡️', 'Экспорт данных в PDF/Excel'),
                    const SizedBox(height: 8),
                    _buildPremiumFeature('⏰', 'Автоматический расчёт налогов'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        state.updateSettings(premiumValue: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Добро пожаловать в Premium!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Начать бесплатный пробный период',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '7 дней бесплатно, затем ₽299/мес',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Settings Sections
            _buildSettingsSection(
              context,
              'Аккаунт',
              [
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF6B7280)),
                  title: const Text('Профиль'),
                  subtitle: Text(state.userName),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF6B7280)),
                  title: const Text('Email'),
                  subtitle: Text(state.userEmail),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  onTap: () {},
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications, color: Color(0xFF6B7280)),
                  title: const Text('Уведомления'),
                  value: state.notifications,
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    state.updateSettings(notificationsValue: value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSettingsSection(
              context,
              'Финансы',
              [
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Color(0xFF6B7280)),
                  title: const Text('Основная ставка'),
                  subtitle: Text('₽${state.hourlyRate}/час'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  onTap: () => _showRateDialog(context, state),
                ),
                ListTile(
                  leading: const Icon(Icons.currency_exchange, color: Color(0xFF6B7280)),
                  title: const Text('Валюта'),
                  subtitle: const Text('RUB (₽)'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSettingsSection(
              context,
              'Приложение',
              [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Color(0xFF6B7280)),
                  title: const Text('Тёмная тема'),
                  value: state.darkMode,
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    state.updateSettings(darkModeValue: value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.sync, color: Color(0xFF6B7280)),
                  title: const Text('Синхронизация'),
                  value: state.sync,
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    state.updateSettings(syncValue: value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

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
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.hourlyRate.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить ставку'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Ставка за час',
            suffixText: '₽/час',
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
              final newRate = int.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                state.updateSettings(rateValue: newRate);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ставка обновлена!')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

// ADD MENU SHEET
class AddMenuSheet extends StatelessWidget {
  const AddMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
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
                // Add task logic
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.calendar_today,
              title: 'Запись в графике',
              subtitle: 'Запланировать рабочее время',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                // Add schedule logic
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.attach_money,
              title: 'Доход/Расход',
              subtitle: 'Добавить финансовую операцию',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                // Add transaction logic
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.flag,
              title: 'Цель',
              subtitle: 'Установить финансовую цель',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция в разработке')),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

// TEMPLATES SHEET
class TemplatesSheet extends StatelessWidget {
  const TemplatesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Шаблоны',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: state.templates.length,
                itemBuilder: (context, index) {
                  final template = state.templates[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      final task = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: template.name,
                        description: 'Создано из шаблона',
                        deadline: DateTime.now(),
                        type: TaskType.paid,
                        hours: template.hours,
                        rate: template.rate,
                        isDone: false,
                        priority: Priority.medium,
                      );
                      state.addTask(task);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Задача создана из шаблона!')),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(template.icon, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${template.hours}ч • ₽${_formatNumber(template.hours * template.rate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.add, color: Colors.blue),
                        ],
                      ),
                    ),
                  );
                },
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
    'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
    'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'
  ];
  const weekdays = [
    'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'
  ];
  
  final now = DateTime.now();
  if (date.day == now.day && date.month == now.month && date.year == now.year) {
    return 'Сегодня';
  } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
    return 'Вчера';
  }
  
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String _formatMonth(DateTime date) {
  const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  return '${months[date.month - 1]} ${date.year}';
}