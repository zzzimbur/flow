import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_glass_card.dart';
import '../widgets/ios_time_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/shift_model.dart';

class EditShiftScreen extends StatefulWidget {
  final ShiftModel shift;
  
  const EditShiftScreen({super.key, required this.shift});

  @override
  State<EditShiftScreen> createState() => _EditShiftScreenState();
}

class _EditShiftScreenState extends State<EditShiftScreen> {
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _noteController;
  final _emojiController = TextEditingController();
  
  late bool _isAllDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  late String _paymentType;
  late double _hourlyRate;
  late double _paidTime;
  late double _bonus;
  late double _expenses;
  late double _shiftRate;

  late Color _selectedColor;
  late IconData? _selectedIcon = Icons.work_outline;
  bool _isSaving = false;
  
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

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.shift.name);
    _categoryController = TextEditingController(text: widget.shift.category);
    _noteController = TextEditingController(text: widget.shift.note ?? '');
    
    _isAllDay = widget.shift.isAllDay;
    _startTime = TimeOfDay(hour: widget.shift.startTime.hour, minute: widget.shift.startTime.minute);
    _endTime = TimeOfDay(hour: widget.shift.endTime.hour, minute: widget.shift.endTime.minute);
    
    _paymentType = widget.shift.paymentType;
    _hourlyRate = widget.shift.hourlyRate;
    _paidTime = widget.shift.paidTime;
    _bonus = widget.shift.bonus;
    _expenses = widget.shift.expenses;
    _shiftRate = widget.shift.shiftRate;

    _selectedColor = widget.shift.color;
    _selectedIcon = widget.shift.icon;
  }

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
                      icon: Icon(Icons.close, color: isDark ? Colors.white : const Color(0xFF1e293b)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Редактировать смену',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                      _buildTextField(
                        'Название',
                        _nameController,
                        isDark,
                        hint: 'Например: Дневная смена',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Категория',
                        _categoryController,
                        isDark,
                        hint: 'Например: Офис',
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
                                    Icon(
                                      Icons.schedule_rounded,
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
                                    Text(
                                      '${calculatedHours.toStringAsFixed(1)} ч',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF8b7ff5),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
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
                                    Icon(
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
                                    Text(
                                      '24.0 ч',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF8b7ff5),
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
                      // Кнопка удаления
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showDeleteConfirmation();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFef4444).withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFef4444).withOpacity(0.15),
                                      const Color(0xFFdc2626).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFef4444).withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFef4444).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFef4444),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Удалить смену',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFef4444),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Future<void> _showDeleteConfirmation() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = settings.isDarkMode;
    
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Иконка
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFef4444).withOpacity(0.2),
                              const Color(0xFFdc2626).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFef4444),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Заголовок
                      Text(
                        'Удалить смену?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Описание
                      Text(
                        'Это действие нельзя отменить',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark 
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Кнопки
                      Row(
                        children: [
                          // Отмена
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'Отмена',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Удалить
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context, true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFef4444),
                                      Color(0xFFdc2626),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFef4444).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Удалить',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    if (result == true) {
      await _deleteShift();
    }
  }

  Future<void> _deleteShift() async {
    HapticFeedback.heavyImpact();
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .doc(widget.shift.id)
          .delete();
      
      if (mounted) {
        _showSnackbar('✅ Смена удалена', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Ошибка удаления: $e');
      if (mounted) {
        _showSnackbar('Ошибка удаления', isError: true);
      }
    }
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
                      Icon(
                        Icons.payments_rounded,
                        color: const Color(0xFF10b981),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10b981),
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
          controller: TextEditingController(text: value > 0 ? value.toString() : ''),
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

      // Создаём DateTime для начала смены
      final startDateTime = DateTime(
        widget.shift.date.year,
        widget.shift.date.month,
        widget.shift.date.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      // ИСПРАВЛЕНИЕ: Если конец раньше начала, значит смена через полночь
      var endDateTime = DateTime(
        widget.shift.date.year,
        widget.shift.date.month,
        widget.shift.date.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      // Если время окончания меньше или равно времени начала - переносим на следующий день
      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      final shiftData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'isAllDay': _isAllDay,
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'paymentType': _paymentType,
        'hourlyRate': _hourlyRate,
        'paidTime': _paidTime,
        'bonus': _bonus,
        'expenses': _expenses,
        'shiftRate': _shiftRate,
        'color': _selectedColor.value,
        'icon': _selectedIcon?.codePoint,
        'emoji': _emojiController.text.trim().isEmpty ? null : _emojiController.text.trim(),
        'note': _noteController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('shifts')
          .doc(widget.shift.id)
          .update(shiftData);

      HapticFeedback.heavyImpact();
      
      if (mounted) {
        _showSnackbar('✅ Смена обновлена!', isSuccess: true);
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
}