import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _getFormattedDate();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добро пожаловать',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    color: const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Статистика
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'За месяц',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '168ч',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Заработано',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '₽85,400',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: const Color(0xFFe2e8f0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Задач сегодня',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '3',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Смен в месяце',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '22',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Задачи на сегодня
            const Text(
              'Задачи на сегодня',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            _buildTaskItem('Встреча с клиентом', '14:00'),
            const SizedBox(height: 8),
            _buildTaskItem('Закончить отчёт', '16:30'),
            const SizedBox(height: 8),
            _buildTaskItem('Тренировка', '19:00'),
            const SizedBox(height: 24),
            
            // Прогресс цели
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Цель на месяц: ₽150,000',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const Text(
                        '57%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.57,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFe2e8f0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1e293b),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Осталось: ₽64,600',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Отступ для нижней навигации
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String title, String time) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF94a3b8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}