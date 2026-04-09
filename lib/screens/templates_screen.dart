import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/template_model.dart';
import '../services/template_service.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/enhanced_glass_card.dart';
import '../providers/subscription_provider.dart';
import 'main_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> with SingleTickerProviderStateMixin {
  final TemplateService _templateService = TemplateService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isDark = settings.isDarkMode;
    final userId = authProvider.userId;

    if (!subscriptionProvider.canUseTemplates) {
      return Scaffold(
        body: AnimatedBackground(
          isDark: isDark,
          child: SafeArea(
            child: _buildPremiumRequired(isDark),
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTabBar(isDark, settings.accentColor),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTemplatesList(userId, TemplateType.shift, isDark),
                    _buildTemplatesList(userId, TemplateType.task, isDark),
                    _buildTemplatesList(userId, TemplateType.transaction, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          EnhancedGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            enableShadow: false,
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Шаблоны',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: EnhancedGlassCard(
        padding: const EdgeInsets.all(1),
        enableHover: false,
        enableShadow: false,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          dividerColor: Colors.transparent,
          dividerHeight: 1,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          onTap: (_) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(text: '💼 Смены'),
            Tab(text: '✅ Задачи'),
            Tab(text: '💰 Операции'),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(String userId, TemplateType type, bool isDark) {
    print('🔵 TEMPLATES: Loading for userId=$userId, type=$type');
    
    return StreamBuilder<List<TemplateModel>>(
      stream: _templateService.templatesStream(userId, type: type),
      builder: (context, snapshot) {
        print('🔵 TEMPLATES: ConnectionState = ${snapshot.connectionState}');
        print('🔵 TEMPLATES: HasError = ${snapshot.hasError}');
        print('🔵 TEMPLATES: Error = ${snapshot.error}');
        print('🔵 TEMPLATES: Data count = ${snapshot.data?.length ?? 0}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Provider.of<SettingsProvider>(context).accentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔴 TEMPLATES ERROR: ${snapshot.error}');
          return _buildEmptyState(
            icon: '❌',
            title: 'Ошибка загрузки',
            subtitle: 'Не удалось загрузить шаблоны: ${snapshot.error}',
            isDark: isDark,
          );
        }

        final templates = snapshot.data ?? [];
        print('🔵 TEMPLATES: Loaded ${templates.length} templates');
        for (var t in templates) {
          print('  - ${t.name} (${t.type})');
        }

        if (templates.isEmpty) {
          return _buildEmptyState(
            icon: TemplateModel.getIconForType(type),
            title: 'Нет шаблонов',
            subtitle: 'Создайте шаблон при добавлении ${_getTypeGenitive(type)}',
            isDark: isDark,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return _buildTemplateCard(templates[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildTemplateCard(TemplateModel template, bool isDark) {
    final settings = Provider.of<SettingsProvider>(context);
    final accentColor = settings.accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EnhancedGlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showTemplateOptions(template, isDark),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  TemplateModel.getIconForType(template.type),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TemplateModel.getNameForType(template.type),
                    style: TextStyle(
                      fontSize: 13,
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
      ),
    );
  }

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateOptions(TemplateModel template, bool isDark) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final accentColor = settings.accentColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1e293b).withOpacity(0.95),
                    const Color(0xFF0f172a).withOpacity(0.95),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    const Color(0xFFf8fafc).withOpacity(0.95),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildOption(
                    icon: Icons.edit,
                    label: 'Переименовать',
                    color: accentColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _renameTemplate(template, isDark);
                    },
                  ),
                  _buildOption(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    color: const Color(0xFFef4444),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteTemplate(template, isDark);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _renameTemplate(TemplateModel template, bool isDark) {
    final controller = TextEditingController(text: template.name);
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
          'Переименовать шаблон',
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
            hintText: 'Название шаблона',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
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
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await _templateService.updateTemplate(
                userId: authProvider.userId,
                templateId: template.id,
                name: controller.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Шаблон переименован'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10b981),
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

  void _deleteTemplate(TemplateModel template, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Удалить шаблон?',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: Text(
          'Это действие нельзя отменить',
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
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await _templateService.deleteTemplate(
                authProvider.userId,
                template.id,
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Шаблон удалён'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10b981),
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
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _getTypeGenitive(TemplateType type) {
    switch (type) {
      case TemplateType.shift:
        return 'смены';
      case TemplateType.task:
        return 'задачи';
      case TemplateType.transaction:
        return 'операции';
    }
  }

  Widget _buildPremiumRequired(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8b7ff5), Color(0xFF6c5ce7)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Шаблоны - Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Создание и использование шаблонов доступно только с Premium подпиской',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialTab: 3),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b7ff5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
          ],
        ),
      ),
    );
  }
}
