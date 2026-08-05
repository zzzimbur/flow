import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/coinka.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;
  final bool showAccountantTab;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    this.showAccountantTab = false,
  });

  @override
  Widget build(BuildContext context) {
    // «+» вынесена в floating-кнопку над таб-баром (см. main_screen),
    // поэтому здесь только вкладки, ровно распределённые по ширине.
    final items = <_NavItemData>[
      const _NavItemData(emoji: '💰', label: 'Финансы', index: 0),
      const _NavItemData(emoji: '📅', label: 'Смены', index: 1),
      const _NavItemData(emoji: '✅', label: 'Задачи', index: 2),
      if (showAccountantTab)
        const _NavItemData(emoji: '📋', label: 'Табель', index: 4),
      const _NavItemData(emoji: '⚙️', label: 'Настройки', index: 3),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.ckS1,
        border: Border(top: BorderSide(color: context.ckBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items
                .map((e) => _NavItem(
                      data: e,
                      isActive: currentIndex == e.index,
                      onTap: onTabChange,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String emoji;
  final String label;
  final int index;
  const _NavItemData(
      {required this.emoji, required this.label, required this.index});
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final Function(int) onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(data.index);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isActive ? 1.0 : 0.45,
                  child: Text(data.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: isActive ? Coinka.accent : context.ckMuted,
                  ),
                ),
              ],
            ),
            // Полоска снизу под активной вкладкой
            if (isActive)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Coinka.accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

