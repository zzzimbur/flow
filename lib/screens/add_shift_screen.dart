import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';
import '../models/template_model.dart';
import '../providers/subscription_provider.dart';
import '../widgets/app_icons.dart';
import '../theme/coinka.dart';

class AddShiftScreen extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const AddShiftScreen({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  final _emojiController = TextEditingController();
  
  bool _isAllDay = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  String _paymentType = 'hourly';
  double _hourlyRate = 0.0;
  double _paidTime = 0.0;
  double _bonus = 0.0;
  double _expenses = 0.0;
  double _shiftRate = 0.0;

  Color _selectedColor = const Color(0xFF8b7ff5);
  IconData? _selectedIcon = Icons.work_outline;
  bool _isSaving = false;
  bool _isListening = false;
  final _speech = SpeechToText();
  bool _speechAvail = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _startTime = widget.initialTime ?? const TimeOfDay(hour: 9, minute: 0);
    final endHour = (_startTime.hour + 8) % 24;
    _endTime = TimeOfDay(hour: endHour, minute: _startTime.minute);
    _speech.initialize().then((ok) { if (mounted) setState(() => _speechAvail = ok); });
  }

  // Вычисленные свойства для часов и заработка
  double get calculatedHours {
    if (_isAllDay) return 24.0;
    
    final start = DateTime(2024, 1, 1, _startTime.hour, _startTime.minute);
    var end = DateTime(2024, 1, 1, _endTime.hour, _endTime.minute);
    
    // Если конец раньше начала, значит смена через полночь
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      end = end.add(const Duration(days: 1));
    }
    
    final difference = end.difference(start);
    return difference.inMinutes / 60.0;
  }

  double get calculatedEarnings {
  if (_paymentType == 'unpaid') return 0.0;
  
  double earnings = 0.0;
  if (_paymentType == 'hourly') {
    final hours = _paidTime > 0 ? _paidTime : calculatedHours;
    earnings = _hourlyRate * hours;
  } else if (_paymentType == 'perShift') {
    earnings = _shiftRate;
  }
  
  return earnings + _bonus - _expenses;
}
  
  final List<Color> _colors = [
    const Color(0xFF8b7ff5),
    const Color(0xFF3b82f6),
    const Color(0xFF10b981),
    const Color(0xFFf59e0b),
    const Color(0xFFef4444),
    const Color(0xFFec4899),
  ];
  
  final List<IconData> _icons = [
    Icons.work_outline,
    Icons.business_center,
    Icons.computer,
    Icons.restaurant,
    Icons.local_shipping,
    Icons.construction,
    Icons.medical_services,
    Icons.school,
    Icons.shopping_bag,
    Icons.palette,
    Icons.camera_alt,
    Icons.headphones,
    Icons.flight,
    Icons.fitness_center,
    Icons.sports_soccer,
    Icons.pets,
    Icons.home,
    Icons.directions_car,
    Icons.cake,
    Icons.local_bar,
    Icons.fastfood,
    Icons.code,
    Icons.brush,
    Icons.design_services,
    Icons.theater_comedy,
    Icons.music_note,
    Icons.library_books,
    Icons.science,
    Icons.engineering,
    Icons.agriculture,
    Icons.local_hospital,
    Icons.store,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  // ─── Coinka input decoration ──────────────────────────────────────────────

  InputDecoration _coinkaInput({String? hint, String? label}) => InputDecoration(
    hintText: hint,
    labelText: label,
    hintStyle: TextStyle(color: context.ckHint, fontSize: 15),
    labelStyle: TextStyle(color: context.ckHint, fontSize: 13),
    filled: true,
    fillColor: context.ckS2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.ckBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.ckBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Coinka.accent, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsProvider>().currencySymbol;

    return Scaffold(
      backgroundColor: context.ckBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.ckHint),
                    onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  ),
                  Expanded(
                    child: Text('Новая смена', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: context.ckText,
                    )),
                  ),
                  GestureDetector(
                    onTap: _saveAsTemplate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('📋', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadFromTemplate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text('📂', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isSaving)
                    const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Coinka.accent, strokeWidth: 2))
                  else
                    GestureDetector(
                      onTap: _saveShift,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Coinka.accent2, Coinka.accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Готово', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                        )),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название + голос
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(color: context.ckText, fontSize: 15),
                            decoration: _coinkaInput(hint: 'Например: Дневная смена', label: 'Название'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _toggleVoice,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening ? Coinka.red : Coinka.accentDim,
                            ),
                            child: Icon(
                              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: _isListening ? Colors.white : Coinka.accent,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Категория
                    TextField(
                      controller: _categoryController,
                      style: TextStyle(color: context.ckText, fontSize: 15),
                      decoration: _coinkaInput(hint: 'Например: Офис', label: 'Категория'),
                    ),
                    const SizedBox(height: 20),

                    // Эмодзи
                    _coinkaSection('Эмодзи смены'),
                    const SizedBox(height: 10),
                    _coinkaCard(
                      child: Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.ckS2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.ckBorder),
                            ),
                            child: Text(
                              _emojiController.text.isNotEmpty ? _emojiController.text : '💼',
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _emojiController,
                              maxLength: 2,
                              style: TextStyle(fontSize: 28, color: context.ckText),
                              textAlign: TextAlign.center,
                              decoration: _coinkaInput(hint: '😊').copyWith(counterText: ''),
                              onChanged: (v) { if (v.isNotEmpty) setState(() => _selectedIcon = null); setState(() {}); },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Дата
                    _coinkaSection('Дата'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectDate(true),
                      child: _coinkaCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Дата смены', style: TextStyle(fontSize: 12, color: context.ckHint)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedDate.day} ${coinkaMonths[_selectedDate.month - 1].toLowerCase()} ${_selectedDate.year}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.ckText),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today_rounded, color: Coinka.accent, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Длительность
                    _coinkaSection('Длительность'),
                    const SizedBox(height: 10),
                    _coinkaCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Весь день', style: TextStyle(fontSize: 15, color: context.ckText)),
                              CupertinoSwitch(
                                value: _isAllDay,
                                activeColor: Coinka.accent,
                                onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _isAllDay = v); },
                              ),
                            ],
                          ),
                          if (!_isAllDay) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(child: _buildTimePicker('Начало', _startTime, (t) => setState(() => _startTime = t))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTimePicker('Конец', _endTime, (t) => setState(() => _endTime = t))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Coinka.accentDim,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.schedule_rounded, color: Coinka.accent, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${calculatedHours.toStringAsFixed(1)} ч',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Coinka.accent)),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Coinka.accentDim, borderRadius: BorderRadius.circular(10)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wb_sunny_rounded, color: Coinka.accent, size: 18),
                                  SizedBox(width: 8),
                                  Text('24.0 ч', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Coinka.accent)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Тип оплаты
                    _coinkaSection('Тип оплаты'),
                    const SizedBox(height: 10),
                    _buildPaymentTypeSelector(),
                    const SizedBox(height: 14),
                    _buildPaymentFields(currency),
                    const SizedBox(height: 20),

                    // Заметка
                    _coinkaSection('Заметка'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      style: TextStyle(color: context.ckText, fontSize: 15),
                      decoration: _coinkaInput(hint: 'Добавьте заметку...'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinkaSection(String title) => Text(
    title.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ckHint, letterSpacing: 0.8),
  );

  Widget _coinkaCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.ckCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.ckBorder),
    ),
    child: child,
  );

  Widget _buildPaymentTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.ckCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.ckBorder),
      ),
      child: Row(
        children: [
          _buildPaymentTypeChip('Почасовая', 'hourly'),
          _buildPaymentTypeChip('За смену', 'perShift'),
          _buildPaymentTypeChip('Без оплаты', 'unpaid'),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeChip(String label, String value) {
    final isSelected = _paymentType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _paymentType = value); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Coinka.accent2.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Coinka.accent2 : Colors.transparent, width: 1.5),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isSelected ? Coinka.accent2 : context.ckHint,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFields(String currency) {
    if (_paymentType == 'unpaid') return const SizedBox.shrink();

    return _coinkaCard(
      child: Column(
        children: [
          if (_paymentType == 'hourly') ...[
            _buildNumberField('Почасовая ставка', _hourlyRate, (v) => setState(() => _hourlyRate = v)),
            const SizedBox(height: 12),
            Text('Оплачиваемое время', style: TextStyle(fontSize: 13, color: context.ckHint)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.ckText, fontSize: 15),
                  controller: TextEditingController(text: _paidTime > 0 ? _paidTime.floor().toString() : calculatedHours.floor().toString()),
                  decoration: _coinkaInput(label: 'Часы'),
                  onChanged: (val) {
                    final h = int.tryParse(val) ?? 0;
                    final m = ((_paidTime - _paidTime.floor()) * 60).round();
                    setState(() => _paidTime = h + m / 60.0);
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.ckText, fontSize: 15),
                  controller: TextEditingController(text: _paidTime > 0 ? ((_paidTime - _paidTime.floor()) * 60).round().toString() : ((calculatedHours - calculatedHours.floor()) * 60).round().toString()),
                  decoration: _coinkaInput(label: 'Минуты'),
                  onChanged: (val) {
                    final m = int.tryParse(val) ?? 0;
                    final h = _paidTime > 0 ? _paidTime.floor() : calculatedHours.floor();
                    setState(() => _paidTime = h + m / 60.0);
                  },
                )),
              ],
            ),
          ] else ...[
            _buildNumberField('Ставка за смену', _shiftRate, (v) => setState(() => _shiftRate = v)),
          ],
          const SizedBox(height: 12),
          _buildNumberField('Доплата', _bonus, (v) => setState(() => _bonus = v)),
          const SizedBox(height: 12),
          _buildNumberField('Расходы', _expenses, (v) => setState(() => _expenses = v)),
          if (_hourlyRate > 0 || _shiftRate > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x1A00E5B3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Итого заработок:', style: TextStyle(fontSize: 14, color: context.ckHint)),
                  Text('${calculatedEarnings.toStringAsFixed(0)} $currency',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Coinka.accent)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.ckHint)),
        const SizedBox(height: 6),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: context.ckText, fontSize: 15),
          decoration: _coinkaInput(hint: '0'),
          onChanged: (val) => onChanged((double.tryParse(val) ?? 0.0)),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final picked = await IOSTimePicker.show(context: context, initialTime: time, isDark: true);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ckS2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.ckBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: context.ckHint)),
            const SizedBox(height: 4),
            Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Coinka.accent)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isDark) async {
    HapticFeedback.lightImpact();
    
    final picked = await IOSDatePicker.show(
      context: context,
      initialDate: _selectedDate,
      isDark: isDark,
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _toggleVoice() async {
    final sub = context.read<SubscriptionProvider>();
    if (!sub.canUseVoiceInput) { sub.showPremiumDialog(context, 'voice_input'); return; }
    if (!_speechAvail) {
      _showSnackbar('Распознавание речи недоступно на этом устройстве', isError: true);
      return;
    }
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (r) {
          if (r.finalResult) {
            _nameController.text = r.recognizedWords;
            if (mounted) setState(() => _isListening = false);
          }
        },
        localeId: 'ru_RU',
      );
    }
  }

  Future<void> _saveShift() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Введите название смены', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      // Создаём DateTime для начала и конца смены
      DateTime startDateTime;
      DateTime endDateTime;

      if (_isAllDay) {
        // Для "Весь день" - с 00:00 до 00:00 следующего дня
        startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          0, // 00:00
          0,
        );
        
        endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day + 1, // СЛЕДУЮЩИЙ ДЕНЬ
          0, // 00:00
          0,
        );
      } else {
        // Обычная смена с выбранным временем
        startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        
        endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _endTime.hour,
          _endTime.minute,
        );
        
        // Если время окончания меньше или равно времени начала - переносим на следующий день
        if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      }

      final shiftData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'date': Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)),
        'isAllDay': _isAllDay,
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'paymentType': _paymentType,
        'hourlyRate': _hourlyRate,
        'paidTime': _paidTime > 0 ? _paidTime : calculatedHours,
        'bonus': _bonus,
        'expenses': _expenses,
        'shiftRate': _shiftRate,
        'color': _selectedColor.value,
        'icon': _selectedIcon?.codePoint,
        'emoji': _emojiController.text.trim().isEmpty ? null : _emojiController.text.trim(),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .add(shiftData);

      HapticFeedback.heavyImpact();
      
      if (mounted) {
        _showSnackbar('✅ Смена создана!', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Ошибка сохранения смены: $e');
      setState(() => _isSaving = false);
      _showSnackbar('Ошибка: ${e.toString()}', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : isError ? Icons.error : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF10b981)
            : isError
                ? const Color(0xFFef4444)
                : const Color(0xFF8b7ff5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveAsTemplate() async {
    print('🔵 НАЧАЛО: _saveAsTemplate вызван');
    
    if (_nameController.text.trim().isEmpty) {
      print('🔴 ОШИБКА: Название смены пустое');
      _showSnackbar('Введите название смены', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();

    final templateName = await _showTemplateNameDialog();
    print('🔵 Введено имя шаблона: $templateName');
    
    if (templateName == null || templateName.trim().isEmpty) {
      print('🔴 ОТМЕНА: Имя шаблона не введено');
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      print('🔵 UserID: $userId');

      if (userId.isEmpty) {
        throw Exception('Пользователь не авторизован');
      }

      final shiftData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'isAllDay': _isAllDay,
        'startHour': _startTime.hour,
        'startMinute': _startTime.minute,
        'endHour': _endTime.hour,
        'endMinute': _endTime.minute,
        'paymentType': _paymentType,
        'hourlyRate': _hourlyRate,
        'paidTime': _paidTime > 0 && _paidTime != calculatedHours ? _paidTime : calculatedHours,
        'bonus': _bonus,
        'expenses': _expenses,
        'shiftRate': _shiftRate,
        'color': _selectedColor.value,
        'icon': _selectedIcon?.codePoint,
        'emoji': _emojiController.text.trim().isEmpty ? null : _emojiController.text.trim(),
        'note': _noteController.text.trim(),
      };
      
      print('🔵 Данные для шаблона: $shiftData');

      final templateService = TemplateService();
      final templateId = await templateService.createTemplateFromShift(
        userId: userId,
        name: templateName.trim(),
        shiftData: shiftData,
      );

      print('🔵 Шаблон сохранен с ID: $templateId');

      if (templateId != null) {
        HapticFeedback.heavyImpact();
        _showSnackbar('✅ Шаблон "${templateName}" создан!', isSuccess: true);
      } else {
        print('🔴 ОШИБКА: templateId = null');
        _showSnackbar('Ошибка создания шаблона', isError: true);
      }
    } catch (e) {
      print('🔴 EXCEPTION: $e');
      _showSnackbar('Ошибка: ${e.toString()}', isError: true);
    }
  }

  Future<String?> _showTemplateNameDialog() async {
    final controller = TextEditingController();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Название шаблона',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
          decoration: InputDecoration(
            hintText: 'Например: Дневная смена',
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
              borderSide: const BorderSide(color: Color(0xFF8b7ff5), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8b7ff5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFromTemplate() async {
    HapticFeedback.mediumImpact();
    
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    
    if (userId.isEmpty) {
      _showSnackbar('Пользователь не авторизован', isError: true);
      return;
    }
    
    // Загружаем список шаблонов
    final templateService = TemplateService();
    final templates = await templateService.getTemplates(userId, type: TemplateType.shift);
    
    if (templates.isEmpty) {
      _showSnackbar('Нет сохраненных шаблонов', isError: true);
      return;
    }
    
    // Показываем диалог выбора шаблона
    final selectedTemplate = await _showTemplatePickerDialog(templates);
    
    if (selectedTemplate != null) {
      // Загружаем данные из шаблона
      setState(() {
        final data = selectedTemplate.data;
        
        _nameController.text = data['name'] ?? '';
        _categoryController.text = data['category'] ?? '';
        _isAllDay = data['isAllDay'] ?? false;
        if (data['startHour'] != null) {
          _startTime = TimeOfDay(hour: data['startHour'] as int, minute: (data['startMinute'] ?? 0) as int);
        }
        if (data['endHour'] != null) {
          _endTime = TimeOfDay(hour: data['endHour'] as int, minute: (data['endMinute'] ?? 0) as int);
        }
        _paymentType = data['paymentType'] ?? 'hourly';
        _hourlyRate = (data['hourlyRate'] ?? 0.0).toDouble();
        _paidTime = (data['paidTime'] ?? 0.0).toDouble();
        _bonus = (data['bonus'] ?? 0.0).toDouble();
        _expenses = (data['expenses'] ?? 0.0).toDouble();
        _shiftRate = (data['shiftRate'] ?? 0.0).toDouble();
        _selectedColor = Color(data['color'] ?? 0xFF8b7ff5);
        
        final iconValue = data['icon'];
        if (iconValue is int) {
          // Иконка хранится как codePoint — подбираем из списка пикера
          _selectedIcon = _icons.firstWhere(
            (i) => i.codePoint == iconValue,
            orElse: () => Icons.work_outline,
          );
        } else if (iconValue is String) {
          _selectedIcon = AppIcons.fromKey(iconValue);
        } else {
          _selectedIcon = null;
        }
        
        _emojiController.text = data['emoji'] ?? '';
        _noteController.text = data['note'] ?? '';
      });
      
      _showSnackbar('✅ Шаблон "${selectedTemplate.name}" загружен', isSuccess: true);
    }
  }

  Future<TemplateModel?> _showTemplatePickerDialog(List<TemplateModel> templates) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    
    return await showDialog<TemplateModel>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Выбрать шаблон',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1e293b),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(
                  template.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
                onTap: () => Navigator.pop(context, template),
              );
            },
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
        ],
      ),
    );
  }    
}