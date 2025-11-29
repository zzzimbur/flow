// task.dart
class Task {
  final int id;
  final String title;
  final String time;
  final bool done;
  final String category;

  Task({
    required this.id,
    required this.title,
    required this.time,
    required this.done,
    required this.category,
  });

  Task copyWith({
    int? id,
    String? title,
    String? time,
    bool? done,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      done: done ?? this.done,
      category: category ?? this.category,
    );
  }
}