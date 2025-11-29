// settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          ListTile(title: const Text('Имя'), subtitle: const Text('Александр')),
          ListTile(title: const Text('Email'), subtitle: const Text('alex@example.com')),
          ListTile(title: const Text('Валюта'), subtitle: const Text('₽ Рубль')),
          ListTile(title: const Text('Тема'), subtitle: const Text('Светлая')),
        ],
      ),
    );
  }
}