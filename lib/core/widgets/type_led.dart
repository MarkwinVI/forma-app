import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'polished.dart';

/// The type-led vocabulary shared by the screens that have left cards behind:
/// mono section labels, big names with one calm line each, hairline dividers
/// instead of boxes, and compact label/value rows for anything that is a
/// setting rather than content.
///
/// The rule the shapes encode: content gets the big-name treatment, settings
/// get the value pair. Nothing gets a tile.
TextStyle monoStyle({
  double size = 11,
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.textMuted,
  double letterSpacing = 1.65,
}) {
  return GoogleFonts.robotoMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

/// Mono, uppercase section eyebrow, with an optional mono note on the right.
class TypeSectionLabel extends StatelessWidget {
  final String label;
  final String? right;

  /// Space above the label. The first label under a title usually wants less.
  final double top;

  const TypeSectionLabel(this.label, {super.key, this.right, this.top = 34});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label.toUpperCase(), style: monoStyle())),
          if (right != null)
            Text(
              right!.toUpperCase(),
              style: monoStyle(letterSpacing: 1.3),
            ),
        ],
      ),
    );
  }
}

/// Display title with an optional line under it.
class TypeTitle extends StatelessWidget {
  final String title;
  final String? sub;
  final double size;

  const TypeTitle(this.title, {super.key, this.sub, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: size * -0.03,
            height: 1.06,
          ),
        ),
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              sub!,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }
}

/// Content row: a big name, one line beneath, an optional right-hand value
/// with a mono caption under it, and a hairline unless it is the last one.
class TypeContentRow extends StatelessWidget {
  final String name;
  final String? sub;
  final Color? subColor;
  final String? right;
  final String? rightSub;
  final bool chevron;
  final bool last;

  /// Rows that are present but not active — a rest day, an exercise still
  /// ahead of you — step back rather than disappearing.
  final bool dim;
  final double nameSize;

  /// Replaces the name/sub column outright when a row needs a richer body.
  final Widget? child;
  final VoidCallback? onTap;

  const TypeContentRow({
    super.key,
    this.name = '',
    this.sub,
    this.subColor,
    this.right,
    this.rightSub,
    this.chevron = true,
    this.last = false,
    this.dim = false,
    this.nameSize = 21,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 19, bottom: 20),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: child ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight:
                              dim ? FontWeight.w600 : FontWeight.w800,
                          color: dim
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          letterSpacing: nameSize * -0.02,
                          height: 1.15,
                        ),
                      ),
                      if (sub != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            sub!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: subColor ?? AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
            if (right != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    right!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (rightSub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        rightSub!.toUpperCase(),
                        style: monoStyle(size: 11.5, letterSpacing: 0.6),
                      ),
                    ),
                ],
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Setting row: a value pair, deliberately quieter and tighter than content.
class TypeSettingRow extends StatelessWidget {
  final String name;
  final String value;
  final Color? valueColor;
  final bool chevron;
  final bool last;
  final VoidCallback? onTap;

  const TypeSettingRow({
    super.key,
    required this.name,
    this.value = '',
    this.valueColor,
    this.chevron = true,
    this.last = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.16,
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A number said plainly, with a mono caption under it.
class TypeStat extends StatelessWidget {
  final String value;
  final String caption;

  const TypeStat({super.key, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.96,
            height: 1,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          caption.toUpperCase(),
          maxLines: 2,
          style: monoStyle(size: 10.5, letterSpacing: 1.35),
        ),
      ],
    );
  }
}

/// The stats band: two or three numbers side by side under a hairline.
class TypeStatBand extends StatelessWidget {
  final List<TypeStat> stats;

  const TypeStatBand({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.only(top: 26),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            Expanded(child: stats[i]),
          ],
        ],
      ),
    );
  }
}
