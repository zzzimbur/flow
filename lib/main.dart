// ============================================================================
// FLOW APP - ПОЛНОЕ ПРИЛОЖЕНИЕ НА FLUTTER
// ============================================================================
// Приложение для учёта финансов, задач и графика работы
// 
// УСТАНОВКА:
// 1. flutter create flow_app
// 2. Скопировать этот код в lib/main.dart
// 3. flutter pub add provider uuid intl
// 4. flutter run
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'dart:math';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: FlowApp(),
    ),
  );
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================================
// STATE MANAGEMENT
// ============================================================================
class AppState extends ChangeNotifier {
  // Пользователь
  String userName = 'Даниил';
  String userEmail = 'daniil@flow.app';
  int hourlyRate = 750;
  bool isPremium = false;
  
  // Настройки
  bool notifications = true;
  bool darkMode = false;
  bool sync = true;
  
  // Задачи
  final List<Task> _tasks = [
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
      deadline: DateTime.now().add(Duration(days: 1)),
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
  ];

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

  // Транзакции
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      type: TransactionType.income,
      amount: 12000,
      category: 'Работа',
      description: 'Дизайн лендинга',
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
      description: 'Консультация',
      date: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

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

  // График работы
  final List<ScheduleSession> _schedule = [
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
  ];

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

  // Шаблоны
  final List<Template> _templates = [
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
  ];

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

// ============================================================================
// МОДЕЛИ ДАННЫХ
// ============================================================================

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

// ============================================================================
// ГЛАВНЫЙ ЭКРАН С НАВИГАЦИЕЙ
// ============================================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Финансы'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: 'Задачи'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'График'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ещё'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMenuSheet(),
    );
  }
}

// ============================================================================
// ЭКРАН: ГЛАВНАЯ
// ============================================================================
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доброе утро, ${state.userName} 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              _formatDate(DateTime.now()),
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 20),

            // Карточка сводки
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
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
                          Text('Сегодня запланировано',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          Text('$todayHours ч',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Прогноз дохода',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          Text('₽${_formatNumber(todayEarnings)}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(color: Colors.white24),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Выполнено задач',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${state.completedTasks.length} из ${state.tasks.length}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Ставка',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('₽${state.hourlyRate}/час',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Статистика
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.trending_up,
                    title: 'ДОХОД ЗА МЕСЯЦ',
                    value: '₽${_formatNumber(state.monthIncome.toInt())}',
                    subtitle: '↑ 15% от плана',
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.access_time,
                    title: 'ОТРАБОТАНО',
                    value: '${state.weekHours} ч',
                    subtitle: 'На этой неделе',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Задачи на сегодня
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Задачи на сегодня',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${todayTasks.where((t) => t.isDone).length} из ${todayTasks.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            SizedBox(height: 12),
            
            ...todayTasks.take(3).map((task) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: TaskItem(task: task),
            )),

            if (todayTasks.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Нет задач на сегодня',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),

            SizedBox(height: 20),

            // Прогресс цели
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Цель на месяц: ₽150,000',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${((state.monthIncome / 150000) * 100).toInt()}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.monthIncome / 150000,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                  ),
                  SizedBox(height: 8),
                  Text('Осталось ₽${_formatNumber((150000 - state.monthIncome).toInt())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ЭКРАН: ФИНАНСЫ
// ============================================================================
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FinanceScreenState createState() {
    return _FinanceScreenState();
  }
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool showStats = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Финансы',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: Icon(Icons.bar_chart, size: 18),
                  label: Text(showStats ? 'Скрыть' : 'Статистика'),
                ),
              ],
            ),
            SizedBox(height: 20),

            if (showStats) ...[
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Финансовая аналитика',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            'Баланс',
                            '₽${_formatNumber(state.balance.toInt())}',
                            state.balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            'Эффективная ставка',
                            '₽${state.hourlyRate}/ч',
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Карточка баланса
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Баланс',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('₽${_formatNumber(state.balance.toInt())}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Доходы',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          Text('+₽${_formatNumber(state.monthIncome.toInt())}',
                              style: TextStyle(
                                  color: Colors.green.shade400,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Расходы',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          Text('-₽${_formatNumber(state.monthExpense.toInt())}',
                              style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Доход vs Расход
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ДОХОД',
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('₽${_formatNumber(state.monthIncome.toInt())}',
                            style: TextStyle(
                                color: Colors.green.shade900,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('${state.weekHours} часов',
                            style: TextStyle(color: Colors.green.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('РАСХОДЫ',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('₽${_formatNumber(state.monthExpense.toInt())}',
                            style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('${((state.monthExpense / state.monthIncome) * 100).toInt()}% от дохода',
                            style: TextStyle(color: Colors.red.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Последние операции
            Text('Последние операции',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...state.transactions.take(5).map((transaction) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.description,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 4),
                        Text(_formatDate(transaction.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    '${transaction.type == TransactionType.income ? '+' : '-'}₽${_formatNumber(transaction.amount.toInt())}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: transaction.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
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

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: color.shade600, fontSize: 11)),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// ЭКРАН: ЗАДАЧИ
// ============================================================================
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TasksScreenState createState() {
    return _TasksScreenState();
  }
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
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Задачи',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showTemplates(context),
                  icon: Icon(Icons.repeat, size: 18),
                  label: Text('Шаблоны'),
                ),
              ],
            ),
          ),

          // Сводка
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Активных задач',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 8),
                        Text('${state.activeTasks.length}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Потенциал дохода',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 8),
                        Text('₽${_formatNumber(totalEarnings)}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: Colors.white24),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Оплачиваемых часов: $totalHoursч',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('Выполнено: ${state.completedTasks.length}',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Фильтры
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Сегодня', 'today', state.todayTasks.length),
                SizedBox(width: 8),
                _buildFilterChip('Все', 'all', state.tasks.length),
                SizedBox(width: 8),
                _buildFilterChip('Оплачиваемые', 'paid', state.paidTasks.length),
                SizedBox(width: 8),
                _buildFilterChip('Личные', 'personal',
                    state.tasks.where((t) => t.type == TaskType.personal).length),
                SizedBox(width: 8),
                _buildFilterChip('Выполнено', 'done', state.completedTasks.length),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Список задач
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text('Нет задач в этой категории',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: TaskItem(
                          task: filteredTasks[index],
                          onDelete: () {
                            state.deleteTask(filteredTasks[index].id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Задача удалена')),
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
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedFilter = value),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showTemplates(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Шаблоны',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...state.templates.map((template) => InkWell(
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(context, template, state);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(template.icon, style: TextStyle(fontSize: 28)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(template.name,
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${template.hours}ч • ₽${_formatNumber(template.hours * template.rate)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.add, color: Colors.blue),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _createFromTemplate(BuildContext context, Template template, AppState state) {
    if (template.type == TemplateType.task) {
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
        SnackBar(content: Text('Задача создана из шаблона!')),
      );
    }
  }
}

// ============================================================================
// ЭКРАН: ГРАФИК
// ============================================================================
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ScheduleScreenState createState() {
    return _ScheduleScreenState();
  }
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('График работы',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: Icon(Icons.bar_chart, size: 18),
                  label: Text(showStats ? 'Скрыть' : 'Статистика'),
                ),
              ],
            ),
            SizedBox(height: 20),

            if (showStats) ...[
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Статистика работы',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            'Всего отработано',
                            '${state.weekHours} ч',
                            Colors.indigo,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            'Заработано',
                            '₽${_formatNumber(state.weekHours * state.hourlyRate)}',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Недельная сводка
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigo.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Эта неделя',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          Text('${state.weekHours} часов',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Заработано',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          Text('₽${_formatNumber(state.weekHours * state.hourlyRate)}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Рабочих дней',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('5 из 7',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Календарь неделя
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatMonth(selectedDate),
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () => setState(() => selectedDate = DateTime.now()),
                        child: Text('Сегодня', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _buildWeekDays(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Расписание на день
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(selectedDate),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Запланировано', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text('$totalHoursч • ₽${_formatNumber(totalEarnings)}',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),

            if (todaySchedule.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Нет записей на этот день',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...todaySchedule.map((session) => Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(12),
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
                              Text(session.title,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue.shade700)),
                              SizedBox(height: 4),
                              Text(session.client,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade600)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₽${_formatNumber(session.hours * session.rate)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue.shade700)),
                            Text('${session.hours}ч × ₽${session.rate}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.blue.shade700),
                        SizedBox(width: 4),
                        Text('${session.startTime} - ${session.endTime}',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700)),
                      ],
                    ),
                  ],
                ),
              )),

            SizedBox(height: 20),

            // Быстрая статистика
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat('Этот месяц', '${state.weekHours * 4}ч', Colors.blue),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildQuickStat('Заработано', '₽${_formatNumber(state.monthIncome.toInt())}', Colors.green),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildQuickStat('Проектов', '3', Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekDays() {
    final weekDays = ['М', 'Т', 'С', 'Ч', 'П', 'С', 'В'];
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
          width: 40,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weekDays[index],
                  style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.grey)),
              SizedBox(height: 4),
              Text('${date.day}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade800)),
              if (isToday)
                Container(
                  margin: EdgeInsets.only(top: 4),
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

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.shade600, fontSize: 11)),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(color: color.shade600, fontSize: 10),
              textAlign: TextAlign.center),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// ЭКРАН: НАСТРОЙКИ
// ============================================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Настройки',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // Premium промо
            if (!state.isPremium)
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.workspace_premium,
                              color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Flow Premium',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text('Разблокируйте все возможности',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        state.updateSettings(premiumValue: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🎉 Добро пожаловать в Premium!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Начать пробный период',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 8),
                    Text('7 дней бесплатно, затем ₽299/мес',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

            // Секции настроек
            _buildSettingsSection(
              context,
              'Аккаунт',
              [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Профиль'),
                  subtitle: Text(state.userName),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text(state.userEmail),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
                SwitchListTile(
                  secondary: Icon(Icons.notifications),
                  title: Text('Уведомления'),
                  value: state.notifications,
                  onChanged: (value) {
                    state.updateSettings(notificationsValue: value);
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildSettingsSection(
              context,
              'Финансы',
              [
                ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Основная ставка'),
                  subtitle: Text('₽${state.hourlyRate}/час'),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showRateDialog(context, state),
                ),
                ListTile(
                  leading: Icon(Icons.currency_exchange),
                  title: Text('Валюта'),
                  subtitle: Text('RUB (₽)'),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildSettingsSection(
              context,
              'Приложение',
              [
                SwitchListTile(
                  secondary: Icon(Icons.dark_mode),
                  title: Text('Тёмная тема'),
                  value: state.darkMode,
                  onChanged: (value) {
                    state.updateSettings(darkModeValue: value);
                  },
                ),
                SwitchListTile(
                  secondary: Icon(Icons.sync),
                  title: Text('Синхронизация'),
                  value: state.sync,
                  onChanged: (value) {
                    state.updateSettings(syncValue: value);
                  },
                ),
              ],
            ),
            SizedBox(height: 32),

            Center(
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Выход'),
                      content: Text('Вы уверены, что хотите выйти?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Вы вышли из аккаунта')),
                            );
                          },
                          child: Text('Выйти', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Выйти из аккаунта',
                    style: TextStyle(color: Colors.red, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Divider(height: 1),
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
        title: Text('Изменить ставку'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Ставка за час',
            suffixText: '₽/час',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final newRate = int.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                state.updateSettings(rateValue: newRate);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ставка обновлена!')),
                );
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// КОМПОНЕНТЫ
// ============================================================================

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const StatCard({super.key, 
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color.shade900,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: color.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onDelete;

  const TaskItem({super.key, required this.task, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    Color getColor() {
      switch (task.priority) {
        case Priority.high:
          return Colors.red;
        case Priority.medium:
          return Colors.orange;
        case Priority.low:
          return Colors.green;
      }
    }

    String getIcon() {
      switch (task.type) {
        case TaskType.paid:
          return '💰';
        case TaskType.personal:
          return '🏠';
        case TaskType.admin:
          return '📋';
      }
    }

    final color = getColor();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
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
                  color: task.isDone ? Colors.blue : Colors.grey.shade400,
                  width: 2,
                ),
                color: task.isDone ? Colors.blue : Colors.transparent,
              ),
              child: task.isDone
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(getIcon(), style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(task.deadline),
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (task.type == TaskType.paid) ...[
                      SizedBox(width: 12),
                      Text(
                        '${task.hours}ч • ₽${_formatNumber(task.hours * task.rate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null) ...[
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
              onPressed: onDelete,
              constraints: BoxConstraints(),
              padding: EdgeInsets.all(8),
            ),
          ],
        ],
      ),
    );
  }
}

class AddMenuSheet extends StatelessWidget {
  const AddMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Добавить',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildMenuItem(
            context,
            icon: Icons.check_box,
            title: 'Новая задача',
            subtitle: 'Создать задачу с дедлайном',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              _showAddTaskDialog(context, state);
            },
          ),
          SizedBox(height: 8),
          
          _buildMenuItem(
            context,
            icon: Icons.calendar_today,
            title: 'Запись в графике',
            subtitle: 'Запланировать рабочее время',
            color: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              _showAddScheduleDialog(context, state);
            },
          ),
          SizedBox(height: 8),
          
          _buildMenuItem(
            context,
            icon: Icons.attach_money,
            title: 'Доход/Расход',
            subtitle: 'Добавить финансовую операцию',
            color: Colors.green,
            onTap: () {
              Navigator.pop(context);
              _showAddTransactionDialog(context, state);
            },
          ),
          SizedBox(height: 8),
          
          _buildMenuItem(
            context,
            icon: Icons.flag,
            title: 'Цель',
            subtitle: 'Установить финансовую цель',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Функция в разработке')),
              );
            },
          ),
        ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppState state) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final hoursController = TextEditingController(text: '2');
    TaskType selectedType = TaskType.paid;
    Priority selectedPriority = Priority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Новая задача'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<TaskType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Тип',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: TaskType.paid, child: Text('💰 Оплачиваемая')),
                    DropdownMenuItem(value: TaskType.personal, child: Text('🏠 Личная')),
                    DropdownMenuItem(value: TaskType.admin, child: Text('📋 Административная')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                SizedBox(height: 12),
                if (selectedType == TaskType.paid)
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Часы',
                      suffixText: 'ч',
                      border: OutlineInputBorder(),
                    ),
                  ),
                SizedBox(height: 12),
                DropdownButtonFormField<Priority>(
                  initialValue: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Приоритет',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: Priority.high, child: Text('🔴 Высокий')),
                    DropdownMenuItem(value: Priority.medium, child: Text('🟡 Средний')),
                    DropdownMenuItem(value: Priority.low, child: Text('🟢 Низкий')),
                  ],
                  onChanged: (value) => setState(() => selectedPriority = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descController.text,
                    deadline: DateTime.now(),
                    type: selectedType,
                    hours: selectedType == TaskType.paid 
                        ? int.tryParse(hoursController.text) ?? 0 
                        : 0,
                    rate: state.hourlyRate,
                    isDone: false,
                    priority: selectedPriority,
                  );
                  state.addTask(task);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Задача создана!')),
                  );
                }
              },
              child: Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, AppState state) {
    final titleController = TextEditingController();
    final clientController = TextEditingController();
    final hoursController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Новая запись'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: clientController,
                decoration: InputDecoration(
                  labelText: 'Клиент',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Часы',
                  suffixText: 'ч',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final hours = int.tryParse(hoursController.text) ?? 4;
                final session = ScheduleSession(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  startTime: '10:00',
                  endTime: '${10 + hours}:00',
                  client: clientController.text,
                  title: titleController.text,
                  hours: hours,
                  rate: state.hourlyRate,
                );
                state.addScheduleSession(session);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('📅 Запись добавлена!')),
                );
              }
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, AppState state) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    TransactionType selectedType = TransactionType.income;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Новая операция'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Доход'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Расход'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() => selectedType = newSelection.first);
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  prefixText: '₽',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && descController.text.isNotEmpty) {
                  final transaction = Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: selectedType,
                    amount: amount,
                    category: selectedType == TransactionType.income ? 'Работа' : 'Разное',
                    description: descController.text,
                    date: DateTime.now(),
                  );
                  state.addTransaction(transaction);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('💰 Операция добавлена!')),
                  );
                }
              },
              child: Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// УТИЛИТЫ
// ============================================================================

String _formatNumber(int number) {
  return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
}

String _formatDate(DateTime date) {
  final months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];
  final weekdays = [
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
  final months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

// ============================================================================
// ИНСТРУКЦИИ ДЛЯ ДАЛЬНЕЙШЕГО РАЗВИТИЯ
// ============================================================================
/*

ПРИЛОЖЕНИЕ ПОЛНОСТЬЮ ГОТОВО К ИСПОЛЬЗОВАНИЮ! 🎉

ЧТО УЖЕ РАБОТАЕТ:
==================
✅ Все 5 экранов (Главная, Финансы, Задачи, График, Настройки)
✅ Добавление задач, транзакций, записей в график
✅ Фильтрация задач (сегодня, все, оплачиваемые, личные, выполнено)
✅ Отметка задач как выполненных
✅ Удаление задач
✅ Шаблоны для быстрого создания
✅ Статистика по финансам и графику
✅ Интерактивный календарь
✅ Изменение ставки
✅ Переключатели настроек
✅ Premium промо
✅ Форматирование чисел и дат
✅ State Management через Provider

КАК ЗАПУСТИТЬ:
==============
1. Создайте проект:
   flutter create flow_app
   cd flow_app

2. Установите зависимости:
   flutter pub add provider

3. Замените lib/main.dart этим кодом

4. Запустите:
   flutter run

ЧТО ДОБАВИТЬ ДЛЯ ПРОДАКШЕНА:
============================

1. БАЗА ДАННЫХ (Firebase/Supabase)
   - Регистрация и вход пользователей
   - Сохранение данных в облаке
   - Синхронизация между устройствами
   
2. ЛОКАЛЬНАЯ БАЗА (Hive/SQLite)
   - Оффлайн режим
   - Быстрое чтение данных
   
3. РАСШИРЕННЫЕ ФУНКЦИИ
   - Редактирование задач
   - Категории расходов с бюджетами
   - Экспорт в PDF/Excel
   - Графики (fl_chart пакет)
   - Уведомления (flutter_local_notifications)
   - Календарь (table_calendar)
   
4. ПЛАТЕЖИ
   - in_app_purchase для подписок
   - stripe_payment для веб
   
5. УЛУЧШЕНИЯ UX
   - Анимации (Hero, PageRouteBuilder)
   - Skeleton loaders
   - Pull-to-refresh
   - Swipe to delete
   
6. ПУБЛИКАЦИЯ
   - Иконки и splash screen
   - Подготовка скриншотов
   - App Store / Google Play

СТОИМОСТЬ ДОРАБОТКИ:
====================
Текущее состояние: MVP готов (70% функционала)
Осталось: 30% (база данных, аутентификация, публикация)

Если нанимать разработчика:
- 2-4 недели работы
- ₽100,000 - ₽200,000

Или можете доработать сами, изучив Flutter! 🚀

*/// ============================================================================
// FLOW APP - ПОЛНОЕ ПРИЛОЖЕНИЕ НА FLUTTER
// ============================================================================
// Приложение для учёта финансов, задач и графика работы
// 
// УСТАНОВКА:
// 1. flutter create flow_app
// 2. Скопировать этот код в lib/main.dart
// 3. flutter pub add provider uuid intl
// 4. flutter run
// ============================================================================
