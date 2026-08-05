import '../widgets/enhanced_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task_model.dart';
import '../models/shift_model.dart';
import '../widgets/calendar_week_view.dart';
import '../screens/edit_shift_screen.dart';
import '../screens/edit_task_screen.dart';
import '../providers/subscription_provider.dart';
import '../widgets/ad_banner.dart';
import 'main_screen.dart';

enum CalendarViewType { month, week }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  CalendarViewType _viewType = CalendarViewType.month;

  final PageController _monthPageController = PageController(initialPage: 1000);
  final PageController _weekPageController = PageController(initialPage: 1000);

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  // Хранит месяц, который сейчас загружается — защита от race condition
  DateTime? _loadingForMonth;
  // Debounce-таймер для перелистывания — не грузим Firestore при каждом кадре свайпа
  Timer? _pageChangeDebounce;

  double _monthEarnings = 0.0;
  double _monthHours = 0.0;
  int _monthTasks = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _pageChangeDebounce?.cancel();
    _monthPageController.dispose();
    _weekPageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // Запоминаем, для какого месяца начали загрузку
    final targetMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    _loadingForMonth = targetMonth;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

      final shiftsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final tasksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      // Если пользователь уже перелистал на другой месяц — отбрасываем устаревший результат
      if (!mounted || _loadingForMonth != targetMonth) return;

      final newEvents = <DateTime, List<dynamic>>{};
      double earnings = 0.0;
      double hours = 0.0;
      int tasks = 0;

      for (var doc in shiftsSnap.docs) {
        final shift = ShiftModel.fromSnapshot(doc);
        final dateKey = DateTime(shift.date.year, shift.date.month, shift.date.day);
        newEvents[dateKey] = [...(newEvents[dateKey] ?? []), shift];
        earnings += shift.totalEarnings;
        hours += shift.totalHours;
      }

      for (var doc in tasksSnap.docs) {
        final task = TaskModel.fromSnapshot(doc);
        final dateKey = DateTime(task.date.year, task.date.month, task.date.day);
        newEvents[dateKey] = [...(newEvents[dateKey] ?? []), task];
        tasks++;
      }

      if (mounted && _loadingForMonth == targetMonth) {
        _fadeController.reset();
        setState(() {
          _events = newEvents;
          _monthEarnings = earnings;
          _monthHours = hours;
          _monthTasks = tasks;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      print('Ошибка загрузки: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isDark = settings.isDarkMode;

    return AnimatedBackground(
      isDark: isDark,
      child: Column(
        children: [
          if (!subscriptionProvider.isActive) const AdBanner(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  _buildStatsBar(isDark),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _viewType == CalendarViewType.month
                              ? _buildMonthViewWithSwipe(isDark)
                              : _buildWeekViewWithSwipe(isDark),
                        ),
                        if (_isLoading) _buildLoadingState(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1a1a2e)
              : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b7ff5)),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMonthName(_focusedMonth.month),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_focusedMonth.year}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

          // View toggle — solid container, no blur
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1a1a2e)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildViewButton(
                  icon: Icons.calendar_month,
                  isSelected: _viewType == CalendarViewType.month,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _viewType = CalendarViewType.month);
                  },
                  isDark: isDark,
                ),
                _buildViewButton(
                  icon: Icons.view_week,
                  isSelected: _viewType == CalendarViewType.week,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _viewType = CalendarViewType.week);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              final today = DateTime.now();
              setState(() {
                _selectedDate = today;
                _focusedMonth = today;
              });

              if (_viewType == CalendarViewType.month) {
                _monthPageController.jumpToPage(1000);
              } else {
                _weekPageController.jumpToPage(1000);
              }

              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8b7ff5),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8b7ff5).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Сегодня',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8b7ff5) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : isDark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.black.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    final accent = Provider.of<SettingsProvider>(context, listen: false).accentColor;
    final currency = Provider.of<SettingsProvider>(context, listen: false).currencySymbol;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem(
              '$currency${_monthEarnings.toStringAsFixed(0)}',
              'Заработано',
              Icons.payments_rounded,
              const Color(0xFF10b981),
              isDark,
              isFirst: true,
            ),
            _buildStatDivider(isDark),
            _buildStatItem(
              '${_monthHours.toStringAsFixed(0)}ч',
              'Отработано',
              Icons.schedule_rounded,
              accent,
              isDark,
            ),
            _buildStatDivider(isDark),
            _buildStatItem(
              '$_monthTasks',
              'Задач',
              Icons.check_circle_outline,
              const Color(0xFF3b82f6),
              isDark,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 44,
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.06),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isDark, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(20) : Radius.zero,
            topRight: isLast ? const Radius.circular(20) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.black.withOpacity(0.4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthViewWithSwipe(bool isDark) {
    return PageView.builder(
      controller: _monthPageController,
      onPageChanged: (index) {
        final monthsOffset = index - 1000;
        final baseDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        final newMonth = DateTime(baseDate.year, baseDate.month + monthsOffset, 1);

        setState(() => _focusedMonth = newMonth);

        // Debounce: грузим данные только когда пользователь остановился (300 мс)
        _pageChangeDebounce?.cancel();
        _pageChangeDebounce = Timer(const Duration(milliseconds: 300), _loadData);
      },
      itemBuilder: (context, index) {
        // ВАЖНО: база всегда DateTime.now(), а не _focusedMonth
        // Иначе при смещении _focusedMonth смещение offset применяется дважды
        final monthsOffset = index - 1000;
        final baseMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
        final month = DateTime(baseMonth.year, baseMonth.month + monthsOffset, 1);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            children: [
              _buildMonthGrid(month, isDark),
              const SizedBox(height: 20),
              _buildDayEvents(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekViewWithSwipe(bool isDark) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (!subscriptionProvider.canAccessWeekView) {
      return _buildPremiumRequiredView();
    }

    return PageView.builder(
      controller: _weekPageController,
      onPageChanged: (index) {
        final weeksOffset = index - 1000;
        final now = DateTime.now();
        final weekStart = _getWeekStart(now).add(Duration(days: weeksOffset * 7));

        setState(() {
          _focusedMonth = weekStart;
        });
      },
      itemBuilder: (context, index) {
        final weeksOffset = index - 1000;
        final now = DateTime.now();
        final weekStart = _getWeekStart(now).add(Duration(days: weeksOffset * 7));

        return CalendarWeekView(
          selectedDate: _selectedDate,
          weekStart: weekStart,
          shifts: _getShiftsForWeek(weekStart),
          tasks: _getTasksForWeek(weekStart),
          isDark: isDark,
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
          },
          onEventTap: (event) => _handleEventTap(event),
          onEventMoved: (event, newDate, newTime) => _handleEventMove(event, newDate, newTime),
          onWeekChanged: (newWeekStart) {
            setState(() {
              _focusedMonth = newWeekStart;
            });
          },
        );
      },
    );
  }

  List<ShiftModel> _getShiftsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _events.entries
        .where((entry) =>
          entry.key.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          entry.key.isBefore(weekEnd))
        .expand((entry) => entry.value)
        .whereType<ShiftModel>()
        .toList();
  }

  List<TaskModel> _getTasksForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _events.entries
        .where((entry) =>
          entry.key.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          entry.key.isBefore(weekEnd))
        .expand((entry) => entry.value)
        .whereType<TaskModel>()
        .toList();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildMonthGrid(DateTime month, bool isDark) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'].map((day) {
              return SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox();
              }

              final day = dayOffset + 1;
              final date = DateTime(month.year, month.month, day);
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;
              final hasEvents = _events[date]?.isNotEmpty ?? false;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = date);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8b7ff5)
                        : (isToday
                            ? (isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.06))
                            : null),
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: const Color(0xFF8b7ff5).withOpacity(0.5),
                            width: 2,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8b7ff5).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF1e293b)),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      if (hasEvents && !isSelected)
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildEventIndicators(date, isDark),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventIndicators(DateTime date, bool isDark) {
    final events = _events[date] ?? [];
    final indicators = <Widget>[];

    final hasShifts = events.any((e) => e is ShiftModel);
    final hasTasks = events.any((e) => e is TaskModel);

    if (hasShifts) {
      indicators.add(
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            color: Color(0xFF8b7ff5),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    if (hasTasks) {
      indicators.add(
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            color: Color(0xFF10b981),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return indicators;
  }

  Widget _buildDayEvents(bool isDark) {
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dayEvents = _events[dateKey] ?? [];

    if (dayEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const Text(
                '📅',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                'Нет событий',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    dayEvents.sort((a, b) {
      final aTime = a is ShiftModel ? a.startTime : (a as TaskModel).startTime;
      final bTime = b is ShiftModel ? b.startTime : (b as TaskModel).startTime;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    return Column(
      children: dayEvents.map((event) {
        if (event is ShiftModel) {
          return _buildShiftCard(event, isDark);
        } else {
          return _buildTaskCard(event as TaskModel, isDark);
        }
      }).toList(),
    );
  }

  Widget _buildShiftCard(ShiftModel shift, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _handleEventTap(shift);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: shift.color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: shift.color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shift.timeRange} • ${_calculateShiftHours(shift).toStringAsFixed(1)}ч',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: shift.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shift.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${shift.totalEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, bool isDark) {
    final priorityColor = task.getPriorityColor();
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _handleEventTap(task);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: priorityColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();

                  try {
                    final authProvider = context.read<AuthProvider>();
                    final userId = authProvider.userId;

                    // Обновляем статус в Firebase
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('tasks')
                        .doc(task.id)
                        .update({'isDone': !task.isDone});

                    // Перезагружаем данные
                    await _loadData();

                    // Показываем снекбар
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                task.isDone ? Icons.cancel : Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(task.isDone ? 'Задача не выполнена' : 'Задача выполнена!'),
                            ],
                          ),
                          backgroundColor: task.isDone ? const Color(0xFFf59e0b) : const Color(0xFF10b981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Ошибка обновления задачи: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Ошибка обновления задачи'),
                            ],
                          ),
                          backgroundColor: const Color(0xFFef4444),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: task.isDone ? priorityColor : null,
                    border: Border.all(
                      color: priorityColor,
                      width: 2.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                        letterSpacing: -0.3,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.time != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.black.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.timeRangeString,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  task.getPriorityIcon(),
                  size: 18,
                  color: priorityColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleEventTap(dynamic event) {
    if (event is ShiftModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditShiftScreen(shift: event),
        ),
      ).then((result) {
        if (result == true) _loadData();
      });
    } else if (event is TaskModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditTaskScreen(task: event),
        ),
      ).then((result) {
        if (result == true) _loadData();
      });
    }
  }

  Future<void> _handleEventMove(Object event, DateTime newDate, TimeOfDay newTime) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    try {
      if (event is ShiftModel) {
        final newStartTime = DateTime(
          newDate.year, newDate.month, newDate.day,
          newTime.hour, newTime.minute,
        );
        final duration = event.endTime.difference(event.startTime);
        final newEndTime = newStartTime.add(duration);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('shifts')
            .doc(event.id)
            .update({
          'date': Timestamp.fromDate(newDate),
          'startTime': Timestamp.fromDate(newStartTime),
          'endTime': Timestamp.fromDate(newEndTime),
        });

      } else if (event is TaskModel) {
        final newStartTime = DateTime(
          newDate.year, newDate.month, newDate.day,
          newTime.hour, newTime.minute,
        );

        DateTime? newEndTime;
        if (event.endTime != null && event.startTime != null) {
          final duration = event.endTime!.difference(event.startTime!);
          newEndTime = newStartTime.add(duration);
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(event.id)
            .update({
          'date': Timestamp.fromDate(newDate),
          'startTime': Timestamp.fromDate(newStartTime),
          'endTime': newEndTime != null ? Timestamp.fromDate(newEndTime) : null,
        });
      }

      HapticFeedback.heavyImpact();
      await _loadData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Событие перемещено'),
              ],
            ),
            backgroundColor: const Color(0xFF10b981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      print('Ошибка перемещения события: $e');
      HapticFeedback.heavyImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Ошибка перемещения'),
              ],
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }

  double _calculateShiftHours(ShiftModel shift) {
    Duration duration = shift.endTime.difference(shift.startTime);

    // Если смена через полночь
    if (duration.isNegative) {
      duration = duration + const Duration(days: 1);
    }

    return duration.inMinutes / 60.0;
  }

  Widget _buildPremiumRequiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week_outlined,
              size: 80,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Недельный вид - Premium',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Недельный вид календаря доступен только с Premium подпиской',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GlassButton(
              text: 'Получить Premium',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialTab: 3),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
