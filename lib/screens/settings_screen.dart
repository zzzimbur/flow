import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Настройки',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0f172a), const Color(0xFF1e293b)]
                : [const Color(0xFFf8fafc), const Color(0xFFe2e8f0)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Профиль пользователя
              GlassCard(
                padding: const EdgeInsets.all(20),
                color: isDark
                    ? const Color(0xFF1e293b).withOpacity(0.6)
                    : Colors.white.withOpacity(0.6),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8b7ff5), Color(0xFFf4e4a7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          settings.userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF94a3b8)
                                  : const Color(0xFF64748b),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Секция "Аккаунт"
              _buildSectionTitle('АККАУНТ', isDark),
              const SizedBox(height: 8),
              
              _buildSettingItem(
                context,
                'Имя',
                settings.userName,
                Icons.person_outline,
                isDark,
                () => _showEditDialog(
                  context,
                  'Изменить имя',
                  settings.userName,
                  (value) => settings.setUserName(value),
                ),
              ),
              const SizedBox(height: 8),
              
              _buildSettingItem(
                context,
                'Email',
                settings.userEmail,
                Icons.email_outlined,
                isDark,
                () => _showEditDialog(
                  context,
                  'Изменить email',
                  settings.userEmail,
                  (value) => settings.setUserEmail(value),
                ),
              ),
              const SizedBox(height: 8),
              
              _buildSettingItem(
                context,
                'Пароль',
                '••••••••',
                Icons.lock_outline,
                isDark,
                () => _showPasswordDialog(context, settings),
              ),
              const SizedBox(height: 24),
              
              // Секция "Настройки"
              _buildSectionTitle('НАСТРОЙКИ', isDark),
              const SizedBox(height: 8),
              
              _buildSettingItem(
                context,
                'Валюта',
                settings.currency,
                Icons.currency_ruble,
                isDark,
                () => _showCurrencyDialog(context, settings),
              ),
              const SizedBox(height: 8),
              
              _buildThemeToggle(context, settings, isDark),
              const SizedBox(height: 24),
              
              // Секция "О приложении"
              _buildSectionTitle('О ПРИЛОЖЕНИИ', isDark),
              const SizedBox(height: 8),
              
              _buildSettingItem(
                context,
                'Версия',
                '1.0.0',
                Icons.info_outline,
                isDark,
                null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark,
    VoidCallback? onTap,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark
          ? const Color(0xFF1e293b).withOpacity(0.6)
          : Colors.white.withOpacity(0.6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFF94a3b8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark
          ? const Color(0xFF1e293b).withOpacity(0.6)
          : Colors.white.withOpacity(0.6),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF1e293b),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тема',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark ? 'Темная' : 'Светлая',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (value) => settings.toggleTheme(),
            activeColor: const Color(0xFF8b7ff5),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    final isDark = Provider.of<SettingsProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8b7ff5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, SettingsProvider settings) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final isDark = settings.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        title: Text(
          'Изменить пароль',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
              decoration: InputDecoration(
                labelText: 'Старый пароль',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setUserPassword(newPasswordController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8b7ff5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    final isDark = settings.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        title: Text(
          'Выбрать валюту',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: settings.availableCurrencies.map((currency) {
            final isSelected = currency == settings.currency;
            return ListTile(
              title: Text(
                currency,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF8b7ff5))
                  : null,
              onTap: () {
                settings.setCurrency(currency);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}