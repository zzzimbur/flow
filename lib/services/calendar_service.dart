import 'package:device_calendar_plus/device_calendar_plus.dart';
import '../models/shift_model.dart';
import '../models/task_model.dart';

class CalendarService {
  // Singleton — так правильно в новом пакете
  final _plugin = DeviceCalendar.instance;

  /// Запрос разрешений на доступ к календарю
  Future<bool> requestPermissions() async {
    final status = await _plugin.requestPermissions();
    return status == CalendarPermissionStatus.granted;
  }

  /// Экспорт одной смены в системный календарь
  Future<void> exportShiftToSystemCalendar(ShiftModel shift) async {
    if (!await requestPermissions()) {
      throw Exception('Нет доступа к календарю');
    }

    final calendarsResult = await _plugin.listCalendars();
    if (calendarsResult.isEmpty) {
      throw Exception('Не найдено ни одного календаря');
    }

    final calendarId = calendarsResult.first.id;

    await _plugin.createEvent(
      calendarId: calendarId,
      title: shift.name,
      description:
          '${shift.category}\nЗаработок: ₽${shift.totalEarnings.toStringAsFixed(0)}',
      startDate: shift.startTime, // обычный DateTime — локальное время
      endDate: shift.endTime,
      isAllDay: shift.isAllDay,
    );
  }

  /// Экспорт одной задачи в системный календарь
  Future<void> exportTaskToSystemCalendar(TaskModel task) async {
    if (!await requestPermissions()) {
      throw Exception('Нет доступа к календарю');
    }

    final calendarsResult = await _plugin.listCalendars();
    if (calendarsResult.isEmpty) {
      throw Exception('Не найдено ни одного календаря');
    }

    final calendarId = calendarsResult.first.id;

    // Определяем время начала и конца
    DateTime startDateTime = task.date;
    DateTime endDateTime = task.date;

    if (task.time != null) {
      startDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time!.hour,
        task.time!.minute,
      );
      endDateTime = startDateTime.add(const Duration(hours: 1));
    } else {
      // Для all-day событий конец = начало + 1 день
      endDateTime = startDateTime.add(const Duration(days: 1));
    }

    await _plugin.createEvent(
      calendarId: calendarId,
      title: task.title,
      description:
          '${task.category}\nПриоритет: ${task.getPriorityLabel()}',
      startDate: startDateTime,
      endDate: endDateTime,
      isAllDay: task.time == null,
    );
  }

  /// Импорт событий из системного календаря за период
  Future<List<Event>> importFromSystemCalendar(DateTime start, DateTime end) async {
    if (!await requestPermissions()) {
      throw Exception('Нет доступа к календарю');
    }

    final calendarsResult = await _plugin.listCalendars();
    if (calendarsResult.isEmpty) return [];

    final calendarIds = calendarsResult.map((c) => c.id).toList();

    final events = await _plugin.listEvents(
      start,
      end,
      calendarIds: calendarIds,
    );

    return events;
  }

  /// Экспорт всех смен
  Future<void> exportAllShifts(List<ShiftModel> shifts) async {
    for (var shift in shifts) {
      try {
        await exportShiftToSystemCalendar(shift);
      } catch (e) {
        // Рекомендую заменить print на logger в продакшене
        print('Ошибка экспорта смены ${shift.name}: $e');
      }
    }
  }

  /// Экспорт всех задач
  Future<void> exportAllTasks(List<TaskModel> tasks) async {
    for (var task in tasks) {
      try {
        await exportTaskToSystemCalendar(task);
      } catch (e) {
        print('Ошибка экспорта задачи ${task.title}: $e');
      }
    }
  }
}