import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;

// Инициализация уведомлений
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация уведомлений
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
      child: FlowApp(),
    ),
  );
}

// ============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ЦВЕТОВ (ИСПРАВЛЕНИЕ ПРОБЛЕМЫ С .shade)
// ============================================================================

MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class AppColors {
  static final green = createMaterialColor(Colors.green);
  static final purple = createMaterialColor(Colors.purple);
  static final blue = createMaterialColor(Colors.blue);
  static final red = createMaterialColor(Colors.red);
  static final orange = createMaterialColor(Colors.orange);
  static final indigo = createMaterialColor(Colors.indigo);
  static final grey = createMaterialColor(Colors.grey);
}

// ============================================================================
// СЕРВИС УВЕДОМЛЕНИЙ
// ============================================================================

class NotificationService {
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidDetails = 
    AndroidNotificationDetails(
    'flow_channel',
    'Flow Notifications',
    channelDescription: 'Уведомления о задачах и целях',
    importance: Importance.high,
  );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    final NotificationDetails details = NotificationDetails(
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

class AndroidNotificationPriority {
  static const int high = 1;
}

class FlowApp extends StatelessWidget {
  FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

class AppState extends ChangeNotifier {
  String userName = 'Даниил';
  String userEmail = 'daniil@flow.app';
  int hourlyRate = 750;
  bool isPremium = false;
  bool notifications = true;
  bool darkMode = false;
  bool sync = true;
  
  final List<Task> _tasks = [];

  AppState() {
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
        deadline: DateTime.now().add(const Duration(days: 1)),
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
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '4',
      type: TransactionType.expense,
      amount: 5000,
      category: 'Транспорт',
      description: 'Такси',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '5',
      type: TransactionType.expense,
      amount: 8000,
      category: 'Развлечения',
      description: 'Кино и ужин',
      date: DateTime.now().subtract(const Duration(days: 3)),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: AppColors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddMenuSheet(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доброе утро, ${state.userName} 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(DateTime.now()),
              style: TextStyle(fontSize: 14, color: AppColors.grey[600]),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                          const Text('Сегодня запланировано',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('$todayHours ч',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Прогноз дохода',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('₽${_formatNumber(todayEarnings)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Выполнено задач',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${state.completedTasks.length} из ${state.tasks.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Ставка',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('₽${state.hourlyRate}/час',
                              style: const TextStyle(
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
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.trending_up,
                    title: 'ДОХОД ЗА МЕСЯЦ',
                    value: '₽${_formatNumber(state.monthIncome.toInt())}',
                    subtitle: '↑ 15% от плана',
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.access_time,
                    title: 'ОТРАБОТАНО',
                    value: '${state.weekHours} ч',
                    subtitle: 'На этой неделе',
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Задачи на сегодня',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${todayTasks.where((t) => t.isDone).length} из ${todayTasks.length}',
                    style: TextStyle(fontSize: 12, color: AppColors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            
            ...todayTasks.take(3).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskItem(task: task),
            )),

            if (todayTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Нет задач на сегодня',
                      style: TextStyle(color: AppColors.grey[600])),
                ),
              ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Цель на месяц: ₽150,000',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${((state.monthIncome / 150000) * 100).toInt()}%',
                          style: TextStyle(fontSize: 12, color: AppColors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.monthIncome / 150000,
                    backgroundColor: AppColors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text('Осталось ₽${_formatNumber((150000 - state.monthIncome).toInt())}',
                      style: TextStyle(fontSize: 12, color: AppColors.grey[600])),
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
// ЭКРАН: ФИНАНСЫ С ГРАФИКАМИ
// ============================================================================

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

    // Группируем расходы по категориям
    final Map<String, double> categoryExpenses = {};
    for (var transaction in state.transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryExpenses[transaction.category] =
            (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Финансы',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: Text(showStats ? 'Скрыть' : 'Статистика'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // График доходов/расходов
            if (showStats) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Доходы и расходы за неделю',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    FinanceChart(transactions: state.transactions),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Круговая диаграмма
              if (categoryExpenses.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Распределение расходов',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      ExpensePieChart(categoryExpenses: categoryExpenses),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.grey[800]!, AppColors.grey[900]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Баланс',
                      style: TextStyle(color: AppColors.grey[400], fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₽${_formatNumber(state.balance.toInt())}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Доходы',
                              style: TextStyle(color: AppColors.grey[400], fontSize: 14)),
                          Text('+₽${_formatNumber(state.monthIncome.toInt())}',
                              style: TextStyle(
                                  color: AppColors.green[400],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Расходы',
                              style: TextStyle(color: AppColors.grey[400], fontSize: 14)),
                          Text('-₽${_formatNumber(state.monthExpense.toInt())}',
                              style: TextStyle(
                                  color: AppColors.red[400],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ДОХОД',
                            style: TextStyle(
                                color: AppColors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('₽${_formatNumber(state.monthIncome.toInt())}',
                            style: TextStyle(
                                color: AppColors.green[900],
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${state.weekHours} часов',
                            style: TextStyle(color: AppColors.green[600], fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('РАСХОДЫ',
                            style: TextStyle(
                                color: AppColors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('₽${_formatNumber(state.monthExpense.toInt())}',
                            style: TextStyle(
                                color: AppColors.red[900],
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${((state.monthExpense / state.monthIncome) * 100).toInt()}% от дохода',
                            style: TextStyle(color: AppColors.red[600], fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Последние операции',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...state.transactions.take(5).map((transaction) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.description,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(_formatDate(transaction.date),
                            style: TextStyle(fontSize: 12, color: AppColors.grey[600])),
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
}

// ============================================================================
// ГРАФИКИ
// ============================================================================

class FinanceChart extends StatelessWidget {
  final List<Transaction> transactions;

  const FinanceChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<int, double> incomeByDay = {};
    final Map<int, double> expenseByDay = {};
    
    for (int i = 0; i < 7; i++) {
      incomeByDay[i] = 0;
      expenseByDay[i] = 0;
    }
    
    for (var transaction in transactions) {
      final dayIndex = transaction.date.weekday - 1;
      if (transaction.type == TransactionType.income) {
        incomeByDay[dayIndex] = (incomeByDay[dayIndex] ?? 0) + transaction.amount;
      } else {
        expenseByDay[dayIndex] = (expenseByDay[dayIndex] ?? 0) + transaction.amount;
      }
    }

    final maxY = math.max(
      incomeByDay.values.reduce((a, b) => a > b ? a : b),
      expenseByDay.values.reduce((a, b) => a > b ? a : b),
    ) * 1.2;

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY > 0 ? maxY : 1000,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                    return Text(days[value.toInt()],
                        style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: incomeByDay[index] ?? 0,
                    color: Colors.green,
                    width: 10,
                  ),
                  BarChartRodData(
                    toY: expenseByDay[index] ?? 0,
                    color: Colors.red,
                    width: 10,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> categoryExpenses;

  const ExpensePieChart({super.key, required this.categoryExpenses});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PieChart(
          PieChartData(
            sections: categoryExpenses.entries.map((entry) {
              final index = categoryExpenses.keys.toList().indexOf(entry.key);
              return PieChartSectionData(
                value: entry.value,
                title: '${entry.key}\n₽${_formatNumber(entry.value.toInt())}',
                color: colors[index % colors.length],
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Задачи',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showTemplates(context),
                  icon: const Icon(Icons.repeat, size: 18),
                  label: const Text('Шаблоны'),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple, AppColors.purple[700]!],
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
                        const Text('Активных задач',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('${state.activeTasks.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Потенциал дохода',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('₽${_formatNumber(totalEarnings)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Оплачиваемых часов: ${totalHours}ч',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('Выполнено: ${state.completedTasks.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 16),

          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text('Нет задач в этой категории',
                        style: TextStyle(color: AppColors.grey[600])),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskItem(
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
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedFilter = value),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.grey[700],
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showTemplates(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Шаблоны',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...state.templates.map((template) => InkWell(
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
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey[200]!),
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
                          Text(template.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${template.hours}ч • ₽${_formatNumber(template.hours * template.rate)}',
                              style: TextStyle(fontSize: 12, color: AppColors.grey[600])),
                        ],
                      ),
                    ),
                    const Icon(Icons.add, color: Colors.blue),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ЭКРАН: ГРАФИК
// ============================================================================

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('График работы',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => showStats = !showStats),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: Text(showStats ? 'Скрыть' : 'Статистика'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (showStats) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Статистика работы',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.indigo[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Всего отработано',
                                    style: TextStyle(color: AppColors.indigo[600], fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('${state.weekHours} ч',
                                    style: TextStyle(
                                        color: AppColors.indigo[900],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Заработано',
                                    style: TextStyle(color: AppColors.green[600], fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('₽${_formatNumber(state.weekHours * state.hourlyRate)}',
                                    style: TextStyle(
                                        color: AppColors.green[900],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.indigo, AppColors.indigo[700]!],
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
                          const Text('Эта неделя',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('${state.weekHours} часов',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Заработано',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('₽${_formatNumber(state.weekHours * state.hourlyRate)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
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
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatMonth(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () => setState(() => selectedDate = DateTime.now()),
                        child: const Text('Сегодня', style: TextStyle(fontSize: 12)),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Запланировано', style: TextStyle(fontSize: 11, color: AppColors.grey[600])),
                    Text('${totalHours}ч • ₽${_formatNumber(totalEarnings)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (todaySchedule.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Нет записей на этот день',
                      style: TextStyle(color: AppColors.grey[600])),
                ),
              )
            else
              ...todaySchedule.map((session) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue[50],
                  border: Border.all(color: AppColors.blue[200]!),
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
                                      color: AppColors.blue[700])),
                              const SizedBox(height: 4),
                              Text(session.client,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.blue[600])),
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
                                    color: AppColors.blue[700])),
                            Text('${session.hours}ч × ₽${session.rate}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.blue[600])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.blue[700]),
                        const SizedBox(width: 4),
                        Text('${session.startTime} - ${session.endTime}',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.blue[700])),
                      ],
                    ),
                  ],
                ),
              )),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('Этот месяц',
                            style: TextStyle(color: AppColors.blue[600], fontSize: 10),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('${state.weekHours * 4}ч',
                            style: TextStyle(
                                color: AppColors.blue[700],
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('Заработано',
                            style: TextStyle(color: AppColors.green[600], fontSize: 10),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('₽${_formatNumber(state.monthIncome.toInt())}',
                            style: TextStyle(
                                color: AppColors.green[700],
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('Проектов',
                            style: TextStyle(color: AppColors.purple[600], fontSize: 10),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('3',
                            style: TextStyle(
                                color: AppColors.purple[700],
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekDays() {
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
          width: 40,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : AppColors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weekDays[index],
                  style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppColors.grey[600])),
              const SizedBox(height: 4),
              Text('${date.day}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.grey[800])),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Настройки',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            if (!state.isPremium)
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
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
                          child: const Icon(Icons.workspace_premium,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
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
                    const SizedBox(height: 16),
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
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Начать пробный период',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    const Text('7 дней бесплатно, затем ₽299/мес',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

            _buildSettingsSection(
              context,
              'Аккаунт',
              [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Профиль'),
                  subtitle: Text(state.userName),
                  trailing: Icon(Icons.chevron_right, color: AppColors.grey[600]),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(state.userEmail),
                  trailing: Icon(Icons.chevron_right, color: AppColors.grey[600]),
                  onTap: () {},
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Уведомления'),
                  value: state.notifications,
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
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Основная ставка'),
                  subtitle: Text('₽${state.hourlyRate}/час'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.grey[600]),
                  onTap: () => _showRateDialog(context, state),
                ),
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Валюта'),
                  subtitle: const Text('RUB (₽)'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.grey[600]),
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
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Тёмная тема'),
                  value: state.darkMode,
                  onChanged: (value) {
                    state.updateSettings(darkModeValue: value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('Синхронизация'),
                  value: state.sync,
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
                          child: const Text('Выйти', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Выйти из аккаунта',
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
        border: Border.all(color: AppColors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.grey[700],
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
          TextButton(
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

// ============================================================================
// КОМПОНЕНТЫ
// ============================================================================

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final MaterialColor color;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[50]!, color[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color[900],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: color[600], fontSize: 11),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: AppColors.grey[200]!),
          right: BorderSide(color: AppColors.grey[200]!),
          bottom: BorderSide(color: AppColors.grey[200]!),
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
                  color: task.isDone ? Colors.blue : AppColors.grey[400]!,
                  width: 2,
                ),
                color: task.isDone ? Colors.blue : Colors.transparent,
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(getIcon(), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 13, color: AppColors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: AppColors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.deadline),
                      style: TextStyle(fontSize: 11, color: AppColors.grey[600]),
                    ),
                    if (task.type == TaskType.paid) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${task.hours}ч • ₽${_formatNumber(task.hours * task.rate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.green[600],
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
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: AppColors.red[300]),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Добавить',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              _showAddTaskDialog(context, state);
            },
          ),
          const SizedBox(height: 8),
          
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
          const SizedBox(height: 8),
          
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
          const SizedBox(height: 8),
          
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
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
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey[400]),
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
          title: const Text('Новая задача'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: TaskType.paid, child: Text('💰 Оплачиваемая')),
                    DropdownMenuItem(value: TaskType.personal, child: Text('🏠 Личная')),
                    DropdownMenuItem(value: TaskType.admin, child: Text('📋 Административная')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 12),
                if (selectedType == TaskType.paid)
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Часы',
                      suffixText: 'ч',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Priority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Приоритет',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
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
              child: const Text('Отмена'),
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
                  
                  // Отправить уведомление
                  NotificationService.showNotification(
                    title: 'Задача создана',
                    body: 'Новая задача: ${task.title}',
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Задача создана!')),
                  );
                }
              },
              child: const Text('Создать'),
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
        title: const Text('Новая запись'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clientController,
                decoration: const InputDecoration(
                  labelText: 'Клиент',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
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
            child: const Text('Отмена'),
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
                  const SnackBar(content: Text('📅 Запись добавлена!')),
                );
              }
            },
            child: const Text('Добавить'),
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
          title: const Text('Новая операция'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
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
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  prefixText: '₽',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
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
                    const SnackBar(content: Text('💰 Операция добавлена!')),
                  );
                }
              },
              child: const Text('Добавить'),
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
  const months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
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