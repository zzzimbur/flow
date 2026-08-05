import 'package:flutter/material.dart';

/// Палитра Coinka — тёмная неоновая тема.
class Coinka {
  // ── Dark palette ──────────────────────────────────────────────────────────
  static const bg     = Color(0xFF090910);
  static const s1     = Color(0xFF0F0F18);
  static const s2     = Color(0xFF141422);
  static const card   = Color(0xFF16162A);
  static const border = Color(0x0FFFFFFF);
  static const text   = Color(0xFFEAEAF0);
  static const hint   = Color(0xFF7070A0);
  static const muted  = Color(0xFF4A4A6A);

  // ── Shared colors ─────────────────────────────────────────────────────────
  static const accent    = Color(0xFF00E5B3);
  static const accentDim = Color(0x1F00E5B3);
  static const accent2   = Color(0xFF7B6FF0);
  static const red       = Color(0xFFFF4D6D);
  static const green     = Color(0xFF00E5B3);

  /// Эмодзи для категорий операций.
  static const categoryEmoji = <String, String>{
    'Продукты': '🛒',
    'Транспорт': '🚗',
    'Развлечения': '🎬',
    'Здоровье': '💊',
    'Образование': '📚',
    'Кафе': '🍔',
    'Одежда': '👕',
    'Дом': '🏠',
    'Зарплата': '💰',
    'Фриланс': '💻',
    'Подработка': '🔧',
    'Инвестиции': '📈',
    'Подарок': '🎁',
    'Другое': '💸',
  };

  static String emojiFor(String category, {bool isIncome = false}) =>
      categoryEmoji[category] ?? (isIncome ? '💵' : '💸');
}

/// Светлая палитра Coinka.
class CoinkaL {
  static const bg     = Color(0xFFF2F2F7);
  static const s1     = Color(0xFFE8E8F0);
  static const s2     = Color(0xFFEAEAF0);
  static const card   = Color(0xFFFFFFFF);
  static const border = Color(0x18000000);
  static const text   = Color(0xFF0F0F1E);
  static const hint   = Color(0xFF6B6B90);
  static const muted  = Color(0xFFBBBBCC);
}

/// Получить правильный набор цветов по контексту.
extension CoinkaTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get ckBg     => _isDark ? Coinka.bg     : CoinkaL.bg;
  Color get ckS1     => _isDark ? Coinka.s1     : CoinkaL.s1;
  Color get ckS2     => _isDark ? Coinka.s2     : CoinkaL.s2;
  Color get ckCard   => _isDark ? Coinka.card   : CoinkaL.card;
  Color get ckBorder => _isDark ? Coinka.border : CoinkaL.border;
  Color get ckText   => _isDark ? Coinka.text   : CoinkaL.text;
  Color get ckHint   => _isDark ? Coinka.hint   : CoinkaL.hint;
  Color get ckMuted  => _isDark ? Coinka.muted  : CoinkaL.muted;
  bool  get isDark   => _isDark;
}

/// Hero-карта с градиентом и неоновыми орбами (баланс, заработок за месяц).
class CoinkaHero extends StatelessWidget {
  final String label;
  final String value;
  final List<CoinkaHeroStat> stats;

  const CoinkaHero({
    super.key,
    required this.label,
    required this.value,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12122A), Color(0xFF1A1A3A), Color(0xFF0F1A2A)],
        ),
        border: Border.all(color: const Color(0x407B6FF0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Орб справа сверху
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2600E5B3), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Орб слева снизу
            Positioned(
              bottom: -30,
              left: -10,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x1F7B6FF0), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Coinka.hint,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Colors.white, Coinka.accent],
                    ).createShader(rect),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (int i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 20),
                        stats[i],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinkaHeroStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const CoinkaHeroStat({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? Coinka.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Coinka.hint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Заголовок секции — мелкий капс как в Coinka.
class CoinkaSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Color? textColor;

  const CoinkaSectionHeader(this.title, {super.key, this.trailing, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor ?? context.ckHint,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Градиентная кнопка добавления (фиолет → циан).
class CoinkaAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const CoinkaAddButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Coinka.accent2, Coinka.accent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Шапка экрана: заголовок слева + опциональная месячная навигация ‹ месяц ›.
class CoinkaHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const CoinkaHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.ckBg,
        border: Border(bottom: BorderSide(color: context.ckBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: context.ckText,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Навигация по месяцам ‹ Июнь › для шапки.
class CoinkaMonthNav extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const CoinkaMonthNav({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  Widget _arrow(BuildContext context, String char, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          char,
          style: TextStyle(fontSize: 22, color: context.ckHint, height: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(context, '‹', onPrev),
        SizedBox(
          width: 86,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.ckText,
            ),
          ),
        ),
        _arrow(context, '›', onNext),
      ],
    );
  }
}

/// Пустое состояние с эмодзи.
class CoinkaEmpty extends StatelessWidget {
  final String emoji;
  final String text;

  const CoinkaEmpty({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.ckHint,
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Месяцы по-русски для навигации.
const coinkaMonths = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];
