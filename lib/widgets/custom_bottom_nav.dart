import 'package:flutter/material.dart';
import 'glass_card.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;
  final VoidCallback onAddPressed;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Главная',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Финансы',
              index: 1,
            ),
            _buildAddButton(),
            _buildNavItem(
              icon: Icons.check_circle_rounded,
              label: 'Задачи',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.calendar_today_rounded,
              label: 'График',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => onTabChange(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFf1f5f9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFF1e293b)
                    : const Color(0xFF94a3b8),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF1e293b)
                      : const Color(0xFF94a3b8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1e293b).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onAddPressed,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}