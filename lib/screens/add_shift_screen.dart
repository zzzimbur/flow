import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../widgets/enhanced_glass_card.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/template_service.dart';
import '../models/template_model.dart';
import '../providers/subscription_provider.dart';
import '../widgets/app_icons.dart';

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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
    body: AnimatedBackground(
      isDark: isDark,
      child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Новая смена',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                    ),
                    // кнопка шаблона
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_add_outlined,
                        color: Color(0xFF8b7ff5),
                      ),
                      onPressed: _saveAsTemplate,
                      tooltip: 'Сохранить как шаблон',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_outlined,
                        color: Color(0xFF8b7ff5),
                      ),
                      onPressed: _loadFromTemplate,
                      tooltip: 'Загрузить из шаблона',
                    ),
                    const SizedBox(width: 8),
                    if (_isSaving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b7ff5)),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _saveShift,
                        child: const Text(
                          'Готово',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8b7ff5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Название',
                              _nameController,
                              isDark,
                              hint: 'Например: Дневная смена',
                            ),
                          ),
                          if (_speechAvail) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleVoice,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
                                      ? const Color(0xFFff4d6d)
                                      : const Color(0xFF00e5b3).withOpacity(0.15),
                                ),
                                child: Icon(
                                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                                  color: _isListening ? Colors.white : const Color(0xFF00e5b3),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Категория',
                        _categoryController,
                        isDark,
                        hint: 'Например: Офис',
                      ),
                      const SizedBox(height: 24),
                      // Дата
                      _buildSectionTitle('Дата', isDark),
                      const SizedBox(height: 12),
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: InkWell(
                          onTap: () => _selectDate(isDark),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Дата смены',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: isDark ? const Color(0xFF8b7ff5) : const Color(0xFF64748b),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Длительность', isDark),
                      const SizedBox(height: 12),
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark 
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Весь день',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: _isAllDay,
                                  activeColor: const Color(0xFF8b7ff5),
                                  onChanged: (value) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _isAllDay = value);
                                  },
                                ),
                              ],
                            ),
                            if (!_isAllDay) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimePicker(
                                      'Начало',
                                      _startTime,
                                      isDark,
                                      (time) => setState(() => _startTime = time),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTimePicker(
                                      'Конец',
                                      _endTime,
                                      isDark,
                                      (time) => setState(() => _endTime = time),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // НОВОЕ: Отображение подсчитанных часов
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF8b7ff5).withOpacity(0.15),
                                      const Color(0xFF6c5ce7).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF8b7ff5).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      color: Color(0xFF8b7ff5),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Длительность: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                      ),
                                    ),
                                    Text(
                                      '${calculatedHours.toStringAsFixed(1)} ч',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF8b7ff5),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              // Отображение для "Весь день"
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF8b7ff5).withOpacity(0.15),
                                      const Color(0xFF6c5ce7).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF8b7ff5).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.wb_sunny_rounded,
                                      color: const Color(0xFF8b7ff5),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Длительность: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                                      ),
                                    ),
                                    const Text(
                                      '24.0 ч',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF8b7ff5),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Тип оплаты', isDark),
                      const SizedBox(height: 12),
                      _buildPaymentTypeSelector(isDark),
                      const SizedBox(height: 16),
                      _buildPaymentFields(isDark),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Оформление', isDark),
                      const SizedBox(height: 12),
                      EnhancedGlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark 
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Цвет',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: _colors.map((color) {
                                final isSelected = color == _selectedColor;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedColor = color);
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: isDark ? Colors.white : const Color(0xFF1e293b),
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Иконка',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Разделитель
                            Container(
                              height: 1,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
                            ),
                            const SizedBox(height: 16),

                            // Эмодзи
                            Text(
                              'Или используй эмодзи',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Поле для эмодзи
                            TextField(
                              controller: _emojiController,
                              maxLength: 2,
                              style: TextStyle(
                                fontSize: 32,
                                color: isDark ? Colors.white : const Color(0xFF1e293b),
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '😊',
                                hintStyle: TextStyle(
                                  fontSize: 32,
                                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                counterText: '',
                              ),
                              onChanged: (value) {
                                // Если введён эмодзи, сбрасываем выбранную иконку
                                if (value.isNotEmpty) {
                                  setState(() => _selectedIcon = null);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Нажми на поле и используй клавиатуру эмодзи',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _icons.map((icon) {
                                final isSelected = icon == _selectedIcon;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedIcon = icon);
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _selectedColor
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFf1f5f9)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: isSelected ? Colors.white : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Заметка', isDark),
                      const SizedBox(height: 12),
                      _buildTextField(
                        '',
                        _noteController,
                        isDark,
                        hint: 'Добавьте заметку...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector(bool isDark) {
    return EnhancedGlassCard(
      padding: const EdgeInsets.all(4),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Row(
        children: [
          _buildPaymentTypeChip('Почасовая', 'hourly', isDark),
          _buildPaymentTypeChip('За смену', 'perShift', isDark),
          _buildPaymentTypeChip('Без оплаты', 'unpaid', isDark),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeChip(String label, String value, bool isDark) {
    final isSelected = _paymentType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _paymentType = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8b7ff5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFields(bool isDark) {
    if (_paymentType == 'unpaid') return const SizedBox.shrink();

    return EnhancedGlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Column(
        children: [
          if (_paymentType == 'hourly') ...[
            _buildNumberField('Почасовая ставка', _hourlyRate, isDark, (val) => setState(() => _hourlyRate = val)),
            const SizedBox(height: 12),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Оплачиваемое время',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    // Часы
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1e293b)),
                        controller: TextEditingController(
                          text: _paidTime > 0 
                              ? _paidTime.floor().toString() 
                              : calculatedHours.floor().toString()
                        ),
                        decoration: InputDecoration(
                          labelText: 'Часы',
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          final hours = int.tryParse(val) ?? 0;
                          final minutes = ((_paidTime - _paidTime.floor()) * 60).round();
                          setState(() {
                            _paidTime = hours + (minutes / 60.0);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Минуты
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1e293b)),
                        controller: TextEditingController(
                          text: _paidTime > 0
                              ? ((_paidTime - _paidTime.floor()) * 60).round().toString()
                              : ((calculatedHours - calculatedHours.floor()) * 60).round().toString()
                        ),
                        decoration: InputDecoration(
                          labelText: 'Минуты',
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          final minutes = int.tryParse(val) ?? 0;
                          final hours = _paidTime > 0 ? _paidTime.floor() : calculatedHours.floor();
                          setState(() {
                            _paidTime = hours + (minutes / 60.0);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            _buildNumberField('Ставка за смену', _shiftRate, isDark, (val) => setState(() => _shiftRate = val)),
          ],
          const SizedBox(height: 12),
          _buildNumberField('Доплата', _bonus, isDark, (val) => setState(() => _bonus = val)),
          const SizedBox(height: 12),
          _buildNumberField('Расходы', _expenses, isDark, (val) => setState(() => _expenses = val)),
          
          // НОВОЕ: Отображение итогового заработка
          if (_hourlyRate > 0 || _shiftRate > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10b981).withOpacity(0.15),
                    const Color(0xFF059669).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10b981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF10b981),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Итого заработок:',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${Provider.of<SettingsProvider>(context, listen: false).currencySymbol}${calculatedEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10b981),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, double value, bool isDark, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1e293b)),
          decoration: InputDecoration(
            hintText: '0.00',
            filled: true,
            fillColor: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val) ?? 0.0;
            onChanged((parsed * 100).roundToDouble() / 100);
          },
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isDark, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        
        final picked = await IOSTimePicker.show(
          context: context,
          initialTime: time,
          isDark: isDark,
        );
        
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1e293b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF1e293b),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark, {
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1e293b)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
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
    if (!sub.canUseVoiceInput) { sub.showPremiumDialog(context); return; }
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