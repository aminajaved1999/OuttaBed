import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          if (blobs) const _DecorativeBlobs(),
          child,
        ],
      ),
    );
  }
}

class _DecorativeBlobs extends StatelessWidget {
  const _DecorativeBlobs();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -40,
          right: -30,
          child: _Blob(size: 160, color: Color(0x33FF8FAB)),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: _Blob(size: 120, color: Color(0x33B8A9E8)),
        ),
        Positioned(
          bottom: 80,
          right: -20,
          child: _Blob(size: 100, color: Color(0x33FFD6A5)),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? AppColors.white.withValues(alpha: 0.92) : null,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: card,
      ),
    );
  }
}

class CuteToggle extends StatelessWidget {
  const CuteToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? AppGradients.cardAccent
              : LinearGradient(
                  colors: [
                    AppColors.plumSoft.withValues(alpha: 0.2),
                    AppColors.plumSoft.withValues(alpha: 0.15),
                  ],
                ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
    final effectiveGradient = gradient ?? AppGradients.fab;

    if (filled) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.white, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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
        foregroundColor: light ? AppColors.white : AppColors.plum,
        side: BorderSide(
          color: light
              ? AppColors.white.withValues(alpha: 0.6)
              : AppColors.violet.withValues(alpha: 0.5),
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.cardAccent : null,
          color: selected ? null : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.blush,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.coral.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: selected ? AppColors.white : AppColors.plumSoft,
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
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.plum,
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: selected ? AppGradients.cardAccent : null,
        color: selected ? null : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.transparent : AppColors.blush,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : AppColors.plum,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle_rounded, color: AppColors.white),
            ),
          if (onPreview != null)
            _PreviewButton(
              isPlaying: isPlaying,
              selected: selected,
              onPressed: onPreview!,
            ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.isPlaying,
    required this.selected,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.white.withValues(alpha: 0.25)
                : AppColors.lavender.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: selected ? AppColors.white : AppColors.plum,
            size: 24,
          ),
        ),
      ),
    );
  }
}
