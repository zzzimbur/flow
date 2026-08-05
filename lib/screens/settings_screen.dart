import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'dart:math';
import 'dart:ui';
import '../widgets/ad_banner.dart';
import '../screens/payment_screen.dart';
import '../services/calendar_service.dart';
import '../services/firestore_service.dart';
import '../models/shift_model.dart';
import '../models/task_model.dart';
import '../theme/coinka.dart';
import 'ai_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _tgUsername;

  @override
  void initState() {
    super.initState();
    _loadTgStatus();
  }

  Future<void> _loadTgStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = doc.data()?['tgUsername'] as String?;
    if (mounted) setState(() => _tgUsername = username);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isDark = settings.isDarkMode;
    const accentColor = Coinka.accent;

    return Container(
      color: context.ckBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CoinkaHeader(title: 'Настройки'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Профиль
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final displayName = user?.displayName ?? settings.userName;
                      final email = user?.email ?? settings.userEmail;

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

                      return GestureDetector(
                        onTap: () => _showEditDialog(
                          context,
                          'Изменить имя',
                          settings.userName,
                          (value) => settings.setUserName(value),
                          isDark,
                          accentColor,
                        ),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.ckCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.ckBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Coinka.accent2, Coinka.accent],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '👤',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName.isNotEmpty ? displayName : 'Пользователь',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: context.ckText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.ckHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit_rounded,
                                  size: 16, color: context.ckMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Flow AI / Подписка ──
                  _buildSubscriptionCard(context, isDark, accentColor),

                  // ── Аккаунт ──
                  const CoinkaSectionHeader('Аккаунт'),
                  _cgroup([
                    _crow('👤', const Color(0x1F00E5B3), 'Имя',
                        settings.userName.isNotEmpty ? settings.userName : '—',
                        () => _showEditDialog(context, 'Изменить имя',
                            settings.userName,
                            (v) => settings.setUserName(v), isDark, accentColor)),
                    _crow('✉️', const Color(0x1F7B6FF0), 'Email',
                        settings.userEmail.isNotEmpty ? settings.userEmail : '—',
                        () => _showEmailChangeDialog(context, isDark, accentColor)),
                    _crow('🔒', const Color(0x1FFF4D6D), 'Пароль', '••••••••',
                        () => _showPasswordDialog(
                            context, settings, isDark, accentColor)),
                    _crow('✈️', const Color(0x1F26A5E4), 'Telegram-бот',
                        _tgUsername != null ? '@$_tgUsername' : 'Не подключён',
                        () => _showTelegramLinkDialog(context, isDark)),
                  ]),

                  // ── Общие ──
                  const CoinkaSectionHeader('Общие'),
                  _cgroup([
                    _crowSwitch('🌙', const Color(0x1F7B6FF0), 'Тёмная тема',
                        isDark, (v) => settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light)),
                    _crow('💱', const Color(0x1F00E5B3), 'Валюта',
                        settings.currency,
                        () => _showCurrencyDialog(
                            context, settings, isDark, accentColor)),
                    _crow('📊', const Color(0x1F7B6FF0), 'Статистика',
                        'Аналитика и графики', () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AnalyticsScreen()));
                    }),
                    _crow('📋', const Color(0x1FFF4D6D), 'Шаблоны',
                        'Управление шаблонами', () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TemplatesScreen()));
                    }),
                  ]),

                  // ── Данные ──
                  const CoinkaSectionHeader('Данные'),
                  _cgroup([
                    _crow('📤', const Color(0x1F00E5B3), 'Экспорт смен',
                        'В системный календарь',
                        () => _exportShiftsToCalendar(
                            context, isDark, accentColor)),
                    _crow('📥', const Color(0x1F7B6FF0), 'Экспорт задач',
                        'В системный календарь',
                        () => _exportTasksToCalendar(
                            context, isDark, accentColor)),
                  ]),

                  // ── О приложении ──
                  const CoinkaSectionHeader('О приложении'),
                  _cgroup([
                    _crow('ℹ️', const Color(0x0FFFFFFF), 'Версия', 'Flow 2.1', null),
                    _crow('💬', const Color(0x1F00E5B3), 'Обратная связь',
                        'Отправить отзыв',
                        () => _showFeedbackDialog(context, isDark)),
                    _crow('❤️', const Color(0x1FFF4D6D), 'Поддержать проект',
                        'Поддержать разработку',
                        () => _showSupportDialog(context, isDark)),
                    _crow('🛡️', const Color(0x1F7B6FF0),
                        'Политика конфиденциальности', '',
                        () => _openLegalDocument(context, 'privacy')),
                    _crow('📄', const Color(0x1F7B6FF0),
                        'Пользовательское соглашение', '',
                        () => _openLegalDocument(context, 'terms')),
                    _crow('✅', const Color(0x1F7B6FF0),
                        'Согласие на обработку данных', '152-ФЗ РФ',
                        () => _openLegalDocument(context, 'consent')),
                  ]),

                  // ── Выход / удаление ──
                  const SizedBox(height: 16),
                  _cgroup([
                    _crow('🚪', const Color(0x1FFF4D6D), 'Выйти из аккаунта', '',
                        () => _handleLogout(context, isDark),
                        danger: true),
                    _crow('🗑️', const Color(0x1FFF4D6D), 'Удалить аккаунт',
                        'Безвозвратно удалить все данные',
                        () => _deleteAccount(context),
                        danger: true),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _aiFeatures = [
    'Прогноз доходов на месяц вперёд',
    'AI-советы по расходам',
    'Сканирование чеков',
    'Голосовой ввод смен',
  ];

  /// Группа строк настроек (карточка как в Coinka).
  Widget _cgroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.ckCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.ckBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  /// Строка настроек: эмодзи в цветном квадрате + заголовок + значение.
  Widget _crow(String emoji, Color iconBg, String title, String subtitle,
      VoidCallback? onTap,
      {bool danger = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.ckBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: danger ? Coinka.red : context.ckText,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 12, color: context.ckHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Text('›',
                    style: TextStyle(fontSize: 18, color: context.ckMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crowSwitch(String emoji, Color iconBg, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.ckBorder))),
      child: Row(children: [
        Container(
          width: 34, height: 34, alignment: Alignment.center,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Text(emoji, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.ckText))),
        Transform.scale(
          scale: 0.85,
          child: CupertinoSwitch(value: value, activeColor: Coinka.accent, onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); }),
        ),
      ]),
    );
  }

  Future<String> _getTelegramLinkCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';

    // Генерируем код и пишем в linkCodes — именно там бот его ищет
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();

    await FirebaseFirestore.instance.collection('linkCodes').doc(code).set({
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
    });

    return code;
  }

  void _showTelegramLinkDialog(BuildContext context, bool isDark) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final code = await _getTelegramLinkCode();
    if (!context.mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('✈️ ', style: TextStyle(fontSize: 20)),
          Text('Telegram-бот',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            )),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_tgUsername != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A5E4).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Color(0xFF26A5E4), size: 18),
                  const SizedBox(width: 8),
                  Text('@$_tgUsername подключён',
                    style: const TextStyle(color: Color(0xFF26A5E4), fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _tgUsername != null
                ? 'Чтобы переподключить другой аккаунт, отправь боту новый код:'
                : 'Отправь боту этот код, чтобы привязать аккаунт:',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Открой @flowjobandmoneybot в Telegram и отправь команду /link $code',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Закрыть', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Скопировать'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '/link $code'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Команда скопирована — вставь в Telegram'),
                backgroundColor: const Color(0xFF26A5E4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A5E4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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

  void _showEmailChangeDialog(BuildContext context, bool isDark, Color accentColor) {
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Изменить email', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Введите новый email и текущий пароль для подтверждения.',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(height: 14),
              _buildAuthField(newEmailCtrl, 'Новый email', isDark, accentColor, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildAuthField(passwordCtrl, 'Текущий пароль', isDark, accentColor, obscure: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Отмена', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                final newEmail = newEmailCtrl.text.trim();
                final password = passwordCtrl.text;
                if (newEmail.isEmpty || !newEmail.contains('@')) return;
                if (password.isEmpty) return;
                setS(() => loading = true);
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) throw Exception('Пользователь не найден');
                  // Re-auth
                  final cred = EmailAuthProvider.credential(email: user.email!, password: password);
                  await user.reauthenticateWithCredential(cred);
                  // Отправляем письмо для подтверждения нового email
                  await user.verifyBeforeUpdateEmail(newEmail);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ Письмо отправлено на $newEmail. Подтвердите его для смены.'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 5),
                    ));
                  }
                } on FirebaseAuthException catch (e) {
                  setS(() => loading = false);
                  final msg = e.code == 'wrong-password' ? 'Неверный пароль'
                    : e.code == 'email-already-in-use' ? 'Этот email уже используется'
                    : e.code == 'invalid-email' ? 'Неверный формат email'
                    : 'Ошибка: ${e.message}';
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                } catch (e) {
                  setS(() => loading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Отправить письмо'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthField(TextEditingController ctrl, String hint, bool isDark, Color accentColor,
      {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        filled: true,
        fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 2)),
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
            onPressed: () async {
              final oldPwd = oldPasswordController.text.trim();
              final newPwd = newPasswordController.text.trim();
              if (oldPwd.isEmpty || newPwd.isEmpty) return;
              Navigator.pop(context);
              final authProv = Provider.of<auth.AuthProvider>(context, listen: false);
              final ok = await authProv.changePassword(
                currentPassword: oldPwd,
                newPassword: newPwd,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '✅ Пароль изменён' : authProv.errorMessage ?? 'Ошибка'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
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
                Provider.of<SubscriptionProvider>(context, listen: false).reset();
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
      final expiresAt = subscriptionProvider.expiresAt;
      final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : null;
      final dateStr = expiresAt != null
          ? 'до ${expiresAt.day.toString().padLeft(2, '0')}.${expiresAt.month.toString().padLeft(2, '0')}.${expiresAt.year}'
          : 'Бессрочная';

      return EnhancedGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8b7ff5).withOpacity(0.18),
            const Color(0xFF6c5ce7).withOpacity(0.08),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8b7ff5), Color(0xFF6c5ce7)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium активна',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1e293b))),
                  Text(
                    daysLeft != null ? '$dateStr · ещё $daysLeft ${_getDaysWord(daysLeft)}' : dateStr,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF8b7ff5), size: 20),
          ],
        ),
      );
    } else {
      return EnhancedGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.workspace_premium, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flow Premium',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1e293b))),
                      Text('299 ₽ / месяц',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureRow('✦', 'Flow AI — финансовый советник', isDark),
            _buildFeatureRow('📊', 'Расширенная аналитика расходов', isDark),
            _buildFeatureRow('🚫', 'Без рекламы', isDark),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Получить Premium',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

      final result = await calendarService.exportAllShifts(shifts);

      if (context.mounted) {
        final msg = result.ok == result.total
            ? '✅ Экспортировано смен: ${result.ok}'
            : '⚠️ Экспортировано ${result.ok} из ${result.total}. Ошибка: ${result.firstError}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: result.ok > 0 ? Colors.green : Colors.red,
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

      final result = await calendarService.exportAllTasks(tasks);

      if (context.mounted) {
        final msg = result.ok == result.total
            ? '✅ Экспортировано задач: ${result.ok}'
            : '⚠️ Экспортировано ${result.ok} из ${result.total}. Ошибка: ${result.firstError}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: result.ok > 0 ? Colors.green : Colors.red,
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
