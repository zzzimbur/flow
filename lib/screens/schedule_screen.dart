import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'График',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
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
            
            // Календарь
            GlassCard(
              padding: const EdgeInsets.all(20),
              color: isDark 
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ноябрь 2024',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Сегодня',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendar(isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Смены сегодня
            Text(
              'Смены сегодня',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildShiftCard('Работа в офисе', 8, 3200, isDark),
            const SizedBox(height: 8),
            _buildShiftCard('Фриланс проект', 4, 2500, isDark),
            
            const SizedBox(height: 100), // Отступ для навигации
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
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
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
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
                    ? (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b))
                    : hasShift
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFf1f5f9))
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
                        : (isDark ? const Color(0xFFe2e8f0) : const Color(0xFF1e293b)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShiftCard(String title, int hours, int earnings, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.work_outline,
              color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
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
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${hours}ч',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₽${earnings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }
}