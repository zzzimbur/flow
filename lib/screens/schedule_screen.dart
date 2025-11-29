// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../screens/add_shift_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final shifts = appProvider.shifts;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('График', style: Theme.of(context).textTheme.headlineLarge),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ноябрь 2024', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Сегодня'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                      itemCount: 42,
                      itemBuilder: (context, index) {
                        final day = index - 7 + 1;
                        bool isCurrentMonth = day > 0 && day <= 30;
                        bool isToday = day == DateTime.now().day;
                        bool hasShift = [1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 29].contains(day);

                        if (index < 7) {
                          return Center(child: Text(['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][index], style: Theme.of(context).textTheme.bodySmall));
                        }

                        return Center(
                          child: isCurrentMonth
                              ? CircleAvatar(
                                  backgroundColor: isToday
                                      ? Theme.of(context).primaryColor
                                      : hasShift
                                          ? Colors.grey[300]
                                          : Colors.transparent,
                                  child: Text(
                                    day.toString(),
                                    style: TextStyle(color: isToday ? Colors.white : Colors.grey[800]),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Смены сегодня', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Column(
              children: shifts.map((shift) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    AddShiftScreen.show(context, shiftToEdit: shift);
                  },
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.work, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shift.title, style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500)),
                                  Text('${shift.hours}ч', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                          Text('₽${shift.earnings.toLocaleString()}', style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}