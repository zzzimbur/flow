// shift.dart
class Shift {
  final int id;
  final String title;
  final int hours;
  final int earnings;
  final String date;

  Shift({
    required this.id,
    required this.title,
    required this.hours,
    required this.earnings,
    required this.date,
  });

  Shift copyWith({
    int? id,
    String? title,
    int? hours,
    int? earnings,
    String? date,
  }) {
    return Shift(
      id: id ?? this.id,
      title: title ?? this.title,
      hours: hours ?? this.hours,
      earnings: earnings ?? this.earnings,
      date: date ?? this.date,
    );
  }
}