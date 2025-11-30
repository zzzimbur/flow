import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

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
                    Text(
                      'Добро пожаловать',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9),
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
                    color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Статистика
            GlassCard(
              padding: const EdgeInsets.all(24),
              color: isDark 
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'За месяц',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '168ч',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Заработано',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₽85,400',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
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
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Задач сегодня',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Смен в месяце',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '22',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
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
            Text(
              'Задачи на сегодня',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            _buildTaskItem('Встреча с клиентом', '14:00', isDark),
            const SizedBox(height: 8),
            _buildTaskItem('Закончить отчёт', '16:30', isDark),
            const SizedBox(height: 8),
            _buildTaskItem('Тренировка', '19:00', isDark),
            const SizedBox(height: 24),
            
            // Прогресс цели
            GlassCard(
              padding: const EdgeInsets.all(20),
              color: isDark 
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Цель на месяц: ₽150,000',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFe2e8f0) : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '57%',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
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
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Осталось: ₽64,600',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
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

  Widget _buildTaskItem(String title, String time, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF94a3b8),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
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