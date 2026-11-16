import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import 'rest_day_view.dart';
import 'today_workout_card.dart';

/// The Train tab's main container: the day of the program being read, as
/// one card. Whatever the day is — a session to start, a rest, a finished
/// workout, a day ahead — it is said inside this card, so the tab keeps one
/// shape as the week moves under it and the extras below stay extras.
///
/// Flat and neutral, with blue kept for the program: the kicker and Start.
class ProgramDayCard extends StatelessWidget {
  /// The mono line across the top: "UP NEXT". A card that only reports
  /// — a finished day, a finished week — goes without one.
  final String? kicker;
  final Color kickerColor;

  /// Its quieter partner on the right: "DAY 1 OF 3", "REST DAY".
  final String? kickerRight;

  /// The session's name, when the day has one to show in type. A rest day
  /// and a finished day carry their own words in [body].
  final String? title;

  /// "7 exercises · about 35 min".
  final String? meta;
  final Widget? body;
  final Widget? actions;

  /// Whether [body] takes the height the card is given beyond its own,
  /// which keeps [actions] on the card's bottom edge. Only for a card
  /// whose height is set from outside.
  final bool fillBody;

  const ProgramDayCard({
    super.key,
    this.kicker,
    this.kickerColor = AppColors.accentPrimary,
    this.kickerRight,
    this.title,
    this.meta,
    this.body,
    this.actions,
    this.fillBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kicker != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    kicker!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: monoStyle(
                      size: 11,
                      letterSpacing: 1.76,
                      color: kickerColor,
                    ),
                  ),
                ),
                if (kickerRight != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    kickerRight!,
                    style: monoStyle(
                      size: 11,
                      letterSpacing: 1.32,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          if (title != null)
            Padding(
              padding: EdgeInsets.only(top: kicker == null ? 0 : 12),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.02,
                ),
              ),
            ),
          if (meta != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                meta!,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (body != null) fillBody ? Expanded(child: body!) : body!,
          if (actions != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: actions,
            ),
        ],
      ),
    );
  }
}

/// The first few exercises of the session, and how many more there are —
/// content only the program has, which is what marks the card as the main
/// thing on the tab. The whole list is a tap away, on the list button.
class ProgramPreviewList extends StatelessWidget {
  final List<TodayWorkoutRow> rows;

  /// How many are named before the rest are counted.
  final int shown;

  const ProgramPreviewList({super.key, required this.rows, this.shown = 3});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final visible = rows.take(shown).toList();
    final more = rows.length - visible.length;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in visible)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (row.tag case final tag?) ...[
                    const SizedBox(width: 8),
                    LevelUpTag(tag: tag),
                  ],
                ],
              ),
            ),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '+ $more more',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The card's one row of actions: the day's verb, and the list button
/// beside it when there is a full workout to show.
///
/// Filled blue for today's Start — the program's colour — and outlined for
/// everything that is not the day's main verb: starting a day early, or
/// reopening one that is done.
class ProgramCardActions extends StatelessWidget {
  final String label;
  final VoidCallback? onPrimary;
  final bool quiet;

  /// Opens the full workout; null hides the button.
  final VoidCallback? onList;

  const ProgramCardActions({
    super.key,
    required this.label,
    required this.onPrimary,
    this.quiet = false,
    this.onList,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: quiet
              ? _OutlinePill(label: label, onTap: onPrimary)
              : PillButton(label: label, radius: 999, onTap: onPrimary),
        ),
        if (onList != null) ...[
          const SizedBox(width: 10),
          Pressable(
            onTap: onList,
            semanticLabel: 'Show the full workout',
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.format_list_bulleted_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OutlinePill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlinePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// The rest day as the program card says it: the rings, the words, and
/// the next session still within reach.
class RestDayCard extends StatelessWidget {
  final String? nextTitle;
  final String? nextWhen;
  final VoidCallback? onStartToday;

  const RestDayCard({
    super.key,
    this.nextTitle,
    this.nextWhen,
    this.onStartToday,
  });

  @override
  Widget build(BuildContext context) {
    return ProgramDayCard(
      kicker: 'TODAY',
      kickerRight: 'REST DAY',
      body: RestDayView(
        contained: true,
        nextTitle: nextTitle,
        nextWhen: nextWhen,
        onStartToday: onStartToday,
      ),
    );
  }
}

/// Gives [child] the height of the rest day's card, so the page under it
/// sits where it does on a day off. The height is taken from a rest card
/// laid out unseen behind it rather than from a number, which keeps the
/// two equal at any text size.
class RestDayHeight extends StatelessWidget {
  final Widget child;

  const RestDayHeight({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          // Unseen rings have nothing to breathe for.
          child: TickerMode(
            enabled: false,
            child: RestDayCard(nextTitle: '', onStartToday: () {}),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
