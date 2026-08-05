import 'package:device_calendar_plus/device_calendar_plus.dart';
import '../models/shift_model.dart';
import '../models/task_model.dart';

class CalendarService {
  final _plugin = DeviceCalendar.instance;

  Future<bool> requestPermissions() async {
    final status = await _plugin.requestPermissions();
    return status == CalendarPermissionStatus.granted;
  }

  /// Находит первый календарь с правом записи
  Future<String> _writableCalendarId() async {
    final calendars = await _plugin.listCalendars();
    if (calendars.isEmpty) throw Exception('Нет доступных календарей');
    // Предпочитаем не-read-only; если все read-only — берём первый
    // Предпочитаем primary, иначе первый не read-only
    final primary = calendars.where((c) => c.isPrimary && !c.readOnly).toList();
    final writable = calendars.where((c) => !c.readOnly).toList();
    final chosen = primary.isNotEmpty ? primary.first : (writable.isNotEmpty ? writable.first : calendars.first);
    return chosen.id;
  }

  Future<void> exportShiftToSystemCalendar(ShiftModel shift) async {
    if (!await requestPermissions()) throw Exception('Нет доступа к календарю');
    final calendarId = await _writableCalendarId();
    await _plugin.createEvent(
      calendarId: calendarId,
      title: shift.name,
      description: '${shift.category}\nЗаработок: ${shift.totalEarnings.toStringAsFixed(0)} ₽',
      startDate: shift.startTime,
      endDate: shift.endTime,
      isAllDay: shift.isAllDay,
    );
  }

  Future<void> exportTaskToSystemCalendar(TaskModel task) async {
    if (!await requestPermissions()) throw Exception('Нет доступа к календарю');
    final calendarId = await _writableCalendarId();

    final start = task.time != null
        ? DateTime(task.date.year, task.date.month, task.date.day, task.time!.hour, task.time!.minute)
        : task.date;
    final end = task.time != null
        ? start.add(const Duration(hours: 1))
        : task.date.add(const Duration(days: 1));

    await _plugin.createEvent(
      calendarId: calendarId,
      title: task.title,
      description: '${task.category}\nПриоритет: ${task.getPriorityLabel()}',
      startDate: start,
      endDate: end,
      isAllDay: task.time == null,
    );
  }

  /// Возвращает количество успешно экспортированных смен.
  /// Бросает исключение если ВСЕ упали, иначе возвращает (ok, total).
  Future<({int ok, int total, String? firstError})> exportAllShifts(List<ShiftModel> shifts) async {
    if (!await requestPermissions()) throw Exception('Нет доступа к календарю. Разреши доступ в Настройках → Конфиденциальность → Календарь.');
    final calendarId = await _writableCalendarId();

    int ok = 0;
    String? firstError;
    for (final shift in shifts) {
      try {
        await _plugin.createEvent(
          calendarId: calendarId,
          title: shift.name,
          description: '${shift.category}\nЗаработок: ${shift.totalEarnings.toStringAsFixed(0)} ₽',
          startDate: shift.startTime,
          endDate: shift.endTime,
          isAllDay: shift.isAllDay,
        );
        ok++;
      } catch (e) {
        firstError ??= e.toString();
      }
    }
    return (ok: ok, total: shifts.length, firstError: firstError);
  }

  /// Возвращает (ok, total, firstError) — аналогично смены.
  Future<({int ok, int total, String? firstError})> exportAllTasks(List<TaskModel> tasks) async {
    if (!await requestPermissions()) throw Exception('Нет доступа к календарю. Разреши доступ в Настройках → Конфиденциальность → Календарь.');
    final calendarId = await _writableCalendarId();

    int ok = 0;
    String? firstError;
    for (final task in tasks) {
      try {
        final start = task.time != null
            ? DateTime(task.date.year, task.date.month, task.date.day, task.time!.hour, task.time!.minute)
            : task.date;
        final end = task.time != null
            ? start.add(const Duration(hours: 1))
            : task.date.add(const Duration(days: 1));
        await _plugin.createEvent(
          calendarId: calendarId,
          title: task.title,
          description: '${task.category}\nПриоритет: ${task.getPriorityLabel()}',
          startDate: start,
          endDate: end,
          isAllDay: task.time == null,
        );
        ok++;
      } catch (e) {
        firstError ??= e.toString();
      }
    }
    return (ok: ok, total: tasks.length, firstError: firstError);
  }

  Future<List<Event>> importFromSystemCalendar(DateTime start, DateTime end) async {
    if (!await requestPermissions()) throw Exception('Нет доступа к календарю');
    final calendars = await _plugin.listCalendars();
    if (calendars.isEmpty) return [];
    return _plugin.listEvents(start, end, calendarIds: calendars.map((c) => c.id).toList());
  }
}
