// lib/screens/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../screens/add_transaction_screen.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  Map<String, dynamic> _groupTransactions(List<TransactionModel> transactions) {
    final Map<String, dynamic> grouped = {};
    for (var tx in transactions) {
      if (!grouped.containsKey(tx.category)) {
        grouped[tx.category] = {'items': <TransactionModel>[], 'total': 0};
      }
      grouped[tx.category]['items'].add(tx);
      grouped[tx.category]['total'] += tx.amount;
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final stats = appProvider.stats;
    final transactions = appProvider.transactions;
    final grouped = _groupTransactions(transactions);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Финансы', style: Theme.of(context).textTheme.headlineLarge),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Show settings
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Баланс', style: Theme.of(context).textTheme.bodySmall),
                    Text('₽${NumberFormat('#,###', 'ru_RU').format(stats['monthEarnings'])}', style: Theme.of(context).textTheme.headlineMedium), 
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text('Доходы', style: TextStyle(color: Colors.green[700])),
                                  ],
                                ),
                                Text('+₽92,300', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Transform.rotate(angle: 3.14, child: const Icon(Icons.trending_up, color: Colors.red)),
                                    const SizedBox(width: 4),
                                    Text('Расходы', style: TextStyle(color: Colors.red[700])),
                                  ],
                                ),
                                Text('-₽6,900', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('По категориям', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Column(
              children: grouped.entries.map((entry) {
                final category = entry.key;
                final data = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(category, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                '${data['total'] > 0 ? '+' : ''}₽${data['total'].abs().toLocaleString()}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: data['total'] > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...data['items'].map((tx) => GestureDetector(
                                onTap: () {
                                  AddTransactionScreen.show(context, txToEdit: tx);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tx.title, style: Theme.of(context).textTheme.bodyMedium),
                                          Text(tx.date, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 12)),
                                        ],
                                      ),
                                      Text(
                                        '${tx.amount > 0 ? '+' : ''}₽${tx.amount.abs().toLocaleString()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: tx.type == 'income' ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}