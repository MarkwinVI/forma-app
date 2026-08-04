import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/type_led.dart';
import '../train_day_view.dart';

/// The mono line that names a day and how far off it is.
class DayEyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const DayEyebrow({
    super.key,
    required this.text,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(text, style: monoStyle(size: 10.5, letterSpacing: 1.6, color: color)),
    );
  }
}

/// One hairline band above the session saying what is true about this day —
/// the same shape as the UPDATED line, so the two never compete for a slot.
class DayNoteBand extends StatelessWidget {
  final TrainDayNote note;
  final Color tagColor;

  const DayNoteBand({
    super.key,
    required this.note,
    this.tagColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.only(top: 11, bottom: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.tag,
            style: monoStyle(size: 10, letterSpacing: 1.4, color: tagColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note.body,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a day trains, when which exercises it trains is not decided yet: the
/// movement, and how many slots it gets.
class DayPatternRow {
  final String movement;
  final String slots;

  const DayPatternRow({required this.movement, required this.slots});
}

class DayPatternList extends StatelessWidget {
  final List<DayPatternRow> rows;

  const DayPatternList({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              border: index == rows.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    rows[index].movement,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.36,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  rows[index].slots,
                  style: monoStyle(size: 13, letterSpacing: 0),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The exercises of a day with no numbers beside them — a missed day has no
/// history to show, and a distant one has no targets worth quoting.
class DayNameList extends StatelessWidget {
  final List<String> names;

  const DayNameList({super.key, required this.names});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < names.length; index++)
            Container(
              padding: const EdgeInsets.only(top: 15, bottom: 16),
              decoration: BoxDecoration(
                border: index == names.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
              ),
              child: Text(
                names[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.36,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The actions under a day that is not today: a quiet primary and a way back.
class DayActions extends StatelessWidget {
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const DayActions({
    super.key,
    this.primaryLabel,
    this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primaryLabel != null)
          _QuietButton(label: primaryLabel!, onTap: onPrimary),
        _TextAction(
          label: secondaryLabel,
          onTap: onSecondary,
          topPadding: primaryLabel == null ? 0 : 14,
        ),
      ],
    );
  }
}

/// A bordered action rather than a filled one: starting a day early, or
/// reopening a day that is already done, is not the screen's main verb.
class _QuietButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuietButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.17,
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double topPadding;

  const _TextAction({
    required this.label,
    required this.onTap,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(top: topPadding, bottom: 2),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPrimary,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}
