import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../providers/settings_provider.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({super.key});

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Длительность
  bool _isAllDay = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  
  // Тип оплаты
  String _paymentType = 'hourly'; // hourly, perShift, unpaid
  double _hourlyRate = 0.0;
  double _paidTime = 0.0;
  double _bonus = 0.0;
  double _expenses = 0.0;
  double _shiftRate = 0.0;
  
  // Визуал
  bool _isFilled = false;
  Color _selectedColor = const Color(0xFF8b7ff5);
  IconData _selectedIcon = Icons.work_outline;
  
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
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0f172a), const Color(0xFF1e293b)]
                : [const Color(0xFFf8fafc), const Color(0xFFe2e8f0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Хедер
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Новая смена',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                    const Spacer(),
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
              
              // Контент
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название и категория
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
                      
                      // Длительность
                      _buildSectionTitle('Длительность', isDark),
                      const SizedBox(height: 12),
                      GlassCard(
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
                                    setState(() {
                                      _isAllDay = value;
                                    });
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
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Тип оплаты
                      _buildSectionTitle('Тип оплаты', isDark),
                      const SizedBox(height: 12),
                      _buildPaymentTypeSelector(isDark),
                      const SizedBox(height: 16),
                      _buildPaymentFields(isDark),
                      const SizedBox(height: 24),
                      
                      // Визуал
                      _buildSectionTitle('Оформление', isDark),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        color: isDark 
                            ? const Color(0xFF1e293b).withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Закрасить',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF1e293b),
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: _isFilled,
                                  activeColor: const Color(0xFF8b7ff5),
                                  onChanged: (value) {
                                    setState(() {
                                      _isFilled = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                  onTap: () => setState(() => _selectedColor = color),
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _icons.map((icon) {
                                final isSelected = icon == _selectedIcon;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedIcon = icon),
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
                      
                      // Заметка
                      _buildSectionTitle('Заметка', isDark),
                      const SizedBox(height: 12),
                      _buildTextField(
                        '',
                        _noteController,
                        isDark,
                        hint: 'Добавьте заметку...',
                        maxLines: 4,
                      ),
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
    return GlassCard(
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
        onTap: () => setState(() => _paymentType = value),
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: isDark 
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Column(
        children: [
          if (_paymentType == 'hourly') ...[
            _buildNumberField('Почасовая ставка', _hourlyRate, isDark, (val) => setState(() => _hourlyRate = val)),
            const SizedBox(height: 12),
            _buildNumberField('Оплачиваемое время (часы)', _paidTime, isDark, (val) => setState(() => _paidTime = val)),
          ] else ...[
            _buildNumberField('Ставка за смену', _shiftRate, isDark, (val) => setState(() => _shiftRate = val)),
          ],
          const SizedBox(height: 12),
          _buildNumberField('Доплата', _bonus, isDark, (val) => setState(() => _bonus = val)),
          const SizedBox(height: 12),
          _buildNumberField('Расходы', _expenses, isDark, (val) => setState(() => _expenses = val)),
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
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: isDark ? const Color(0xFF1e293b) : Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
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
              time.format(context),
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

  void _saveShift() {
    // TODO: Сохранить смену в Firebase
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}