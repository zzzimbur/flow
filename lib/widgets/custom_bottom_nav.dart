import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
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
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        color: isDark 
            ? const Color(0xFF1e293b).withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Главная',
              index: 0,
              isDark: isDark,
            ),
            _buildNavItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Финансы',
              index: 1,
              isDark: isDark,
            ),
            _buildAddButton(isDark),
            _buildNavItem(
              icon: Icons.check_circle_rounded,
              label: 'Задачи',
              index: 2,
              isDark: isDark,
            ),
            _buildNavItem(
              icon: Icons.calendar_today_rounded,
              label: 'График',
              index: 3,
              isDark: isDark,
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
    required bool isDark,
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
                ? (isDark 
                    ? const Color(0xFF8b7ff5).withOpacity(0.2) 
                    : const Color(0xFFf1f5f9))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b))
                    : (isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8)),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? (isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b))
                      : (isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8)),
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

  Widget _buildAddButton(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6c5ce7), Color(0xFF8b7ff5), Color(0xFF4a3f8f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6c5ce7).withOpacity(0.5),
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