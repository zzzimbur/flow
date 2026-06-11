import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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
    final accent = settings.accentColor;

    // Build the list of nav items (excluding center + button)
    final leftItems = <_NavItemData>[
      _NavItemData(icon: Icons.house_rounded, label: 'Главная', index: 0),
      _NavItemData(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Финансы',
          index: 1),
    ];

    final rightItems = <_NavItemData>[
      _NavItemData(
          icon: Icons.calendar_today_rounded, label: 'Календарь', index: 2),
      if (showAccountantTab)
        _NavItemData(
            icon: Icons.summarize_rounded, label: 'Табель', index: 4),
      _NavItemData(
          icon: Icons.settings_rounded, label: 'Настройки', index: 3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.18)
                    : Colors.white.withOpacity(0.9),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Left items
                ...leftItems.map(
                  (item) => _NavItem(
                    icon: item.icon,
                    label: item.label,
                    index: item.index,
                    currentIndex: currentIndex,
                    isDark: isDark,
                    accent: accent,
                    onTap: onTabChange,
                  ),
                ),
                // Center "+" button
                _AddButton(accent: accent, onPressed: onAddPressed),
                // Right items
                ...rightItems.map(
                  (item) => _NavItem(
                    icon: item.icon,
                    label: item.label,
                    index: item.index,
                    currentIndex: currentIndex,
                    isDark: isDark,
                    accent: accent,
                    onTap: onTabChange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int index;
  const _NavItemData(
      {required this.icon, required this.label, required this.index});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isDark;
  final Color accent;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.35)
        : Colors.black.withOpacity(0.35);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 14 : 0,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isActive ? accent.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? accent : inactiveColor,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;

  const _AddButton({
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, accent.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
