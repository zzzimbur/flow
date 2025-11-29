// transaction.dart
class TransactionModel {
  final int id;
  final String title;
  final int amount;
  final String type;
  final String category;
  final String date;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  TransactionModel copyWith({
    int? id,
    String? title,
    int? amount,
    String? type,
    String? category,
    String? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}