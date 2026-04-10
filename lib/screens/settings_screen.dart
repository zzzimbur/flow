import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_glass_card.dart' hide AnimatedBackground;
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart' as auth;
import 'analytics_screen.dart';
import 'auth_screen.dart';
import 'templates_screen.dart';
import '../providers/subscription_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../widgets/ad_banner.dart';
import '../screens/payment_screen.dart';
import '../services/calendar_service.dart';
import '../services/firestore_service.dart';
import '../models/shift_model.dart';
import '../models/task_model.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accentColor = settings.accentColor;
    
final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    return Scaffold(
      body: AnimatedBackground(
        isDark: isDark,
        child: Column(
          children: [
            if (!subscriptionProvider.isActive) const AdBanner(),
            Expanded(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Заголовок
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Настройки',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Профиль пользователя - используем StreamBuilder для реального времени
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final displayName = user?.displayName ?? settings.userName;
                        final email = user?.email ?? settings.userEmail;
                        
                        // Обновляем settings если данные отличаются
                        if (displayName != settings.userName && displayName.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            settings.setUserName(displayName);
                          });
                        }
                        if (email != settings.userEmail && email.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            settings.setUserEmail(email);
                          });
                        }
                        
                        return EnhancedGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accentColor, accentColor.withOpacity(0.6)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    displayName.isNotEmpty 
                                        ? displayName[0].toUpperCase() 
                                        : 'П',
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
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Секция "Аккаунт"
                    SectionHeader(
                      title: 'Аккаунт',
                      icon: Icons.person,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSettingItem(
                      context,
                      'Имя',
                      settings.userName,
                      Icons.person_outline,
                      isDark,
                      accentColor,
                      () => _showEditDialog(
                        context,
                        'Изменить имя',
                        settings.userName,
                        (value) => settings.setUserName(value),
                        isDark,
                        accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildSettingItem(
                      context,
                      'Email',
                      settings.userEmail,
                      Icons.email_outlined,
                      isDark,
                      accentColor,
                      () => _showEditDialog(
                        context,
                        'Изменить email',
                        settings.userEmail,
                        (value) => settings.setUserEmail(value),
                        isDark,
                        accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildSettingItem(
                      context,
                      'Пароль',
                      '••••••••',
                      Icons.lock_outline,
                      isDark,
                      accentColor,
                      () => _showPasswordDialog(context, settings, isDark, accentColor),
                    ),
                    const SizedBox(height: 24),
                    
                    // Секция "Подписка"
                    SectionHeader(
                      title: 'Подписка',
                      icon: Icons.workspace_premium,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSubscriptionCard(context, isDark, accentColor),
                    const SizedBox(height: 24),
                    
                    // Секция "Оформление"
                    SectionHeader(
                      title: 'Оформление',
                      icon: Icons.palette,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildThemeToggle(context, settings, isDark, accentColor),
                    const SizedBox(height: 8),
                    
                    _buildColorThemeSelector(context, settings, isDark),
                    const SizedBox(height: 24),
                    
                    // Секция "Настройки"
                    SectionHeader(
                      title: 'Настройки',
                      icon: Icons.settings,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSettingItem(
                      context,
                      'Валюта',
                      settings.currency,
                      Icons.currency_ruble,
                      isDark,
                      accentColor,
                      () => _showCurrencyDialog(context, settings, isDark, accentColor),
                    ),
                    const SizedBox(height: 24),
                    
                    // Секция "Аналитика"
                    SectionHeader(
                      title: 'Аналитика',
                      icon: Icons.bar_chart,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionItem(
                      context,
                      'Статистика',
                      'Просмотр аналитики',
                      Icons.insights,
                      isDark,
                      accentColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height:12),

                    _buildActionItem(
                      context,
                      'Шаблоны',
                      'Управление шаблонами',
                      Icons.bookmark_outline,
                      isDark,
                      accentColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TemplatesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Секция "Экспорт"
                    SectionHeader(
                      title: 'Экспорт данных',
                      icon: Icons.ios_share,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _buildActionItem(
                      context,
                      'Экспорт смен в календарь',
                      'Добавить все смены в системный календарь',
                      Icons.event_repeat,
                      isDark,
                      accentColor,
                      () => _exportShiftsToCalendar(context, isDark, accentColor),
                    ),
                    const SizedBox(height: 8),

                    _buildActionItem(
                      context,
                      'Экспорт задач в календарь',
                      'Добавить все задачи в системный календарь',
                      Icons.task_alt,
                      isDark,
                      accentColor,
                      () => _exportTasksToCalendar(context, isDark, accentColor),
                    ),
                    const SizedBox(height: 24),

                    // Секция "О приложении"
                    SectionHeader(
                      title: 'О приложении',
                      icon: Icons.info,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildSettingItem(
                      context,
                      'Версия',
                      '1.0.1',
                      Icons.info_outline,
                      isDark,
                      accentColor,
                      null,
                    ),
                    const SizedBox(height: 8),
                    
                    _buildActionItem(
                      context,
                      'Обратная связь',
                      'Отправить отзыв',
                      Icons.feedback_outlined,
                      isDark,
                      accentColor,
                      () => _showFeedbackDialog(context, isDark),
                    ),
                    const SizedBox(height: 8),

                    _buildActionItem(
                      context,
                      'Поддержать проект',
                      'Поддержать разработку проекта',
                      Icons.favorite,
                      isDark,
                      accentColor,
                      () => _showSupportDialog(context, isDark),
                    ),
                    const SizedBox(height: 8),

                    // Политика конфиденциальности
                    _buildActionItem(
                      context,
                      'Политика конфиденциальности',
                      'Как мы используем ваши данные',
                      Icons.shield_outlined,
                      isDark,
                      accentColor,
                      () => _openLegalDocument(context, 'privacy'),
                    ),
                    const SizedBox(height: 8),

                    // Пользовательское соглашение
                    _buildActionItem(
                      context,
                      'Пользовательское соглашение',
                      'Условия использования приложения',
                      Icons.description_outlined,
                      isDark,
                      accentColor,
                      () => _openLegalDocument(context, 'terms'),
                    ),
                    const SizedBox(height: 8),

                    // Согласие на обработку данных
                    _buildActionItem(
                      context,
                      'Согласие на обработку данных',
                      'В соответствии с 152-ФЗ РФ',
                      Icons.verified_user_outlined,
                      isDark,
                      accentColor,
                      () => _openLegalDocument(context, 'consent'),
                    ),

                    const SizedBox(height: 24),
                    // Выход
                    GlassButton(
                      text: 'Выйти из аккаунта',
                      onPressed: () => _handleLogout(context, isDark),
                      color: const Color(0xFFef4444),
                      icon: Icons.logout,
                    ),
                    const SizedBox(height: 12),

                    // Кнопка удаления аккаунта
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withOpacity(0.1),
                            Colors.red.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white.withOpacity(0.02),
                                ],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _deleteAccount(context),
                                borderRadius: BorderRadius.circular(20),
                                splashColor: Colors.red.withOpacity(0.2),
                                highlightColor: Colors.red.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.red.withOpacity(0.2),
                                              Colors.red.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_forever_rounded,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Удалить аккаунт',
                                              style: TextStyle(
                                                color: Colors.red.shade300,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Безвозвратно удалить все данные',
                                              style: TextStyle(
                                                color: isDark 
                                                    ? Colors.white.withOpacity(0.4)
                                                    : Colors.black.withOpacity(0.4),
                                                fontSize: 12,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.red.withOpacity(0.4),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    Color accentColor,
    VoidCallback? onTap,
  ) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      enableHover: onTap != null,
      child: Row(
        children: [
          Icon(
            icon,
            color: accentColor,
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
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: accentColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    Color accentColor,
  ) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
      enableHover: false,
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: accentColor,
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
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark ? 'Тёмная' : 'Светлая',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (value) => settings.toggleTheme(value),
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildColorThemeSelector(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
      enableHover: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.color_lens,
                color: settings.accentColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'Акцентный цвет',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: settings.availableThemes.map((theme) {
              final isSelected = theme.id == settings.selectedThemeId;
              final color = isDark ? theme.darkAccent : theme.lightAccent;
              
              return GestureDetector(
                onTap: () => settings.setAccentTheme(theme.id),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 28,
                        )
                      : null,
                ),
              );
            }).toList(),
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
    bool isDark,
    Color accentColor,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark 
                ? const Color(0xFF0f172a) 
                : const Color(0xFFf1f5f9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    Color accentColor,
  ) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Изменить пароль',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Старый пароль',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                filled: true,
                fillColor: isDark 
                    ? const Color(0xFF0f172a) 
                    : const Color(0xFFf1f5f9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                filled: true,
                fillColor: isDark 
                    ? const Color(0xFF0f172a) 
                    : const Color(0xFFf1f5f9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
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
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setUserPassword(newPasswordController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    Color accentColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Выбрать валюту',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: accentColor)
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

  Future<void> _showSupportDialog(BuildContext context, bool isDark) async {
    const String donateUrl = 'https://pay.cloudtips.ru/p/10515bdb';
        try {
      final Uri donateUri = Uri.parse(donateUrl);
      
      // Убираем проверку canLaunchUrl - просто пытаемся открыть
      await launchUrl(
        donateUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Ошибка открытия ссылки: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Не удалось открыть ссылку поддержки проекта'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Скопировать ссылку',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: donateUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ссылка скопирована в буфер обмена'),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showFeedbackDialog(BuildContext context, bool isDark) async {
    const String googleFormUrl = 'https://forms.gle/hp9QBGaS7qAS1iKL9';
        try {
      final Uri formUri = Uri.parse(googleFormUrl);
      
      // Убираем проверку canLaunchUrl - просто пытаемся открыть
      await launchUrl(
        formUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Ошибка открытия формы: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Не удалось открыть форму обратной связи'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Скопировать ссылку',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: googleFormUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ссылка скопирована в буфер обмена'),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _handleLogout(BuildContext context, bool isDark) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final accentColor = settings.accentColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Выйти из аккаунта?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Вы действительно хотите выйти?',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: EnhancedGlassCard(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                ),
              );
              
              try {
                final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
                await authProvider.signOut();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка выхода: $e'),
                      backgroundColor: const Color(0xFFef4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Выйти',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSubscriptionCard(BuildContext context, bool isDark, Color accentColor) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    if (subscriptionProvider.isPremium) {
      // Показываем статус активной подписки
      final expiresAt = subscriptionProvider.expiresAt;
      final daysLeft = expiresAt != null 
          ? expiresAt.difference(DateTime.now()).inDays 
          : 0;
      
      return EnhancedGlassCard(
        padding: const EdgeInsets.all(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8b7ff5).withOpacity(0.2),
            const Color(0xFF6c5ce7).withOpacity(0.1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8b7ff5), Color(0xFF6c5ce7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium активна',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expiresAt != null
                            ? 'Истекает через $daysLeft ${_getDaysWord(daysLeft)}'
                            : 'Бессрочная',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Дата окончания: ${expiresAt.day}.${expiresAt.month}.${expiresAt.year}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка продления подписки
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Продлить подписку'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8b7ff5),
                    side: const BorderSide(
                      color: Color(0xFF8b7ff5),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      // Показываем предложение купить подписку
      return EnhancedGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flow Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '299 ₽ / месяц',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFeatureRow('📅', 'Недельный вид календаря', isDark),
            _buildFeatureRow('💰', 'Управление финансами', isDark),
            _buildFeatureRow('🎯', 'Неограниченные цели', isDark),
            _buildFeatureRow('📋', 'Шаблоны событий', isDark),
            _buildFeatureRow('🚫', 'Без рекламы', isDark),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Переход на экран оплаты через ЮКассу
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Получить Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildFeatureRow(String emoji, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            size: 18,
            color: const Color(0xFF10b981),
          ),
        ],
      ),
    );
  }
  
  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) return 'дня';
    return 'дней';
  }

  // ─── Экспорт смен в системный календарь ──────────────────────────────────
  Future<void> _exportShiftsToCalendar(
    BuildContext context,
    bool isDark,
    Color accentColor,
  ) async {
    final authProv = Provider.of<auth.AuthProvider>(context, listen: false);
    final userId = authProv.userId;
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestoreService = FirestoreService();
      final calendarService = CalendarService();
      final now = DateTime.now();
      final shiftsRaw = await firestoreService.getShifts(
        userId,
        DateTime(now.year, now.month - 3),
        DateTime(now.year, now.month + 1, 28),
      );
      final shifts = shiftsRaw
          .map((data) => ShiftModel.fromMap(data['id'] ?? '', data))
          .toList();

      if (context.mounted) Navigator.pop(context);

      if (shifts.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Нет смен для экспорта'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
        return;
      }

      await calendarService.exportAllShifts(shifts);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Экспортировано смен: ${shifts.length}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ─── Экспорт задач в системный календарь ─────────────────────────────────
  Future<void> _exportTasksToCalendar(
    BuildContext context,
    bool isDark,
    Color accentColor,
  ) async {
    final authProv = Provider.of<auth.AuthProvider>(context, listen: false);
    final userId = authProv.userId;
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestoreService = FirestoreService();
      final calendarService = CalendarService();
      final now = DateTime.now();
      final tasksRaw = await firestoreService.getTasks(
        userId,
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month + 2, 28),
      );
      final tasks = tasksRaw
          .map((data) => TaskModel.fromMap(data['id'] ?? '', data))
          .toList();

      if (context.mounted) Navigator.pop(context);

      if (tasks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Нет задач для экспорта'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
        return;
      }

      await calendarService.exportAllTasks(tasks);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Экспортировано задач: ${tasks.length}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }
}

void _openLegalDocument(BuildContext context, String type) async {
  final urls = {
    'privacy': 'https://zzzimbur.github.io/flow-legal/privacy-policy.html',
    'terms': 'https://zzzimbur.github.io/flow-legal/terms-of-service.html',
    'consent': 'https://zzzimbur.github.io/flow-legal/consent.html',
  };
  
  final url = urls[type];
  if (url == null) return;
  
  try {
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    
    if (canLaunch) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Не удалось открыть документ'),
              ],
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  } catch (e) {
    print('Ошибка открытия документа: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Ошибка: ${e.toString()}')),
            ],
          ),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

Future<void> _deleteAccount(BuildContext context) async {
  // Единственное подтверждение с вводом текста
  final textConfirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: const Text(
          'Удалить аккаунт навсегда?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Это действие необратимо. Все ваши данные будут удалены навсегда.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Введите "УДАЛИТЬ" для подтверждения',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'УДАЛИТЬ',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim() == 'УДАЛИТЬ') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Введите "УДАЛИТЬ" для подтверждения'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Удалить аккаунт',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );

  if (textConfirmed != true) return;

  try {
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final batch = FirebaseFirestore.instance.batch();
    
    // Удаляем задачи из подколлекции
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Удаляем смены из подколлекции
    final shiftsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('shifts')
        .get();
    for (var doc in shiftsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Удаляем транзакции из подколлекции
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .get();
    for (var doc in transactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Удаляем цели из подколлекции
    final goalsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goals')
        .get();
    for (var doc in goalsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Удаляем настройки из подколлекции
    final settingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .get();
    for (var doc in settingsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Удаляем категории из подколлекции
    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .get();
    for (var doc in categoriesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Удаляем документ пользователя
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    batch.delete(userDoc);

    // Применяем все удаления
    await batch.commit();

    // Удаляем аккаунт Firebase Auth
    await user.delete();

    // Закрываем диалог загрузки
    if (context.mounted) Navigator.pop(context);

    // Показываем сообщение и переходим на экран авторизации
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Аккаунт успешно удален'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    // Закрываем диалог загрузки
    if (context.mounted) Navigator.pop(context);

    // Если требуется повторная аутентификация - просто показываем ошибку
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'requires-recent-login'
                ? 'Сессия устарела. Пожалуйста, выйдите и войдите снова, затем повторите удаление.'
                : 'Ошибка удаления аккаунта: ${e.message}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    // Закрываем диалог загрузки
    if (context.mounted) Navigator.pop(context);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
