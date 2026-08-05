import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';
import 'payment_screen.dart';

const _kAdviceUrl = 'https://flow-ai.prostozapaska.workers.dev';

// ─── Data models ──────────────────────────────────────────────────────────────

class _Msg {
  final String role; // 'user' | 'ai'
  final String text;
  int feedback; // 0=none, 1=good, -1=bad
  _Msg({required this.role, required this.text, this.feedback = 0});

  Map<String, String> toApiTurn() => {'role': role == 'ai' ? 'assistant' : 'user', 'content': text};
}

// ─── Quick suggestions ────────────────────────────────────────────────────────

class _Suggestion {
  final String label;
  final String msg;
  const _Suggestion(this.label, this.msg);
}

const _kSuggestions = [
  _Suggestion('🔍 Разбор расходов',
    'Выступи в роли финансового консультанта. '
    'На основе моих расходов за этот месяц раздели их на категории: '
    'обязательные, полезные, эмоциональные, импульсивные, бесполезные. '
    'Покажи: 1. На что ушло больше всего денег. '
    '2. Какие расходы можно сократить без снижения качества жизни. '
    '3. Сколько денег я смогу экономить ежемесячно. '
    '4. Три главные финансовые ошибки месяца.'),
  _Suggestion('📈 Прогноз дохода', 'Сколько я заработаю в следующем месяце?'),
  _Suggestion('💡 Советы по расходам', 'Дай 3 совета по расходам'),
  _Suggestion('💼 Как увеличить доход?', 'Как увеличить доход?'),
  _Suggestion('📊 Отчёт за месяц', 'Составь подробный отчёт за этот месяц'),
  _Suggestion('🎯 Финансовые цели', 'Помоги поставить финансовые цели на следующий месяц'),
];

// ─── Main screen ──────────────────────────────────────────────────────────────

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _speech = SpeechToText();

  bool _loadingCtx = true;
  bool _thinking = false;
  bool _listening = false;
  bool _speechAvail = false;
  String _provider = 'claude'; // 'claude' | 'gemini'

  // User context (same as Telegram bot)
  double _shiftEarn = 0;
  double _income = 0;
  double _expense = 0;
  int _shiftCount = 0;
  double _forecast = 0;
  String _topExpense = '—';
  double _savingsRate = 0;
  Map<String, double> _expByCat = {};

  final List<_Msg> _messages = [];
  late String _sessionId;
  String? _uid;

  late AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _sessionId = _buildSessionId();
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _speech.initialize().then((ok) { if (mounted) setState(() => _speechAvail = ok); });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  String _buildSessionId() {
    final d = DateTime.now();
    return 'app_${d.year}${d.month}${d.day}';
  }

  // ── Boot: load context + history ──────────────────────────────────────────

  Future<void> _boot() async {
    _uid = context.read<AuthProvider>().userId;
    if (_uid == null || _uid!.isEmpty) {
      if (mounted) setState(() => _loadingCtx = false);
      return;
    }
    await Future.wait([_loadContext(), _loadHistory()]);
    if (mounted && _messages.isEmpty) {
      _addGreeting();
    }
    if (mounted) setState(() => _loadingCtx = false);
  }

  Future<void> _loadContext() async {
    final now = DateTime.now();
    final ms = DateTime(now.year, now.month, 1);
    final me = DateTime(now.year, now.month + 1, 1);
    final ms3 = DateTime(now.year, now.month - 3, 1);

    try {
      final shifts = await FirebaseFirestore.instance
          .collection('users').doc(_uid!).collection('shifts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(ms3))
          .where('date', isLessThan: Timestamp.fromDate(me))
          .get();

      double earn = 0;
      int count = 0;
      final monthlyEarns = <String, double>{};
      final curKey = '${now.year}-${now.month}';

      for (final d in shifts.docs) {
        final s = d.data();
        final dt = (s['date'] as Timestamp).toDate();
        final key = '${dt.year}-${dt.month}';
        final st = (s['startTime'] as Timestamp).toDate();
        final en = (s['endTime'] as Timestamp).toDate();
        final ph = (s['paidTime'] ?? 0.0) as num;
        final h = ph > 0 ? ph.toDouble() : en.difference(st).inMinutes / 60.0;
        final pt = s['paymentType'] ?? 'hourly';
        final e = pt == 'hourly' ? (s['hourlyRate'] ?? 0.0) * h : (s['shiftRate'] ?? 0.0);
        final tot = e + (s['bonus'] ?? 0.0) - (s['expenses'] ?? 0.0);
        monthlyEarns[key] = (monthlyEarns[key] ?? 0) + tot;
        if (key == curKey) { earn += tot; count++; }
      }

      final pastMonths = monthlyEarns.entries.where((e) => e.key != curKey).toList();
      final fc = pastMonths.isEmpty ? earn
          : pastMonths.fold(0.0, (a, e) => a + e.value) / pastMonths.length;

      final txSnap = await FirebaseFirestore.instance
          .collection('users').doc(_uid!).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(ms))
          .where('date', isLessThan: Timestamp.fromDate(me))
          .get();

      double inc = 0, exp = 0;
      final expByCat = <String, double>{};
      for (final d in txSnap.docs) {
        final t = d.data();
        final amt = ((t['amount'] ?? 0) as num).abs().toDouble();
        if (t['type'] == 'income' || t['isIncome'] == true) {
          inc += amt;
        } else {
          exp += amt;
          final cat = t['category'] ?? 'Другое';
          expByCat[cat] = (expByCat[cat] ?? 0) + amt;
        }
      }
      final sorted = expByCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.isEmpty ? '—' : sorted.take(2).map((e) => '${e.key}: ${e.value.round()}₽').join(', ');
      final totalInc = inc + earn;

      if (mounted) {
        setState(() {
          _shiftEarn = earn; _shiftCount = count;
          _income = totalInc; _expense = exp;
          _forecast = fc;
          _topExpense = top;
          _expByCat = expByCat;
          _savingsRate = totalInc > 0 ? (totalInc - exp) / totalInc * 100 : 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_uid!).collection('aiChats').doc(_sessionId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limit(20)
          .get();
      if (snap.docs.isEmpty) return;
      final loaded = snap.docs.map((d) {
        final data = d.data();
        return _Msg(
          role: data['role'] == 'assistant' ? 'ai' : 'user',
          text: data['content'] ?? '',
        );
      }).toList();
      if (mounted) setState(() => _messages.addAll(loaded));
    } catch (_) {}
  }

  void _addGreeting() {
    final avgShift = _shiftCount > 0 ? (_shiftEarn / _shiftCount).round() : 0;
    setState(() {
      _messages.add(_Msg(
        role: 'ai',
        text: 'Привет! Я Flow AI ✦\n\n'
            'В этом месяце ты заработал ${_fmt(_shiftEarn)} на $_shiftCount сменах. '
            'Средняя смена — ${_fmt(avgShift.toDouble())}. '
            'Прогноз на следующий месяц — ${_fmt(_forecast)}.\n\n'
            'Задай любой вопрос о своих финансах или работе 👇',
      ));
    });
  }

  // ── Context map for API ───────────────────────────────────────────────────

  Map<String, dynamic> get _ctx => {
    'shiftEarnings': _shiftEarn.round(),
    'shiftCount': _shiftCount,
    'avgShift': _shiftCount > 0 ? (_shiftEarn / _shiftCount).round() : 0,
    'totalIncome': _income.round(),
    'totalExpense': _expense.round(),
    'balance': (_income - _expense).round(),
    'forecast': _forecast.round(),
    'savingsRate': _savingsRate.round(),
    'topExpenseCategories': _topExpense,
    'expenseCategories': _expByCat.map((k, v) => MapEntry(k, v.round())),
  };

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _thinking) return;
    _msgCtrl.clear();
    final userMsg = _Msg(role: 'user', text: text.trim());
    setState(() { _messages.add(userMsg); _thinking = true; });
    _scrollToBottom();

    // Build history for API (exclude current message)
    final history = _messages
        .where((m) => m != userMsg)
        .map((m) => m.toApiTurn())
        .toList();

    try {
      final resp = await http.post(
        Uri.parse(_kAdviceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text.trim(),
          'context': _ctx,
          'history': history,
          'uid': _uid,
          'sessionId': _sessionId,
          'provider': _provider,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(resp.body) as Map;
      if (resp.statusCode != 200) {
        final errMsg = data['error']?.toString() ?? 'Ошибка сервера ${resp.statusCode}';
        throw Exception(errMsg);
      }
      final reply = (data['reply'] as String?)?.trim();
      if (reply == null || reply.isEmpty) throw Exception('Пустой ответ сервера');
      if (mounted) {
        setState(() {
          _messages.add(_Msg(role: 'ai', text: reply));
          _thinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errText = e.toString().contains('SocketException') || e.toString().contains('TimeoutException') || e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')
        ? '🌐 Сервер недоступен.\n\nВозможно, `flow-bot-rosy.vercel.app` заблокирован в вашей сети. Попробуйте VPN или подключитесь к другой сети.'
        : '😔 Ошибка: ${e.toString().replaceAll('Exception: ', '')}';
      if (mounted) {
        setState(() {
          _messages.add(_Msg(role: 'ai', text: errText));
          _thinking = false;
        });
      }
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<void> _setFeedback(_Msg msg, int rating) async {
    HapticFeedback.lightImpact();
    setState(() => msg.feedback = rating);
    if (_uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('_aiStats').doc('feedback')
          .set({rating > 0 ? 'thumbsUp' : 'thumbsDown': FieldValue.increment(1)}, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('users').doc(_uid!).collection('aiChats').doc(_sessionId)
          .set({'lastFeedback': rating, 'feedbackAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Voice ─────────────────────────────────────────────────────────────────

  Future<void> _toggleVoice() async {
    if (!_speechAvail) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
    } else {
      setState(() => _listening = true);
      await _speech.listen(
        onResult: (r) {
          if (r.finalResult) {
            _msgCtrl.text = r.recognizedWords;
            if (mounted) setState(() => _listening = false);
          }
        },
        localeId: 'ru_RU',
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
      }
    });
  }

  String _fmt(double v) => '${v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} ₽';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final isDark = settings.isDarkMode;
    final accent = settings.accentColor;

    if (!sub.canUseAI) return _PaywallScreen(accent: accent, isDark: isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a14) : const Color(0xFFF5F5FA),
      body: Column(
        children: [
          _Header(
            accent: accent, isDark: isDark,
            provider: _provider,
            onToggleProvider: () => setState(() => _provider = _provider == 'claude' ? 'gemini' : 'claude'),
          ),
          if (_loadingCtx)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            _ForecastCard(
              shiftEarn: _shiftEarn, income: _income, expense: _expense,
              forecast: _forecast, savingsRate: _savingsRate, accent: accent, fmt: _fmt,
            ),
            Expanded(child: _buildChat(isDark, accent)),
            _buildInput(isDark, accent),
          ],
        ],
      ),
    );
  }

  Widget _buildChat(bool isDark, Color accent) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      itemCount: _messages.length + (_thinking ? 1 : 0),
      itemBuilder: (_, i) {
        if (_thinking && i == _messages.length) return _TypingBubble(ctrl: _dotCtrl, accent: accent);
        final msg = _messages[i];
        final isLast = i == _messages.length - 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bubble(msg: msg, accent: accent, isDark: isDark),
            // Feedback buttons on last AI message
            if (msg.role == 'ai' && isLast && !_thinking)
              Padding(
                padding: const EdgeInsets.only(left: 38, bottom: 4),
                child: Row(children: [
                  _FbBtn(icon: Icons.thumb_up_rounded, active: msg.feedback == 1,
                    color: Colors.green, onTap: () => _setFeedback(msg, 1)),
                  const SizedBox(width: 6),
                  _FbBtn(icon: Icons.thumb_down_rounded, active: msg.feedback == -1,
                    color: Colors.red, onTap: () => _setFeedback(msg, -1)),
                ]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInput(bool isDark, Color accent) {
    final hasMsgs = _messages.length > 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0f0f18) : Colors.white,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Suggestions (only before chat starts)
            if (!hasMsgs)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kSuggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _send(_kSuggestions[i].msg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16162a) : const Color(0xFFEEEEF8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Text(_kSuggestions[i].label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                    ),
                  ),
                ),
              ),
            if (!hasMsgs) const SizedBox(height: 8),
            // Input row
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: _listening ? '🎙 Слушаю…' : 'Спроси что-нибудь…',
                    hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.35), fontSize: 14),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF16162a) : const Color(0xFFF0F0F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              if (_speechAvail)
                _CircleBtn(
                  icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  bg: _listening ? const Color(0xFFff4d6d) : accent.withOpacity(0.15),
                  fg: _listening ? Colors.white : accent,
                  onTap: _toggleVoice,
                ),
              const SizedBox(width: 8),
              _CircleBtn(
                icon: Icons.arrow_upward_rounded,
                bg: accent,
                fg: Colors.black,
                onTap: () => _send(_msgCtrl.text),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final String provider;
  final VoidCallback onToggleProvider;
  const _Header({required this.accent, required this.isDark, required this.provider, required this.onToggleProvider});

  @override
  Widget build(BuildContext context) {
    final isGemini = provider == 'gemini';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF1a1240), accent.withOpacity(0.22)],
        ),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 14),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [accent, const Color(0xFF7b6ff0)]),
            ),
            child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Flow AI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.4)),
            Text('Умный финансовый советник', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
          ])),
          // Provider toggle
          GestureDetector(
            onTap: onToggleProvider,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isGemini ? const Color(0xFF1a73e8).withOpacity(0.2) : accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isGemini ? const Color(0xFF4285f4) : accent, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(isGemini ? '✦' : '◆', style: TextStyle(
                  fontSize: 10, color: isGemini ? const Color(0xFF4285f4) : accent)),
                const SizedBox(width: 5),
                Text(isGemini ? 'Gemini' : 'Claude',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isGemini ? const Color(0xFF4285f4) : accent)),
              ]),
            ),
          ),
        ]),
      )),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final double shiftEarn, income, expense, forecast, savingsRate;
  final Color accent;
  final String Function(double) fmt;
  const _ForecastCard({required this.shiftEarn, required this.income, required this.expense,
    required this.forecast, required this.savingsRate, required this.accent, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF12122a), Color(0xFF1a1a3a)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
            child: const Text('Прогноз', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
          ),
          const Spacer(),
          Text('следующий месяц', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ожидаемый доход', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            Text(fmt(forecast), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.8)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Баланс сейчас', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            Text(fmt(balance), style: TextStyle(color: balance >= 0 ? accent : const Color(0xFFff4d6d),
              fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (savingsRate / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(accent),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text('Норма сбережений: ${savingsRate.round()}%',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final Color accent;
  final bool isDark;
  const _Bubble({required this.msg, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAI = msg.role == 'ai';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(width: 26, height: 26, margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent, const Color(0xFF7b6ff0)])),
              child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 11)))),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: isAI ? (isDark ? const Color(0xFF16162a) : const Color(0xFFEEEEF8)) : accent.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isAI ? 4 : 18), bottomRight: Radius.circular(isAI ? 18 : 4),
              ),
              border: isAI ? Border.all(color: Colors.white.withOpacity(0.06)) : null,
            ),
            child: Text(msg.text,
              style: TextStyle(fontSize: 14, color: isAI ? (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.85)) : Colors.black.withOpacity(0.88), height: 1.45)),
          )),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  const _TypingBubble({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(width: 26, height: 26, margin: const EdgeInsets.only(right: 8, bottom: 2),
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [accent, const Color(0xFF7b6ff0)])),
          child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 11)))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF16162a),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) => Row(children: List.generate(3, (i) {
              final delay = i * 0.33;
              final val = ((ctrl.value - delay) % 1.0 + 1.0) % 1.0;
              final opacity = (val < 0.5 ? val * 2 : (1 - val) * 2).clamp(0.3, 1.0);
              return Container(width: 6, height: 6, margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(opacity)));
            })),
          ),
        ),
      ]),
    );
  }
}

class _FbBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FbBtn({required this.icon, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        ),
        child: Icon(icon, size: 14, color: active ? color : Colors.white.withOpacity(0.3)),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color bg, fg;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}

// ─── Paywall ──────────────────────────────────────────────────────────────────

class _PaywallScreen extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _PaywallScreen({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a14) : const Color(0xFFF5F5FA),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black), padding: EdgeInsets.zero),
          ]),
          const Spacer(),
          Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: [const Color(0xFF7b6ff0), accent])),
            child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 36)))),
          const SizedBox(height: 24),
          const Text('Flow AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text('Умный учёт с искусственным интеллектом',
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.black45), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          for (final f in ['Прогноз доходов на месяц вперёд', 'AI-советник по финансам', 'Сканирование чеков', 'Голосовой ввод'])
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
              Icon(Icons.auto_awesome_rounded, color: accent, size: 16), const SizedBox(width: 12),
              Text(f, style: const TextStyle(fontSize: 15)),
            ])),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: GestureDetector(
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())); },
            child: Container(
              alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF7b6ff0), accent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Подключить Flow AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          )),
          const Spacer(),
        ]),
      )),
    );
  }
}
