import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared building blocks for the polished design language:
/// tonal cards instead of 1px-bordered boxes, one radius token,
/// sentence-case section titles, real press states, pill CTAs.

const double kCardRadius = 20;

/// Scale-down press feedback used across the polished screens.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.977 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.82 : 1,
          duration: const Duration(milliseconds: 160),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tonal card — soft drop shadow, no border.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool clip;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            offset: Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Pressable(onTap: onTap, child: card);
  }
}

/// Sentence-case section title with optional subtitle and trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.sub,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 28, 2, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (action != null)
                Pressable(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                sub!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded icon tile used by list rows.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool tint;
  final bool warn;

  const IconTile({
    super.key,
    required this.icon,
    this.size = 40,
    this.tint = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = warn
        ? AppColors.amberSoft
        : tint
            ? AppColors.accentSoft
            : AppColors.surface2;
    final color = warn
        ? AppColors.amber
        : tint
            ? AppColors.accentPrimary
            : AppColors.textSecondary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.54, color: color),
    );
  }
}

/// Full-width pill CTA (52px tall, accent background).
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool trailingIcon;
  final bool tonal;

  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon = false,
    this.tonal = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final background = disabled
        ? AppColors.surface2
        : tonal
            ? AppColors.surface2
            : AppColors.accentPrimary;
    final foreground = disabled
        ? AppColors.textMuted
        : tonal
            ? AppColors.textPrimary
            : Colors.white;

    final iconWidget =
        icon == null ? null : Icon(icon, size: 18, color: foreground);

    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null && !trailingIcon) ...[
              iconWidget,
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foreground,
                letterSpacing: -0.2,
              ),
            ),
            if (iconWidget != null && trailingIcon) ...[
              const SizedBox(width: 7),
              iconWidget,
            ],
          ],
        ),
      ),
    );
  }
}

/// 38px circular header button (bell / gear).
class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Large screen title ("Today", "Welcome") with trailing header buttons.
class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.96,
                height: 1.05,
              ),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: actions[i],
            ),
          ],
        ],
      ),
    );
  }
}
