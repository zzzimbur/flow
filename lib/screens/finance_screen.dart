import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

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
                  'Финансы',
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
                    onPressed: () {},
                    color: const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Баланс
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Баланс',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₽85,400',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFecfdf5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: const Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Доходы',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '+₽92,300',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF065f46),
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
                            color: const Color(0xFFfef2f2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_down,
                                    size: 16,
                                    color: const Color(0xFFdc2626),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Расходы',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFb91c1c),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '-₽6,900',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF991b1b),
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
            const Text(
              'По категориям',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b),
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
            ),
            const SizedBox(height: 12),
            
            _buildCategoryCard(
              'Продукты',
              -2300,
              false,
              [
                Transaction('Продукты', -2300, 'Вчера'),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildCategoryCard(
              'Развлечения',
              -850,
              false,
              [
                Transaction('Кафе', -850, '3 дня назад'),
              ],
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
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      tx.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94a3b8),
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