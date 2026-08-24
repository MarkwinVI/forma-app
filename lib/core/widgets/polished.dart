import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format/dates.dart';
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

/// "Wednesday, Jul 16" — the eyebrow date used by the tab screen headers,
/// in the device's language.
String formatHeaderDate(BuildContext context, DateTime now) =>
    '${FormaDates.weekdayLong(context, now)}, ${FormaDates.monthDay(context, now)}';

/// Scale-down press feedback used across the polished screens.
///
/// Every tappable thing in the app is built on this, so it is also where the
/// button trait lives: the child's own text becomes the accessible name, or
/// [semanticLabel] replaces it outright (icon-only buttons must pass one).
/// A Pressable with no [onTap] and no [semanticLabel] is plain content and
/// exposes nothing extra; with a label it reads as a disabled button.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Accessible name. When set, the child's own semantics are replaced by it.
  final String? semanticLabel;

  /// A live reading next to the name — the elapsed time on a pause button.
  final String? semanticValue;

  /// For tabs and segmented options: whether this one is the active choice.
  final bool? selected;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticValue,
    this.selected,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    if (!enabled && widget.semanticLabel == null && widget.selected == null) {
      return widget.child;
    }

    Widget body = widget.child;
    if (enabled) {
      body = GestureDetector(
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

    // One node per control: the child's text (or the explicit label) plus
    // the button trait, instead of a bare tap region beside a stray label.
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: widget.selected,
        label: widget.semanticLabel,
        value: widget.semanticValue,
        // The tap action is declared here, not left to the GestureDetector:
        // an explicit label excludes the child's semantics, action included.
        onTap: widget.onTap,
        excludeSemantics: widget.semanticLabel != null,
        child: body,
      ),
    );
  }
}

/// A quiet text action — the secondary verb under a primary button, or the
/// one thing a small state asks of you. 15pt accent, an optional leading
/// icon, and a 44pt tall hit area however short the line is.
class TextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const TextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.accentPrimary),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPrimary,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ],
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

/// The app's one confirm sheet: a question, a line of context, a filled
/// button and a quiet text button under it. Pops `true` when the confirming
/// answer is chosen and `false` for the other, whichever of the two is the
/// filled one — a destructive confirm (delete, sign out) is filled with the
/// safe way out in text below it; a "keep editing" keeps the safe answer
/// filled and the loss in red text.
class ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;

  /// The filled button.
  final String primaryLabel;
  final bool primaryConfirms;
  final Color primaryColor;
  final Color primaryForeground;

  /// The text-only button under it. Pops the opposite of the primary.
  final String secondaryLabel;
  final Color secondaryColor;

  /// Spoken name for the secondary when its visible word is too short on its
  /// own ("Discard" → "Discard changes").
  final String? secondarySemanticLabel;

  const ConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.primaryConfirms = true,
    this.primaryColor = AppColors.accentPrimary,
    this.primaryForeground = Colors.white,
    this.secondaryColor = AppColors.textSecondary,
    this.secondarySemanticLabel,
  });

  /// Shows the sheet over the root navigator and resolves to the answer, or
  /// null when dismissed by the scrim.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryLabel,
    required String secondaryLabel,
    bool primaryConfirms = true,
    Color primaryColor = AppColors.accentPrimary,
    Color primaryForeground = Colors.white,
    Color secondaryColor = AppColors.textSecondary,
    String? secondarySemanticLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmSheet(
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        primaryConfirms: primaryConfirms,
        primaryColor: primaryColor,
        primaryForeground: primaryForeground,
        secondaryColor: secondaryColor,
        secondarySemanticLabel: secondarySemanticLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Pressable(
                semanticLabel: primaryLabel,
                onTap: () => Navigator.of(context).pop(primaryConfirms),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    primaryLabel,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: primaryForeground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Pressable(
                semanticLabel: secondarySemanticLabel ?? secondaryLabel,
                onTap: () => Navigator.of(context).pop(!primaryConfirms),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(
                    secondaryLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  /// Accessible name when the visible label is too terse on its own
  /// ("Retry" → "Retry loading history"). Defaults to [label].
  final String? semanticLabel;

  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon = false,
    this.tonal = false,
    this.color,
    this.radius = 26,
    this.semanticLabel,
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
      // Named explicitly so a disabled button still reads as one.
      semanticLabel: semanticLabel ?? label,
      child: Container(
        // A floor, not a fixed height: at a large text size the label
        // grows the button instead of clipping against it.
        constraints: const BoxConstraints(minHeight: 52),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                selected: i == selectedIndex,
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
      // The back target is 44pt; its drawn circle stays 36 and sits where it
      // always did, so the outer padding gives up the 4pt the target grew by.
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            semanticLabel: 'Back',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
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
            ),
          ),
          const SizedBox(width: 8),
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

/// 38px circular header button (bell / gear) inside a 44pt hit target.
///
/// Icon-only, so it needs a [semanticLabel] — "Settings", "Notifications".
class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
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
        ),
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
            // The circle buttons carry 3pt of hit area on every side now, so
            // the gap between them shrinks by that much to read the same.
            if (i > 0) const SizedBox(width: 4),
            actions[i],
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
            // The close target is 44pt (its circle stays 32), so the row
            // grew by 12: the bottom padding gives 6 of it back and the
            // right padding the 6 the circle moved inward.
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
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
                        semanticLabel: 'Close',
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
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
