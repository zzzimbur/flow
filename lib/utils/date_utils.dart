import 'package:cloud_firestore/cloud_firestore.dart';

class DateUtils {
  // Получить первый день месяца
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Получить последний день месяца
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Получить количество дней в месяце
  static int getDaysInMonth(DateTime date) {
    return getLastDayOfMonth(date).day;
  }

  // Проверка, является ли день сегодняшним
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  // Проверка, являются ли два дня одинаковыми
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Проверка, является ли день выходным
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Получить название месяца
  static String getMonthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }

  // Получить короткое название месяца
  static String getShortMonthName(int month) {
    const months = [
      'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
      'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
    ];
    return months[month - 1];
  }

  // Получить название дня недели
  static String getWeekdayName(int weekday) {
    const weekdays = [
      'Понедельник', 'Вторник', 'Среда', 'Четверг', 
      'Пятница', 'Суббота', 'Воскресенье'
    ];
    return weekdays[weekday - 1];
  }

  // Получить короткое название дня недели
  static String getShortWeekdayName(int weekday) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[weekday - 1];
  }

  // Форматировать дату в строку
  static String formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    switch (format) {
      case 'dd.MM.yyyy':
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      case 'dd MMMM yyyy':
        return '${date.day} ${getMonthName(date.month)} ${date.year}';
      case 'dd MMM':
        return '${date.day} ${getShortMonthName(date.month)}';
      case 'EEEE, dd MMMM':
        return '${getWeekdayName(date.weekday)}, ${date.day} ${getMonthName(date.month).toLowerCase()}';
      default:
        return '${date.day}.${date.month}.${date.year}';
    }
  }

  // Форматировать время
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Получить начало дня
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Получить конец дня
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Получить начало недели (понедельник)
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: diff)));
  }

  // Получить конец недели (воскресенье)
  static DateTime endOfWeek(DateTime date) {
    final diff = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: diff)));
  }

  // Получить начало месяца
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Получить конец месяца
  static DateTime endOfMonth(DateTime date) {
    return endOfDay(getLastDayOfMonth(date));
  }

  // Получить список дней для календарной сетки (42 дня)
  static List<DateTime?> getCalendarDays(DateTime month) {
    List<DateTime?> days = [];
    
    final firstDay = getFirstDayOfMonth(month);
    final lastDay = getLastDayOfMonth(month);
    final firstWeekday = firstDay.weekday;
    
    // Добавляем пустые дни в начале
    for (int i = 1; i < firstWeekday; i++) {
      days.add(null);
    }
    
    // Добавляем дни месяца
    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }
    
    // Добавляем пустые дни в конце до 42
    while (days.length < 42) {
      days.add(null);
    }
    
    return days;
  }

  // Получить список недель для месяца
  static List<List<DateTime?>> getWeeksInMonth(DateTime month) {
    final days = getCalendarDays(month);
    List<List<DateTime?>> weeks = [];
    
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }
    
    return weeks;
  }

  // Конвертация Timestamp в DateTime
  static DateTime fromTimestamp(Timestamp timestamp) {
    return timestamp.toDate();
  }

  // Конвертация DateTime в Timestamp
  static Timestamp toTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  // Получить относительное время ("Сегодня", "Вчера", "2 дня назад")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = startOfDay(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = startOfDay(date);
    
    if (isSameDay(dateDay, today)) {
      return 'Сегодня';
    } else if (isSameDay(dateDay, yesterday)) {
      return 'Вчера';
    } else {
      final diff = today.difference(dateDay).inDays;
      if (diff < 7) {
        return '$diff ${_getDaysWord(diff)} назад';
      } else {
        return formatDate(date, format: 'dd MMM');
      }
    }
  }

  // Склонение слова "день"
  static String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }

  // Вычислить разницу в часах между двумя временами
  static double calculateHoursDifference(DateTime start, DateTime end) {
    final difference = end.difference(start);
    return difference.inMinutes / 60.0;
  }

  // Проверка, находится ли дата в диапазоне
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) && 
           date.isBefore(end.add(const Duration(days: 1)));
  }

  // Получить количество недель между датами
  static int getWeeksBetween(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    return (days / 7).ceil();
  }

  // Добавить месяцы к дате
  static DateTime addMonths(DateTime date, int months) {
    int newMonth = date.month + months;
    int newYear = date.year;
    
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }
    
    final lastDayOfNewMonth = getLastDayOfMonth(DateTime(newYear, newMonth));
    final day = date.day > lastDayOfNewMonth.day ? lastDayOfNewMonth.day : date.day;
    
    return DateTime(newYear, newMonth, day, date.hour, date.minute, date.second);
  }
}