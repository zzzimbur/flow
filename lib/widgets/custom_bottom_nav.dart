import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'dart:ui';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;
  final VoidCallback onAddPressed;
  final bool showAccountantTab;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    required this.onAddPressed,
    this.showAccountantTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.house_rounded,
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
                _buildAddButton(isDark), // теперь по центру!
                _buildNavItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Календарь',
                  index: 2,
                  isDark: isDark,
                ),
                if (showAccountantTab)
                  _buildNavItem(
                    icon: Icons.summarize,
                    label: 'Табель',
                    index: 4,
                    isDark: isDark,
                  )
                else
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Настройки',
                    index: 3,
                    isDark: isDark,
                  ),
                if (showAccountantTab)
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Настройки',
                    index: 3,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
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
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTabChange(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark 
                    ? Colors.white.withOpacity(0.15) 
                    : Colors.black.withOpacity(0.06))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? (isDark ? Colors.white : const Color(0xFF1e293b))
                    : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? Colors.white : const Color(0xFF1e293b))
                      : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
                  letterSpacing: -0.2,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onAddPressed();
      },
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8b7ff5).withOpacity(0.9),
              const Color(0xFF6c5ce7).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6c5ce7).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF6c5ce7).withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}