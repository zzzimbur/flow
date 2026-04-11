import 'package:flutter/material.dart';
import 'dart:ui';

// ---------------------------------------------------------------------------
// Private helper: a single floating orb rendered as a circle with a radial
// gradient that fades to transparent at its edge.
// ---------------------------------------------------------------------------
class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedBackground – floating orb blobs instead of a plain gradient sweep.
// ---------------------------------------------------------------------------
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const AnimatedBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl1;
  late final AnimationController _ctrl2;
  late final AnimationController _ctrl3;

  @override
  void initState() {
    super.initState();

    _ctrl1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _ctrl2 = AnimationController(
      duration: const Duration(seconds: 13),
      vsync: this,
    )
      ..value = 0.4
      ..repeat(reverse: true);

    _ctrl3 = AnimationController(
      duration: const Duration(seconds: 17),
      vsync: this,
    )
      ..value = 0.7
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFF060612)
        : const Color(0xFFf9f9fb);

    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl1, _ctrl2, _ctrl3]),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Orb 1
            final orb1Color = widget.isDark
                ? const Color(0xFF5b21b6).withOpacity(0.45)
                : const Color(0xFFa78bfa).withOpacity(0.45);
            final orb1x =
                lerpDouble(-130, w * 0.2, _ctrl1.value)! - 200;
            final orb1y =
                lerpDouble(-130, h * 0.22, _ctrl1.value)! - 200;

            // Orb 2
            final orb2Color = widget.isDark
                ? const Color(0xFF0369a1).withOpacity(0.30)
                : const Color(0xFF7dd3fc).withOpacity(0.40);
            final orb2x =
                lerpDouble(w + 100, w * 0.4, _ctrl2.value)! - 170;
            final orb2y =
                lerpDouble(h * 0.3, h * 0.5, _ctrl2.value)! - 170;

            // Orb 3
            final orb3Color = widget.isDark
                ? const Color(0xFF9d174d).withOpacity(0.20)
                : const Color(0xFFfda4af).withOpacity(0.30);
            final orb3x =
                lerpDouble(w * 0.1, w * 0.55, _ctrl3.value)! - 145;
            final orb3y =
                lerpDouble(h * 0.7, h * 0.55, _ctrl3.value)! - 145;

            return Container(
              color: baseColor,
              child: Stack(
                children: [
                  Positioned(
                    left: orb1x,
                    top: orb1y,
                    child: _Orb(size: 400, color: orb1Color),
                  ),
                  Positioned(
                    left: orb2x,
                    top: orb2y,
                    child: _Orb(size: 340, color: orb2Color),
                  ),
                  Positioned(
                    left: orb3x,
                    top: orb3y,
                    child: _Orb(size: 290, color: orb3Color),
                  ),
                  if (child != null) child,
                ],
              ),
            );
          },
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// EnhancedGlassCard
// ---------------------------------------------------------------------------
class EnhancedGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final double borderRadius;
  final bool enableHover;
  final bool enableShadow;
  final VoidCallback? onTap;
  // Kept for API compatibility; not used in decoration.
  final Gradient? gradient;

  const EnhancedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderRadius = 20,
    this.enableHover = true,
    this.enableShadow = true,
    this.onTap,
    this.gradient,
  });

  @override
  State<EnhancedGlassCard> createState() => _EnhancedGlassCardState();
}

class _EnhancedGlassCardState extends State<EnhancedGlassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel:
          widget.onTap != null ? () => _controller.reverse() : null,
      child: MouseRegion(
        onEnter: widget.enableHover
            ? (_) => setState(() => _isHovered = true)
            : null,
        onExit: widget.enableHover
            ? (_) => setState(() => _isHovered = false)
            : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius),
                  boxShadow: widget.enableShadow
                      ? [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius:
                                20 + (_glowAnimation.value * 10),
                            offset: Offset(
                                0, 8 + (_glowAnimation.value * 4)),
                            spreadRadius: _isHovered ? 2 : 0,
                          ),
                          if (_isHovered && widget.enableHover)
                            BoxShadow(
                              color: const Color(0xFF8b7ff5)
                                  .withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                              spreadRadius: 5,
                            ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 35 + (_glowAnimation.value * 10),
                      sigmaY: 35 + (_glowAnimation.value * 10),
                    ),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: widget.color ??
                            (isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.75)),
                        borderRadius: BorderRadius.circular(
                            widget.borderRadius),
                        border: Border.all(
                          width: 1.5,
                          color: isDark
                              ? Colors.white.withOpacity(
                                  0.2 + (_glowAnimation.value * 0.1))
                              : Colors.white.withOpacity(
                                  0.4 + (_glowAnimation.value * 0.2)),
                        ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GlassButton
// ---------------------------------------------------------------------------
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? const Color(0xFF8b7ff5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              if (!widget.isLoading) widget.onPressed();
            },
            onTapCancel: () => _controller.reverse(),
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              padding: widget.isFullWidth
                  ? const EdgeInsets.symmetric(vertical: 18)
                  : const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: widget.isFullWidth
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SectionHeader
// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8b7ff5).withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8b7ff5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF1e293b),
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
