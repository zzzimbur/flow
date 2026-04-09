import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as app_date_utils;

class CalendarDateCell extends StatelessWidget {
  final DateTime? date;
  final bool isSelected;
  final bool isToday;
  final bool hasShift;
  final bool hasTask;
  final bool hasTransaction;
  final VoidCallback? onTap;
  final bool isDark;

  const CalendarDateCell({
    super.key,
    this.date,
    this.isSelected = false,
    this.isToday = false,
    this.hasShift = false,
    this.hasTask = false,
    this.hasTransaction = false,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox();
    }

    final isWeekend = app_date_utils.DateUtils.isWeekend(date!);
    final isCurrentMonth = true; // Можно добавить проверку месяца

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(
                  color: isDark 
                      ? const Color(0xFF8b7ff5).withOpacity(0.5)
                      : const Color(0xFF8b7ff5).withOpacity(0.3),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date!.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                color: _getTextColor(isWeekend, isCurrentMonth),
              ),
            ),
            const SizedBox(height: 4),
            // Индикаторы событий
            if (hasShift || hasTask || hasTransaction)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasShift) _buildIndicator(const Color(0xFF8b7ff5)),
                  if (hasTask) _buildIndicator(const Color(0xFF3b82f6)),
                  if (hasTransaction) _buildIndicator(const Color(0xFF10b981)),
                ],
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) {
      return const Color(0xFF8b7ff5);
    }
    if (isToday) {
      return isDark 
          ? const Color(0xFF334155)
          : const Color(0xFFf1f5f9);
    }
    return Colors.transparent;
  }

  Color _getTextColor(bool isWeekend, bool isCurrentMonth) {
    if (isSelected) {
      return Colors.white;
    }
    
    if (!isCurrentMonth) {
      return isDark 
          ? const Color(0xFF475569)
          : const Color(0xFFcbd5e1);
    }
    
    if (isWeekend) {
      return isDark 
          ? const Color(0xFF8b7ff5)
          : const Color(0xFF6c5ce7);
    }
    
    return isDark ? Colors.white : const Color(0xFF1e293b);
  }

  Widget _buildIndicator(Color color) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.8) : color,
        shape: BoxShape.circle,
      ),
    );
  }
}