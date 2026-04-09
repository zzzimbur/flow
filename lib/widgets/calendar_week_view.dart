import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import '../models/shift_model.dart';
import '../models/task_model.dart';
import '../screens/add_shift_screen.dart';
import '../screens/add_task_screen.dart';

class CalendarWeekView extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime weekStart;
  final List<ShiftModel> shifts;
  final List<TaskModel> tasks;
  final bool isDark;
  final Function(DateTime) onDateChanged;
  final Function(dynamic event) onEventTap;
  final Function(Object event, DateTime newDate, TimeOfDay newTime)? onEventMoved;
  final Function(Object event, DateTime newStartTime, DateTime newEndTime)? onEventResized;
  final Function(DateTime weekStart) onWeekChanged;

  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.weekStart,
    required this.shifts,
    required this.tasks,
    required this.isDark,
    required this.onDateChanged,
    required this.onEventTap,
    this.onEventMoved,
    this.onEventResized,
    required this.onWeekChanged,
  });

  @override
  State<CalendarWeekView> createState() => _CalendarWeekViewState();
}

class _CalendarWeekViewState extends State<CalendarWeekView> {
  final ScrollController _scrollController = ScrollController();
  final double _hourHeight = 60.0;
  final double _headerHeight = 80.0;
  
  final int _startHour = 0;
  final int _endHour = 24;
  
  Timer? _timeUpdateTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(8 * _hourHeight);
      }
    });
    
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) => widget.weekStart.add(Duration(days: index)));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    
    return GestureDetector(
      child: Column(
        children: [
          _buildWeekHeader(weekDays),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeColumn(),
                      Expanded(
                        child: Stack(
                          children: [
                            _buildTimeGrid(weekDays),
                            _buildEventsOverlay(weekDays),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCurrentTimeIndicator(weekDays),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(List<DateTime> weekDays) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: widget.isDark 
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: widget.isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              const SizedBox(width: 60),
              Expanded(
                child: Row(
                  children: weekDays.map((day) {
                    final isToday = _isToday(day);
                    final isSelected = day.day == widget.selectedDate.day &&
                                      day.month == widget.selectedDate.month;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onDateChanged(day);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: widget.isDark 
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getWeekdayName(day.weekday),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isToday
                                      ? const Color(0xFF8b7ff5)
                                      : (widget.isDark 
                                          ? Colors.white60 
                                          : Colors.black45),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF8b7ff5)
                                      : (isToday
                                          ? const Color(0xFF8b7ff5).withOpacity(0.15)
                                          : Colors.transparent),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isToday
                                              ? const Color(0xFF8b7ff5)
                                              : (widget.isDark 
                                                  ? Colors.white 
                                                  : Colors.black87)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn() {
    return SizedBox(
      width: 60,
      child: Column(
        children: List.generate(_endHour - _startHour, (index) {
          final hour = _startHour + index;
          return Container(
            height: _hourHeight,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: Text(
              _formatHour(hour),
              style: TextStyle(
                fontSize: 11,
                color: widget.isDark 
                    ? Colors.white38
                    : Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeGrid(List<DateTime> weekDays) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = (screenWidth - 60) / 7;
    
    return Column(
      children: List.generate(_endHour - _startHour, (hourIndex) {
        return Container(
          height: _hourHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: weekDays.asMap().entries.map((entry) {
              final day = entry.value;
              final hour = _startHour + hourIndex;
              
              return SizedBox(
                width: dayWidth,
                child: DragTarget<Object>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    HapticFeedback.mediumImpact();
                    final newTime = TimeOfDay(hour: hour, minute: 0);
                    
                    if (widget.onEventMoved != null) {
                      widget.onEventMoved!(details.data, day, newTime);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHighlighted = candidateData.isNotEmpty;
                    
                    return GestureDetector(
                      // НОВОЕ: Обработчик долгого нажатия
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        final time = TimeOfDay(hour: hour, minute: 0);
                        _showAddEventDialog(day, time);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFF8b7ff5).withOpacity(0.2)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: widget.isDark 
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  // Диалог выбора типа события
  void _showAddEventDialog(DateTime date, TimeOfDay time) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      const Color(0xFF1e293b).withOpacity(0.95),
                      const Color(0xFF0f172a).withOpacity(0.95),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      const Color(0xFFf8fafc).withOpacity(0.95),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Color(0xFF8b7ff5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Добавить событие',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${date.day}.${date.month}.${date.year} • ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogButton(
                      icon: Icons.work_outline,
                      label: 'Смена',
                      color: const Color(0xFF8b7ff5),
                      onTap: () {
                        Navigator.pop(context); // Закрываем диалог
                        // ИСПРАВЛЕНО: Убрали вызов callback, навигация происходит напрямую
                        _navigateToAddShift(date, time);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogButton(
                      icon: Icons.task_alt,
                      label: 'Задача',
                      color: const Color(0xFF3b82f6),
                      onTap: () {
                        Navigator.pop(context); // Закрываем диалог
                        // ИСПРАВЛЕНО: Убрали вызов callback, навигация происходит напрямую
                        _navigateToAddTask(date, time);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          color: widget.isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Навигация к экранам создания

  // смены
  void _navigateToAddShift(DateTime date, TimeOfDay time) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddShiftScreen(
          initialDate: date,
          initialTime: time,
        ),
      ),
    );
  }
  // задачи
  void _navigateToAddTask(DateTime date, TimeOfDay time) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          initialDate: date,
          initialTime: time,
        ),
      ),
    );
  }

  Widget _buildEventsOverlay(List<DateTime> weekDays) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = (screenWidth - 60) / 7;
    
    return SizedBox(
      height: (_endHour - _startHour) * _hourHeight,
      child: Row(
        children: weekDays.asMap().entries.map((entry) {
          final day = entry.value;
          final dayEvents = _getEventsForDay(day);
          
          final shifts = dayEvents.whereType<ShiftModel>().toList();
          final tasks = dayEvents.whereType<TaskModel>().toList();
          
          return SizedBox(
            width: dayWidth,
            child: Stack(
              children: [
                ...shifts.map((shift) => _buildShiftBlock(shift, day, dayWidth)),
                ...tasks.map((task) => _buildTaskBlock(task, day, dayWidth)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final events = <dynamic>[];
    final currentDay = DateTime(day.year, day.month, day.day);
    
    for (var shift in widget.shifts) {
      final shiftStartDay = DateTime(shift.startTime.year, shift.startTime.month, shift.startTime.day);
      final shiftEndDay = DateTime(shift.endTime.year, shift.endTime.month, shift.endTime.day);
      
      if (currentDay.isAtSameMomentAs(shiftStartDay) || 
          currentDay.isAtSameMomentAs(shiftEndDay) ||
          (currentDay.isAfter(shiftStartDay) && currentDay.isBefore(shiftEndDay))) {
        events.add(shift);
      }
    }
    
    for (var task in widget.tasks) {
      if (task.startTime != null) {
        final taskStartDay = DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day);
        
        if (task.endTime != null) {
          final taskEndDay = DateTime(task.endTime!.year, task.endTime!.month, task.endTime!.day);
          
          if (currentDay.isAtSameMomentAs(taskStartDay) || 
              currentDay.isAtSameMomentAs(taskEndDay) ||
              (currentDay.isAfter(taskStartDay) && currentDay.isBefore(taskEndDay))) {
            events.add(task);
          }
        } else {
          if (currentDay.isAtSameMomentAs(taskStartDay)) {
            events.add(task);
          }
        }
      }
    }
    
    return events;
  }

  Widget _buildShiftBlock(
    ShiftModel shift, 
    DateTime day,
    double dayWidth,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
    
    final effectiveStart = shift.startTime.isBefore(dayStart) ? dayStart : shift.startTime;
    final effectiveEnd = shift.endTime.isAfter(dayEnd) ? dayEnd : shift.endTime;
    
    final startMinutes = effectiveStart.hour * 60 + effectiveStart.minute;
    final endMinutes = effectiveEnd.hour * 60 + effectiveEnd.minute;
    final duration = endMinutes - startMinutes;
    
    final top = (startMinutes / 60) * _hourHeight;
    final height = (duration / 60) * _hourHeight;
    
    final continuesFromPrevDay = shift.startTime.isBefore(dayStart);
    final continuesToNextDay = shift.endTime.isAfter(dayEnd);
    
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height.clamp(40.0, double.infinity),
      child: LongPressDraggable<ShiftModel>(
        data: shift,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: SizedBox(
              width: 80,
              height: 60,
              child: _buildEventCard(
                shift.name,
                shift.color,
                height,
                shift.timeRange,
                continuesFromPrevDay: continuesFromPrevDay,
                continuesToNextDay: continuesToNextDay,
                icon: shift.emoji != null && shift.emoji!.isNotEmpty ? null : shift.icon,
                emoji: shift.emoji,
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildEventCard(
            shift.name,
            shift.color,
            height,
            shift.timeRange,
            continuesFromPrevDay: continuesFromPrevDay,
            continuesToNextDay: continuesToNextDay,
            icon: shift.emoji != null && shift.emoji!.isNotEmpty ? null : shift.icon,
            emoji: shift.emoji,
          ),
        ),
        onDragStarted: () => HapticFeedback.mediumImpact(),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onEventTap(shift);
          },
          child: _buildEventCard(
            shift.name,
            shift.color,
            height,
            shift.timeRange,
            continuesFromPrevDay: continuesFromPrevDay,
            continuesToNextDay: continuesToNextDay,
            icon: shift.emoji != null && shift.emoji!.isNotEmpty ? null : shift.icon,
            emoji: shift.emoji,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskBlock(TaskModel task, DateTime day, double dayWidth) {
    if (task.startTime == null) return const SizedBox();
    
    // используем только ВРЕМЯ из startTime/endTime, но дату из параметра day
    final taskStartHour = task.startTime!.hour;
    final taskStartMinute = task.startTime!.minute;
    
    final startMinutes = taskStartHour * 60 + taskStartMinute;
    
    int endMinutes;
    if (task.endTime != null) {
      final taskEndHour = task.endTime!.hour;
      final taskEndMinute = task.endTime!.minute;
      endMinutes = taskEndHour * 60 + taskEndMinute;
      
      // если endTime меньше startTime, значит задача переходит на следующий день
      // В этом случае показываем только часть задачи в текущем дне
      if (endMinutes < startMinutes) {
        // Проверяем, это день начала или день окончания
        final taskStartDay = DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day);
        final currentDay = DateTime(day.year, day.month, day.day);
        
        if (currentDay.isAtSameMomentAs(taskStartDay)) {
          // Это день начала - показываем до конца дня
          endMinutes = 24 * 60;
        } else {
          // Это день окончания - показываем с начала дня
          return Positioned(
            top: 0,
            left: 4,
            right: 4,
            height: ((taskEndHour * 60 + taskEndMinute) / 60) * _hourHeight,
            child: _buildTaskCardWidget(task, dayWidth - 8, true, false),
          );
        }
      }
    } else {
      // Нет времени окончания - по умолчанию 10 минут
      endMinutes = startMinutes + 10;
    }
    
    final duration = endMinutes - startMinutes;
    
    final top = (startMinutes / 60) * _hourHeight;
    final height = (duration / 60) * _hourHeight;
    
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height.clamp(30.0, double.infinity),
      child: _buildTaskCardWidget(task, dayWidth - 8, false, false),
    );
  }

  // Выносим виджет карточки в отдельный метод
  Widget _buildTaskCardWidget(TaskModel task, double width, bool isStart, bool isEnd) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onEventTap(task);
      },
      child: LongPressDraggable<TaskModel>(
        data: task,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: SizedBox(
              width: 100,
              height: 60,
              child: _buildTaskCard(task, width),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildTaskCard(task, width),
        ),
        onDragStarted: () {
          HapticFeedback.mediumImpact();
        },
        child: _buildTaskCard(task, width),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, double width) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            task.getPriorityColor().withOpacity(0.85),
            task.getPriorityColor().withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.getPriorityColor(),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: task.getPriorityColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: Colors.white,
          ),
          if (width > 30) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(
    String title, 
    Color color, 
    double height,
    String time, {
    bool continuesFromPrevDay = false,
    bool continuesToNextDay = false,
    IconData? icon,
    String? emoji,
  }) {
    final isSmall = height < 40;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(continuesFromPrevDay ? 0 : 8),
          topRight: Radius.circular(continuesFromPrevDay ? 0 : 8),
          bottomLeft: Radius.circular(continuesToNextDay ? 0 : 8),
          bottomRight: Radius.circular(continuesToNextDay ? 0 : 8),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(continuesFromPrevDay ? 0 : 8),
          topRight: Radius.circular(continuesFromPrevDay ? 0 : 8),
          bottomLeft: Radius.circular(continuesToNextDay ? 0 : 8),
          bottomRight: Radius.circular(continuesToNextDay ? 0 : 8),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(continuesFromPrevDay ? 0 : 8),
                topRight: Radius.circular(continuesFromPrevDay ? 0 : 8),
                bottomLeft: Radius.circular(continuesToNextDay ? 0 : 8),
                bottomRight: Radius.circular(continuesToNextDay ? 0 : 8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Используем LayoutBuilder для адаптивного отображения
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Если ширина меньше 35px - показываем только иконку/эмодзи
                    if (constraints.maxWidth < 35) {
                      return Center(
                        child: emoji != null && emoji.isNotEmpty
                            ? Text(
                                emoji,
                                style: const TextStyle(fontSize: 12),
                              )
                            : Icon(
                                icon ?? Icons.event,
                                size: 10,
                                color: Colors.white,
                              ),
                      );
                    }
                    // Если ширина меньше 60px - показываем без стрелок
                    if (constraints.maxWidth < 60) {
                      return Row(
                        children: [
                          if (emoji != null && emoji.isNotEmpty)
                            Text(
                              emoji,
                              style: const TextStyle(fontSize: 12),
                            )
                          else if (icon != null)
                            Icon(
                              icon,
                              size: 10,
                              color: Colors.white,
                            ),
                          
                          if ((emoji != null && emoji.isNotEmpty) || icon != null)
                            const SizedBox(width: 3),
                          
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }
                    // Полное отображение со всеми элементами
                    return Row(
                      children: [
                        if (emoji != null && emoji.isNotEmpty)
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 14),
                          )
                        else if (icon != null)
                          Icon(
                            icon,
                            size: 12,
                            color: Colors.white,
                          ),
                        
                        if ((emoji != null && emoji.isNotEmpty) || icon != null)
                          const SizedBox(width: 4),
                        
                        if (continuesFromPrevDay)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.arrow_upward, 
                              size: 8, 
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: isSmall ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        if (continuesToNextDay)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.arrow_downward, 
                              size: 8, 
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (!isSmall && height > 50) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(List<DateTime> weekDays) {
    final todayIndex = weekDays.indexWhere((day) => _isToday(day));
    
    if (todayIndex == -1) return const SizedBox();

    final minutes = _currentTime.hour * 60 + _currentTime.minute;
    final linePositionInContent = (minutes / 60) * _hourHeight;
    
    final currentScroll = _scrollController.hasClients ? _scrollController.offset : 0;
    final visibleTop = linePositionInContent - currentScroll;
    
    if (visibleTop < 0 || visibleTop > MediaQuery.of(context).size.height - _headerHeight) {
      return const SizedBox();
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = (screenWidth - 60) / 7;
    final todayLeft = 60 + (todayIndex * dayWidth);
    
    return Positioned(
      top: visibleTop,
      left: todayLeft,
      width: dayWidth,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A84FF).withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    return names[weekday - 1];
  }

  String _formatHour(int hour) {
    if (hour == 0) return '00:00';
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}