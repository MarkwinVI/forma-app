import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared building blocks for the polished design language:
/// tonal cards instead of 1px-bordered boxes, one radius token,
/// sentence-case section titles, real press states, pill CTAs.

const double kCardRadius = 20;

/// Dashed rounded outline around [child] — Flutter has no dashed border, so
/// it is painted by hand. Across the app a dashed edge means "nothing
/// logged here": a session skipped, or one still ahead.
class DashedRoundedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  const DashedRoundedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 9,
    this.dash = 3,
    this.gap = 2.6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: color,
        radius: radius,
        dash: dash,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}

/// "Wednesday, Jul 16" — the eyebrow date used by the tab screen headers.
String formatHeaderDate(DateTime now) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

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

  /// Overrides the accent background (ignored for tonal/disabled buttons).
  final Color? color;

  /// Corner radius — the default is a full pill; the type-led screens square
  /// it off so the button sits with their type rather than floating over it.
  final double radius;

  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon = false,
    this.tonal = false,
    this.color,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final background = disabled
        ? AppColors.surface2
        : tonal
            ? AppColors.surface2
            : color ?? AppColors.accentPrimary;
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
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null && !trailingIcon) ...[
              iconWidget,
              const SizedBox(width: 7),
            ],
            // Flexible so a long label or a large text scale ellipsizes
            // instead of overflowing a narrow button.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  letterSpacing: -0.2,
                ),
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

/// Pill-shaped segmented control — equal-width tabs on a soft track.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.surface2
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: i == selectedIndex
                        ? const [
                            BoxShadow(
                              color: Color(0x4D000000),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sub-screen header — back circle, large title, optional trailing widget.
class SubScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const SubScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.44,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
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

/// Large screen title ("Today", "Welcome") with trailing header buttons and
/// an optional small uppercase eyebrow line (e.g. the current date).
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      eyebrow!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.96,
                    height: 1.05,
                  ),
                ),
              ],
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

/// Slide-up sheet chrome shared by every picker sheet: grabber, title and
/// subtitle, close button, scrolling content and an optional pinned footer.
class SheetShell extends StatelessWidget {
  final String title;

  /// Optional — sheets whose title already says everything omit it.
  final String? sub;
  final Widget child;
  final Widget? footer;
  final bool expand;

  /// Sheets that are a quick pick-one menu drop the close button — the grab
  /// handle and the scrim already offer two ways out.
  final bool showClose;

  const SheetShell({
    super.key,
    required this.title,
    this.sub,
    required this.child,
    this.footer,
    this.expand = false,
    this.showClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height - media.padding.top - 24;

    return Container(
      constraints: BoxConstraints(
        maxHeight: math.min(media.size.height * 0.88, maxHeight),
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: media.padding.bottom + 14),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (sub != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              sub!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showClose)
                      Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (expand) Expanded(child: child) else Flexible(child: child),
          if (footer != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}
