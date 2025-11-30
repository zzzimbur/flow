import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'График',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
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
            
            // Календарь
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ноябрь 2024',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Сегодня',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748b),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendar(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Смены сегодня
            const Text(
              'Смены сегодня',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildShiftCard('Работа в офисе', 8, 3200),
            const SizedBox(height: 8),
            _buildShiftCard('Фриланс проект', 4, 2500),
            
            const SizedBox(height: 100), // Отступ для навигации
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final workDays = [1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 29];
    final today = 29;
    
    return Column(
      children: [
        // Дни недели
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) => SizedBox(
            width: 40,
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748b),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        
        // Дни месяца
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: 35,
          itemBuilder: (context, index) {
            final day = index - 2;
            final isValid = day > 0 && day <= 30;
            final isToday = day == today;
            final hasShift = workDays.contains(day);
            
            return Container(
              decoration: BoxDecoration(
                color: !isValid
                    ? Colors.transparent
                    : isToday
                    ? const Color(0xFF1e293b)
                    : hasShift
                    ? const Color(0xFFf1f5f9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isValid ? day.toString() : '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: !isValid
                        ? Colors.transparent
                        : isToday
                        ? Colors.white
                        : const Color(0xFF1e293b),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard(String title, int hours, int earnings) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_outline,
              color: Color(0xFF64748b),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${hours}ч',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₽${earnings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }
}