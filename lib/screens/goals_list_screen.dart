import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/coinka.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isNotEmpty) context.read<GoalProvider>().loadGoals(userId);
    });
  }

  String _fmt(double v) {
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf ₽';
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(child: Text('Цели', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.ckText))),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen()))
                          .then((_) {
                        final userId = context.read<AuthProvider>().userId;
                        if (userId.isNotEmpty) context.read<GoalProvider>().loadGoals(userId);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]), borderRadius: BorderRadius.circular(20)),
                      child: const Text('+ Добавить', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<GoalProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Coinka.accent));
                  }
                  if (provider.goals.isEmpty) {
                    return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text('Нет целей', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ctx.ckText)),
                        const SizedBox(height: 8),
                        Text('Создай первую накопительную\nцель прямо сейчас', style: TextStyle(fontSize: 14, color: ctx.ckHint), textAlign: TextAlign.center),
                      ],
                    ));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: provider.goals.length,
                    itemBuilder: (ctx, i) {
                      final goal = provider.goals[i];
                      final progress = goal.progress;
                      final isCompleted = goal.isCompleted;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(ctx, MaterialPageRoute(builder: (_) => EditGoalScreen(goal: goal)))
                              .then((_) {
                            final userId = ctx.read<AuthProvider>().userId;
                            if (userId.isNotEmpty) ctx.read<GoalProvider>().loadGoals(userId);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ctx.ckCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isCompleted ? Coinka.accent.withOpacity(0.4) : ctx.ckBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(goal.icon, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(goal.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.ckText)),
                                      Text(_fmt(goal.targetAmount), style: TextStyle(fontSize: 12, color: ctx.ckHint)),
                                    ],
                                  )),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Coinka.accentDim, borderRadius: BorderRadius.circular(8)),
                                      child: const Text('✓ Готово', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Coinka.accent)),
                                    )
                                  else
                                    Text('${(progress * 100).round()}%',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Coinka.accent)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress, minHeight: 6,
                                  backgroundColor: ctx.ckS2,
                                  valueColor: const AlwaysStoppedAnimation(Coinka.accent),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${_fmt(goal.currentAmount)} из ${_fmt(goal.targetAmount)}',
                                style: TextStyle(fontSize: 12, color: ctx.ckHint)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
