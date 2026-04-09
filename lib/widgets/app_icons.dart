import 'package:flutter/material.dart';

class AppIcons {
  static const Map<String, IconData> map = {
    'work': Icons.work,
    'money': Icons.attach_money,
    'shift': Icons.schedule,
    'goal': Icons.flag,
    'task': Icons.check_circle,
    'home': Icons.home,
    'default': Icons.help_outline,
  };

  static IconData fromKey(String? key) {
    return map[key] ?? map['default']!;
  }
}
