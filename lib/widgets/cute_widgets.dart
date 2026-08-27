import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated dark mesh background with drifting neon orbs.
class GradientBackground extends StatefulWidget {
  const GradientBackground({
    super.key,
    required this.gradient,
    required this.child,
    this.blobs = true,
  });

  final Gradient gradient;
  final Widget child;
  final bool blobs;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: widget.gradient),
      child: Stack(
        children: [
          if (widget.blobs)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => CustomPaint(
                painter: _ChaosOrbPainter(progress: _ctrl.value),
                size: Size.infinite,
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _ChaosOrbPainter extends CustomPainter {
  _ChaosOrbPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (AppColors.lime, 0.18, Offset(size.width * 0.8, size.height * 0.12)),
      (AppColors.hotPink, 0.14, Offset(size.width * 0.1, size.height * 0.35)),
      (AppColors.electric, 0.1, Offset(size.width * 0.65, size.height * 0.75)),
    ];
    for (var i = 0; i < orbs.length; i++) {
      final (color, alpha, base) = orbs[i];
      final wobble = math.sin((progress + i * 0.33) * math.pi * 2) * 30;
      final center = base + Offset(wobble, wobble * 0.6);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(center, 90 + i * 20, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChaosOrbPainter old) => old.progress != progress;
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.gradient,
    this.tilt = 0.0,
    this.accent = AppColors.lime,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double tilt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final card = Transform.rotate(
      angle: tilt,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.surface.withValues(alpha: 0.92) : null,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: accent.withValues(alpha: 0.1),
        child: card,
      ),
    );
  }
}

class CuteToggle extends StatelessWidget {
  const CuteToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 58,
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? AppColors.lime : AppColors.stroke,
          border: Border.all(
            color: value ? AppColors.lime : AppColors.muted.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: value
              ? [BoxShadow(color: AppColors.lime.withValues(alpha: 0.35), blurRadius: 12)]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppColors.voidBlack : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.gradient,
    this.light = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;
  final Gradient? gradient;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      final g = gradient ?? AppGradients.fab;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Ink(
            decoration: BoxDecoration(
              gradient: g,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lime.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.voidBlack, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(16, weight: FontWeight.w800)
                          .copyWith(color: AppColors.voidBlack),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: light ? AppColors.white : AppColors.lime,
        side: BorderSide(
          color: light ? AppColors.white.withValues(alpha: 0.5) : AppColors.lime,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: Text(
        label,
        style: AppTheme.display(15, weight: FontWeight.w700),
      ),
    );
  }
}

class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.lime : AppColors.stroke,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.lime.withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: selected ? AppColors.voidBlack : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.emoji});

  final String title;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 20)),
          if (emoji != null) const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTheme.display(14, weight: FontWeight.w800).copyWith(
              color: AppColors.lime,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class SoundOptionCard extends StatelessWidget {
  const SoundOptionCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isPlaying = false,
    this.onPreview,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isPlaying;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AppColors.lime.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? AppColors.lime : AppColors.stroke,
          width: selected ? 2 : 1.5,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.lime.withValues(alpha: 0.15), blurRadius: 16)]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTheme.body(15, weight: FontWeight.w600).copyWith(
                        color: selected ? AppColors.lime : AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected) const Icon(Icons.check_rounded, color: AppColors.lime, size: 20),
          if (onPreview != null) ...[
            const SizedBox(width: 8),
            _PreviewButton(isPlaying: isPlaying, onPressed: onPreview!),
          ],
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.hotPink : AppColors.stroke,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying ? AppColors.hotPink : AppColors.muted.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: AppColors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// Sticker-style badge with slight tilt — chaotic gen-z energy.
class StickerBadge extends StatelessWidget {
  const StickerBadge({
    super.key,
    required this.text,
    this.color = AppColors.hotPink,
    this.tilt = -0.06,
  });

  final String text;
  final Color color;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: Text(
          text,
          style: AppTheme.display(11, weight: FontWeight.w800).copyWith(color: AppColors.voidBlack),
        ),
      ),
    );
  }
}
