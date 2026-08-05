import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/template_model.dart';
import '../services/template_service.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/coinka.dart';
import 'main_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final TemplateService _templateService = TemplateService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final userId = authProvider.userId;

    if (!subscriptionProvider.canUseTemplates) {
      return Scaffold(
        backgroundColor: context.ckBg,
        body: SafeArea(child: _buildPremiumRequired()),
      );
    }

    return Scaffold(
      backgroundColor: context.ckBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.ckHint, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(child: Text('Шаблоны смен', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildTemplatesList(userId)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(String userId) {
    return StreamBuilder<List<TemplateModel>>(
      stream: _templateService.templatesStream(userId, type: TemplateType.shift),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Coinka.accent));
        }

        if (snapshot.hasError) {
          return _buildEmptyState(icon: '❌', title: 'Ошибка загрузки', subtitle: 'Не удалось загрузить шаблоны');
        }

        final templates = snapshot.data ?? [];

        if (templates.isEmpty) {
          return _buildEmptyState(
            icon: '💼',
            title: 'Нет шаблонов',
            subtitle: 'Сохрани шаблон при добавлении смены',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          itemCount: templates.length,
          itemBuilder: (context, index) => _buildTemplateCard(templates[index]),
        );
      },
    );
  }

  Widget _buildTemplateCard(TemplateModel template) {
    final data = template.data;
    final paymentType = data['paymentType'] as String? ?? 'hourly';
    final hourlyRate = ((data['hourlyRate'] as num?) ?? 0).toDouble();
    final shiftRate = ((data['shiftRate'] as num?) ?? 0).toDouble();
    final bonus = ((data['bonus'] as num?) ?? 0).toDouble();
    final category = (data['category'] as String? ?? '').trim();
    final startHour = data['startHour'] as int?;
    final startMinute = data['startMinute'] as int? ?? 0;
    final endHour = data['endHour'] as int?;
    final endMinute = data['endMinute'] as int? ?? 0;

    String timeStr = '';
    if (startHour != null && endHour != null) {
      final s = '${startHour.toString().padLeft(2,'0')}:${startMinute.toString().padLeft(2,'0')}';
      final e = '${endHour.toString().padLeft(2,'0')}:${endMinute.toString().padLeft(2,'0')}';
      timeStr = '$s – $e';
    }

    String payStr = '';
    if (paymentType == 'hourly' && hourlyRate > 0) {
      payStr = '${hourlyRate.round()} ₽/ч';
    } else if (paymentType == 'fixed' && shiftRate > 0) {
      payStr = '${shiftRate.round()} ₽/смену';
    }
    if (bonus > 0) payStr += ' + бонус ${bonus.round()} ₽';

    final details = [
      if (category.isNotEmpty) category,
      if (timeStr.isNotEmpty) timeStr,
      if (payStr.isNotEmpty) payStr,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showTemplateOptions(template),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.ckCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.ckBorder)),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Coinka.accentDim, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('💼', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.ckText)),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(details, style: TextStyle(fontSize: 12, color: context.ckHint)),
                  ],
                ],
              )),
              Icon(Icons.chevron_right_rounded, color: context.ckHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: context.ckHint), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showTemplateOptions(TemplateModel template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ckCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 3, decoration: BoxDecoration(color: context.ckMuted, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(template.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText)),
              const SizedBox(height: 20),
              _buildOption(emoji: '✏️', label: 'Переименовать', color: Coinka.accent, onTap: () { Navigator.pop(ctx); _renameTemplate(template); }),
              const SizedBox(height: 8),
              _buildOption(emoji: '🗑️', label: 'Удалить', color: Coinka.red, onTap: () { Navigator.pop(ctx); _deleteTemplate(template); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({required String emoji, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  void _renameTemplate(TemplateModel template) {
    final controller = TextEditingController(text: template.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ckCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Переименовать', style: TextStyle(color: context.ckText, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.ckText, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Название шаблона',
            hintStyle: TextStyle(color: context.ckHint),
            filled: true, fillColor: context.ckS2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.ckBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.ckBorder)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Coinka.accent, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: TextStyle(color: context.ckHint))),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await _templateService.updateTemplate(userId: authProvider.userId, templateId: template.id, name: controller.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                HapticFeedback.heavyImpact();
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Coinka.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(TemplateModel template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ckCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Удалить шаблон?', style: TextStyle(color: context.ckText, fontWeight: FontWeight.w700)),
        content: Text('Это действие нельзя отменить', style: TextStyle(color: context.ckHint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: TextStyle(color: context.ckHint))),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await _templateService.deleteTemplate(authProvider.userId, template.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                HapticFeedback.heavyImpact();
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Coinka.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Coinka.accent2, Coinka.accent]), shape: BoxShape.circle),
              child: const Text('📋', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            Text('Шаблоны — Premium', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.ckText), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Создание и использование шаблонов доступно только с Premium подпиской', style: TextStyle(fontSize: 15, color: context.ckHint, height: 1.4), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialTab: 3)), (r) => false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Coinka.accent2, Coinka.accent]), borderRadius: BorderRadius.all(Radius.circular(14))),
                child: const Text('Получить Premium', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
