import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/shift_model.dart';
import '../models/template_model.dart';
import '../services/template_service.dart';
import '../theme/coinka.dart';
import 'add_shift_screen.dart';
import 'edit_shift_screen.dart';

/// Вкладка «Смены»: hero-карта заработка, встроенный календарь-сетка,
/// список смен выбранного дня, шаблоны.
class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  DateTime _month = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  bool _templatesOpen = false;

  List<ShiftModel> _shifts = [];
  List<TemplateModel> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final start = DateTime(_month.year, _month.month, 1);
      final end = DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);

      final shiftsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final templates = await TemplateService()
          .getTemplates(userId, type: TemplateType.shift);

      if (!mounted) return;
      setState(() {
        _shifts = shiftsSnap.docs.map(ShiftModel.fromSnapshot).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки смен: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selectedDay = null;
    });
    _loadData();
  }

  String _fmt(double v) {
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${v < 0 ? '−' : ''}$buf $symbol';
  }

  List<ShiftModel> get _visibleShifts {
    if (_selectedDay == null) return _shifts;
    return _shifts
        .where((s) =>
            s.date.year == _selectedDay!.year &&
            s.date.month == _selectedDay!.month &&
            s.date.day == _selectedDay!.day)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final earnings = _shifts.fold(0.0, (sum, s) => sum + s.totalEarnings);
    final hours = _shifts.fold(0.0, (sum, s) => sum + s.totalHours);
    final avg = _shifts.isEmpty ? 0.0 : earnings / _shifts.length;

    return Container(
      color: context.ckBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CoinkaHeader(
              title: 'Смены',
              trailing: CoinkaMonthNav(
                label: '${coinkaMonths[_month.month - 1]} ${_month.year != DateTime.now().year ? _month.year : ''}'.trim(),
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: Coinka.accent,
                backgroundColor: context.ckS2,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    CoinkaHero(
                      label: 'Заработано за месяц',
                      value: _isLoading ? '—' : _fmt(earnings),
                      stats: [
                        CoinkaHeroStat(
                          value: _isLoading ? '—' : '${_shifts.length}',
                          label: 'смен',
                        ),
                        CoinkaHeroStat(
                          value: _isLoading ? '—' : '${hours.toStringAsFixed(0)}ч',
                          label: 'часов',
                        ),
                        CoinkaHeroStat(
                          value: _isLoading ? '—' : _fmt(avg),
                          label: 'ср/смена',
                        ),
                      ],
                    ),
                    _buildCalendarGrid(),
                    if (_selectedDay != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                        child: Row(
                          children: [
                            Text(
                              '${_selectedDay!.day} ${coinkaMonths[_selectedDay!.month - 1].toLowerCase()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Coinka.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _selectedDay = null),
                              child: Text(
                                '× сбросить',
                                style: TextStyle(
                                    fontSize: 12, color: context.ckHint),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Coinka.accent,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (_visibleShifts.isEmpty)
                      CoinkaEmpty(
                        emoji: '📅',
                        text: _selectedDay == null
                            ? 'Нет смен в этом месяце.\nДобавь первую!'
                            : 'Нет смен в этот день',
                      )
                    else
                      ..._visibleShifts.map(_buildShiftCard),
                    _buildTemplatesBlock(),
                    CoinkaAddButton(
                      label: 'Добавить смену',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddShiftScreen(initialDate: _selectedDay),
                          ),
                        ).then((result) {
                          if (result == true) _loadData();
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Календарь-сетка ───────────────────────────────────────────────────────

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingEmpty = (firstDay.weekday + 6) % 7; // Пн=0
    final today = DateTime.now();

    final shiftDays = <int>{};
    for (final s in _shifts) {
      shiftDays.add(s.date.day);
    }

    const dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: context.ckCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.ckBorder),
      ),
      child: Column(
        children: [
          Row(
            children: dayNames
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.ckHint,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          for (int week = 0;
              week * 7 < leadingEmpty + daysInMonth;
              week++)
            Row(
              children: List.generate(7, (wd) {
                final dayNum = week * 7 + wd - leadingEmpty + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                final isToday = today.year == _month.year &&
                    today.month == _month.month &&
                    today.day == dayNum;
                final isSelected = _selectedDay != null &&
                    _selectedDay!.day == dayNum &&
                    _selectedDay!.month == _month.month;
                final hasShift = shiftDays.contains(dayNum);

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        final tapped =
                            DateTime(_month.year, _month.month, dayNum);
                        _selectedDay =
                            _selectedDay == tapped ? null : tapped;
                      });
                    },
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? Coinka.accentDim : null,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: const Color(0x4D00E5B3))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected || isToday
                                  ? Coinka.accent
                                  : context.ckText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasShift
                                  ? Coinka.accent
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // ─── Карточка смены ────────────────────────────────────────────────────────

  Widget _buildShiftCard(ShiftModel shift) {
    final emoji = shift.emoji?.isNotEmpty == true ? shift.emoji! : '💼';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditShiftScreen(shift: shift)),
        ).then((result) {
          if (result == true) _loadData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.ckBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x267B6FF0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.name.isNotEmpty ? shift.name : 'Смена',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.ckText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shift.date.day} ${coinkaMonths[shift.date.month - 1].toLowerCase()} · ${shift.timeRange} · ${shift.totalHours.toStringAsFixed(1)}ч',
                    style: TextStyle(fontSize: 12, color: context.ckHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _fmt(shift.totalEarnings),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Coinka.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Шаблоны ───────────────────────────────────────────────────────────────

  Widget _buildTemplatesBlock() {
    if (_templates.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _templatesOpen = !_templatesOpen);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.ckBorder)),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Шаблоны смен',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.ckText,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _templatesOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: context.ckHint, size: 20),
                ),
              ],
            ),
          ),
        ),
        if (_templatesOpen)
          ..._templates.map((t) => GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddShiftScreen(initialDate: _selectedDay),
                    ),
                  ).then((result) {
                    if (result == true) _loadData();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(44, 11, 14, 11),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.ckBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.ckText,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: context.ckMuted),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
