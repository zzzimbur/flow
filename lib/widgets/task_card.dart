import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
    this.onTap,
    this.onToggle,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
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
          color: isDark
              ? const Color(0xFF1e293b).withOpacity(0.5)
              : Colors.white.withOpacity(0.7),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isDone 
                        ? task.getPriorityColor()
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isDone
                          ? task.getPriorityColor()
                          : (isDark 
                              ? const Color(0xFF64748b)
                              : const Color(0xFF94a3b8)),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Содержимое задачи
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                        decoration: task.isDone 
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        // Время
                        if (task.time != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark 
                                ? const Color(0xFF64748b)
                                : const Color(0xFF94a3b8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.time!.hour.toString().padLeft(2, '0')}:${task.time!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF94a3b8)
                                  : const Color(0xFF64748b),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        // Подзадачи
                        if (task.hasSubtasks) ...[
                          Icon(
                            Icons.checklist,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF64748b)
                                : const Color(0xFF94a3b8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.completedSubtasks}/${task.totalSubtasks}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF94a3b8)
                                  : const Color(0xFF64748b),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        // Приоритет
                        if (task.priority != 'none') ...[
                          Icon(
                            task.getPriorityIcon(),
                            size: 14,
                            color: task.getPriorityColor(),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Категория
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: task.getPriorityColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: task.getPriorityColor(),
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
          'Удалить задачу?',
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