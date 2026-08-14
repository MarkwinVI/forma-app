import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_event_model.dart';
import '../../../data/services/dev_clock_service.dart';
import '../../../data/services/weight_unit_service.dart';
import '../program_faq.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// One rendered change, in the only words the app uses for these: the
/// exercise, what the program did to it, and the number that moved.
///
/// Every surface that reports a change — the receipt on the finish screen,
/// the line above today's session, the sheet behind it — reads from this, so
/// a raised target is called the same thing wherever it is mentioned.
class _InsightItem {
  final Color color;
  final String name;
  final String detail;
  final String value;

  /// How this kind of change is counted in a summary line: "two targets
  /// raised", "one exercise unlocked".
  final String Function(int count) noun;

  const _InsightItem({
    required this.color,
    required this.name,
    required this.detail,
    required this.value,
    required this.noun,
  });
}

String _plural(int count, String one, String many) => count == 1 ? one : many;

/// The Train tab's one-line note that the program moved: a mono flag, what
/// changed and when, and a way into the detail.
///
/// Compressed to a line on purpose — a second list of exercise names beside
/// today's session competes with the only list that screen is for.
class WhatChangedLine extends StatelessWidget {
  final List<ProgressionEvent> events;
  final VoidCallback onTap;

  const WhatChangedLine({
    super.key,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = summaryFor(events);
    if (summary == null) return const SizedBox.shrink();

    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 22),
        padding: const EdgeInsets.only(top: 11, bottom: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider),
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Text(
              'UPDATED',
              style: monoStyle(
                  size: 10, letterSpacing: 1.4, color: AppColors.green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// "Two targets raised since Tuesday", counted in the same words the list
  /// uses — or null when there is nothing to report.
  static String? summaryFor(List<ProgressionEvent> events) {
    final items = _itemsFor(events);
    if (items.isEmpty) return null;

    // Group by what happened, so each kind is counted in its own noun rather
    // than everything collapsing into "updates".
    final counts = <String, int>{};
    for (final item in items) {
      final key = item.noun(2);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final clauses = [
      for (final entry in counts.entries)
        '${_spelled(entry.value)} '
            '${items.firstWhere((item) => item.noun(2) == entry.key).noun(entry.value)}',
    ];

    final said = switch (clauses.length) {
      1 => clauses.first,
      2 => '${clauses.first} and ${clauses.last.toLowerCase()}',
      _ => '${clauses.first} and ${clauses.length - 1} more changes',
    };
    final when = _lastDayName(events);

    return when == null ? said : '$said since $when';
  }
}

/// Lifts the detail over the session: why the program moved, what earned each
/// raise, and where the rule is written down.
Future<void> showWhatChangedSheet(
  BuildContext context,
  List<ProgressionEvent> events,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (_) => _WhatChangedSheet(events: events),
  );
}

class _WhatChangedSheet extends StatelessWidget {
  final List<ProgressionEvent> events;

  const _WhatChangedSheet({required this.events});

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(events);
    final when = _lastDayName(events);
    final headline = WhatChangedLine.summaryFor(events) ?? 'Nothing changed';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        30 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            when == null ? 'UPDATED' : 'UPDATED AFTER ${when.toUpperCase()}',
            style: monoStyle(
              size: 10.5,
              letterSpacing: 1.55,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.81,
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Container(
              margin: EdgeInsets.only(top: i == 0 ? 22 : 0),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    items[i].value,
                    style: monoStyle(
                      size: 14,
                      letterSpacing: 0.2,
                      color: items[i].color,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 13, bottom: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Pressable(
              onTap: () {
                Navigator.of(context).pop();
                showFaqSheet(context, kHowTargetsAreSetFaq);
              },
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'How targets are set',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "What the program changed" on the finish screen — a receipt, deliberately
/// lighter than any exercise list: what moved, and its new number.
class TrainInsight extends StatelessWidget {
  final List<ProgressionEvent> events;

  const TrainInsight({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(events);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TypeSectionLabel('What the program changed', top: 26),
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cardHighlight)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.value,
                  style: monoStyle(
                    size: 13.5,
                    letterSpacing: 0.2,
                    color: item.color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The weekday the most recent change was earned on, or null when that was
/// today — "since today" says nothing. Reads the developer clock so time
/// travel moves this line with everything else.
String? _lastDayName(List<ProgressionEvent> events) {
  if (events.isEmpty) return null;
  var latest = events.first.createdAt;
  for (final event in events) {
    if (event.createdAt.isAfter(latest)) latest = event.createdAt;
  }
  final now = DevClockService().now();
  final sameDay = latest.year == now.year &&
      latest.month == now.month &&
      latest.day == now.day;
  return sameDay ? null : _weekdayNames[latest.weekday - 1];
}

/// Small counts read better spelled out at the head of a sentence.
String _spelled(int count) {
  const words = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
  ];
  return count >= 0 && count < words.length ? words[count] : '$count';
}

List<_InsightItem> _itemsFor(List<ProgressionEvent> events) {
  return [
    for (final event in events)
      if (_itemFor(event) case final item?) item,
  ];
}

/// Maps a progression event to one rendered change, or null when it has no
/// catalog exercise (or is a personal best, which lives on Progress).
///
/// The wording here is the app's whole vocabulary for program changes — every
/// surface that reports one renders from this.
_InsightItem? _itemFor(ProgressionEvent event) {
  final exercise = ExerciseCatalog.findById(event.exerciseId);
  if (exercise == null) return null;
  final unit = exercise.isTimed ? 's' : '';
  final sets = event.targetSets ?? 3;

  /// Targets are written in full — "3×7", not "7" — so a raise reads as the
  /// work it actually asks for.
  String target(int? value) => value == null ? '—' : '$sets×$value$unit';

  switch (event.kind) {
    case ProgressionEventKind.targetIncrease:
      return _InsightItem(
        color: AppColors.green,
        name: exercise.name,
        detail: 'target raised',
        value: event.valueFrom == null
            ? '→ ${target(event.valueTo)}'
            : '${target(event.valueFrom)} → ${target(event.valueTo)}',
        noun: (count) => _plural(count, 'target raised', 'targets raised'),
      );
    case ProgressionEventKind.mastered:
      return _InsightItem(
        color: AppColors.green,
        name: exercise.name,
        detail: 'mastered',
        value: target(event.valueTo),
        noun: (count) =>
            _plural(count, 'exercise mastered', 'exercises mastered'),
      );
    case ProgressionEventKind.activated:
      final related = event.relatedExerciseId == null
          ? null
          : ExerciseCatalog.findById(event.relatedExerciseId!);
      return _InsightItem(
        color: AppColors.accentPrimary,
        name: exercise.name,
        detail: related == null ? 'unlocked' : 'unlocked after ${related.name}',
        value: '→ ${target(event.valueTo)}',
        noun: (count) =>
            _plural(count, 'exercise unlocked', 'exercises unlocked'),
      );
    case ProgressionEventKind.personalBest:
      return null; // Shown as an achievement on the Progress tab.
    case ProgressionEventKind.branchChoice:
      return _InsightItem(
        color: AppColors.accentPrimary,
        name: exercise.name,
        detail: 'path forks here',
        value: 'choose',
        noun: (count) => _plural(count, 'path to choose', 'paths to choose'),
      );
    case ProgressionEventKind.loadIncrease:
      return _InsightItem(
        color: AppColors.green,
        name: exercise.name,
        detail: 'load raised',
        value: '${weightLabel(event.weightFrom)} → '
            '${weightLabel(event.weightTo)}',
        noun: (count) => _plural(count, 'load raised', 'loads raised'),
      );
  }
}

/// A working weight as the app writes it: shown in the display unit, whole
/// numbers stay whole, halves keep their decimal, and a missing weight reads
/// as a dash.
String weightLabel(double? weightKg) {
  if (weightKg == null) return '—';
  return '${WeightUnitService.displayText(weightKg)} '
      '${WeightUnitService.unit.suffix}';
}
