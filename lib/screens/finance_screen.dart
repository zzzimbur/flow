import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

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
                  'Финансы',
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
            
            // Баланс
            GlassCard(
              padding: const EdgeInsets.all(24),
              color: isDark 
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Баланс',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₽85,400',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFecfdf5).withOpacity(isDark ? 0.2 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                  'Доходы',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF10b981) : const Color(0xFF047857), // Ярче для темной темы
                                  ),
                                ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                              '+₽92,300',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF34d399) : const Color(0xFF065f46), // Ярче для темной темы
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfef2f2).withOpacity(isDark ? 0.2 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_down,
                                    size: 16,
                                    color: Color(0xFFdc2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Расходы',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFFf87171) : const Color(0xFFb91c1c),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '-₽6,900',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFfca5a5) : const Color(0xFF991b1b),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // По категориям
            Text(
              'По категориям',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildCategoryCard(
              'Работа',
              60000,
              true,
              [
                Transaction('Зарплата', 45000, 'Сегодня'),
                Transaction('Фриланс', 15000, '2 дня назад'),
              ],
              isDark,
            ),
            const SizedBox(height: 12),
            
            _buildCategoryCard(
              'Продукты',
              -2300,
              false,
              [
                Transaction('Продукты', -2300, 'Вчера'),
              ],
              isDark,
            ),
            const SizedBox(height: 12),
            
            _buildCategoryCard(
              'Развлечения',
              -850,
              false,
              [
                Transaction('Кафе', -850, '3 дня назад'),
              ],
              isDark,
            ),
            
            const SizedBox(height: 100), // Отступ для навигации
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String category,
    int total,
    bool isIncome,
    List<Transaction> transactions,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                ),
              ),
              Text(
                '${total > 0 ? '+' : ''}₽${total.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? const Color(0xFF059669) : const Color(0xFFdc2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...transactions.map((tx) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFFe2e8f0) : const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      tx.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${tx.amount > 0 ? '+' : ''}₽${tx.amount.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tx.amount > 0 ? const Color(0xFF059669) : const Color(0xFFdc2626),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class Transaction {
  final String title;
  final int amount;
  final String date;

  Transaction(this.title, this.amount, this.date);
}