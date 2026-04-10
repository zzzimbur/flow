import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/firestore_service.dart';

class AccountantReportScreen extends StatefulWidget {
  const AccountantReportScreen({super.key});

  @override
  State<AccountantReportScreen> createState() => _AccountantReportScreenState();
}

class _AccountantReportScreenState extends State<AccountantReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _report = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _expandedEmployeeId;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _firestoreService.getMonthlyReportForAccountant(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      setState(() { _report = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _expandedEmployeeId = null;
    });
    _loadReport();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _expandedEmployeeId = null;
    });
    _loadReport();
  }

  String _monthName(int month) {
    const names = [
      'Январь','Февраль','Март','Апрель','Май','Июнь',
      'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'
    ];
    return names[month - 1];
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }

  String _formatMoney(double amount) {
    return '${amount.toStringAsFixed(0)} ₽';
  }

  String _formatShiftTime(Map<String, dynamic> shift) {
    try {
      final s = (shift['startTime'] as dynamic).toDate() as DateTime;
      final e = (shift['endTime'] as dynamic).toDate() as DateTime;
      return '${s.hour.toString().padLeft(2,'0')}:${s.minute.toString().padLeft(2,'0')} — ${e.hour.toString().padLeft(2,'0')}:${e.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '—';
    }
  }

  String _formatDate(Map<String, dynamic> shift) {
    try {
      final d = (shift['date'] as dynamic).toDate() as DateTime;
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final accent = settings.accentColor;

    final totalHoursAll = _report.fold<double>(0, (s, e) => s + (e['totalHours'] as double));
    final totalEarningsAll = _report.fold<double>(0, (s, e) => s + (e['totalEarnings'] as double));
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFfaf5ff),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Табель сотрудников',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1e293b)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Выбор месяца
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                  color: accent,
                ),
                Text(
                  '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right,
                      color: isCurrentMonth ? Colors.grey : accent),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
          ),

          // Итоговая строка
          if (!_isLoading && _report.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.8), accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Сотрудников', '${_report.length}', Icons.people),
                  _summaryItem('Итого часов', _formatHours(totalHoursAll), Icons.access_time),
                  _summaryItem('Итого начислено', _formatMoney(totalEarningsAll), Icons.payments),
                ],
              ),
            ),

          // Список
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text('Ошибка загрузки', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _loadReport, child: Text('Повторить', style: TextStyle(color: accent))),
                          ],
                        ),
                      )
                    : _report.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                                const SizedBox(height: 12),
                                Text(
                                  'Нет данных за этот месяц',
                                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _report.length,
                            itemBuilder: (context, i) => _buildEmployeeCard(_report[i], isDark, accent),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, bool isDark, Color accent) {
    final id = employee['employeeId'] as String;
    final isExpanded = _expandedEmployeeId == id;
    final shifts = employee['shifts'] as List<Map<String, dynamic>>;
    final totalHours = employee['totalHours'] as double;
    final totalEarnings = employee['totalEarnings'] as double;
    final shiftsCount = employee['shiftsCount'] as int;
    final name = employee['name'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? accent.withOpacity(0.5) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок карточки
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              _expandedEmployeeId = isExpanded ? null : id;
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withOpacity(0.15),
                    radius: 22,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _chip(Icons.access_time, _formatHours(totalHours), isDark, accent),
                            const SizedBox(width: 8),
                            _chip(Icons.work_outline, '$shiftsCount смен', isDark, accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMoney(totalEarnings),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white38 : Colors.black26,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Развёрнутый список смен
          if (isExpanded && shifts.isNotEmpty) ...[
            Divider(height: 1, color: accent.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Детализация смен:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...shifts.map((shift) => _buildShiftRow(shift, isDark, accent)),
                ],
              ),
            ),
          ],
          if (isExpanded && shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Нет смен за этот месяц',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDark, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 12, color: accent.withOpacity(0.7)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
      ],
    );
  }

  Widget _buildShiftRow(Map<String, dynamic> shift, bool isDark, Color accent) {
    final name = shift['name'] ?? 'Смена';
    final date = _formatDate(shift);
    final time = _formatShiftTime(shift);
    final paymentType = shift['paymentType'] ?? 'hourly';

    double earnings = 0;
    try {
      final s = (shift['startTime'] as dynamic).toDate() as DateTime;
      final e = (shift['endTime'] as dynamic).toDate() as DateTime;
      final hours = e.difference(s).inMinutes / 60.0;
      if (paymentType == 'hourly') {
        final rate = (shift['hourlyRate'] ?? 0.0).toDouble();
        final paid = (shift['paidTime'] ?? 0.0).toDouble();
        earnings = rate * (paid > 0 ? paid : hours);
      } else if (paymentType == 'perShift') {
        earnings = (shift['shiftRate'] ?? 0.0).toDouble();
      }
      earnings += (shift['bonus'] ?? 0.0).toDouble();
      earnings -= (shift['expenses'] ?? 0.0).toDouble();
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1e293b))),
                Text(time, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          if (earnings > 0)
            Text(
              _formatMoney(earnings),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
            ),
        ],
      ),
    );
  }
}
