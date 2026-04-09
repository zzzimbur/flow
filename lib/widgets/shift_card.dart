import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../models/shift_model.dart';

class ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.isDark,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(shift.id),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF3b82f6),
        icon: Icons.edit,
        isDark: isDark,
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: const Color(0xFFef4444),
        icon: Icons.delete,
        isDark: isDark,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        } else {
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          color: shift.isFilled
              ? shift.color.withOpacity(isDark ? 0.3 : 0.15)
              : (isDark
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7)),
          border: shift.isFilled
              ? Border.all(color: shift.color.withOpacity(0.5), width: 1.5)
              : null,
          child: Row(
            children: [
              // Левая цветная полоска
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: shift.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // ИСПРАВЛЕНО: Иконка или эмодзи
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: shift.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: shift.emoji != null && shift.emoji!.isNotEmpty
                      ? Text(
                          shift.emoji!,
                          style: const TextStyle(fontSize: 24),
                        )
                      : Icon(
                          shift.icon,
                          color: shift.color,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Информация о смене
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ИСПРАВЛЕНО: Ограничение текста с overflow
                    Text(
                      shift.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        // Время
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF64748b)
                              : const Color(0xFF94a3b8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shift.timeRange,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF94a3b8)
                                : const Color(0xFF64748b),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Часы
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF64748b)
                              : const Color(0xFF94a3b8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shift.totalHours.toStringAsFixed(1)}ч',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF94a3b8)
                                : const Color(0xFF64748b),
                          ),
                        ),
                      ],
                    ),
                    
                    // Категория
                    if (shift.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: shift.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shift.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: shift.color,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Заработок
              if (shift.paymentType != 'unpaid')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₽${shift.totalEarnings.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: shift.color,
                      ),
                    ),
                    if (shift.paymentType == 'hourly')
                      Text(
                        '₽${shift.hourlyRate.toStringAsFixed(0)}/ч',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF64748b)
                              : const Color(0xFF94a3b8),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Без оплаты',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        title: Text(
          'Удалить смену?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: Text(
          'Это действие нельзя отменить',
          style: TextStyle(
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ?? false;
  }
}