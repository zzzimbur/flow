import 'package:flutter/material.dart';

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;
  
  TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });
  
  static List getExpenseCategories() {
    return [
      TransactionCategory(
        id: 'food',
        name: 'Продукты',
        icon: Icons.shopping_cart,
        color: Color(0xFF10b981),
        isExpense: true,
      ),
      TransactionCategory(
        id: 'transport',
        name: 'Транспорт',
        icon: Icons.directions_car,
        color: Color(0xFF3b82f6),
        isExpense: true,
      ),
    ];
  }
  
  static List getIncomeCategories() {
    return [
      TransactionCategory(
        id: 'salary',
        name: 'Зарплата',
        icon: Icons.account_balance_wallet,
        color: Color(0xFF10b981),
        isExpense: false,
      ),
    ];
  }
}