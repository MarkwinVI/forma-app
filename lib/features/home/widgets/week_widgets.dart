import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../weekly_quota.dart';

/// The line across the top of the Train tab: how the week stands, a bar
/// with one segment per session, and the way into the week's sessions.
///
/// Quiet on purpose — a mono line, not a title — so the session in the
/// card under it stays the one loud thing on the tab.
class WeekHeader extends StatelessWidget {
  final WeeklyQuota quota;
  final VoidCallback onSeeUpcoming;

  const WeekHeader({
    super.key,
    required this.quota,
    required this.onSeeUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'THIS WEEK · ${quota.done} OF ${quota.target}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: monoStyle(
                  size: 11,
                  letterSpacing: 1.65,
                  color: quota.isComplete
                      ? AppColors.green
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Pressable(
              onTap: onSeeUpcoming,
              semanticLabel: 'See upcoming sessions',
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See upcoming',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.accentPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Semantics(
          label: '${quota.done} of ${quota.target} sessions done this week',
          child: Row(
            children: [
              for (var index = 0; index < quota.target; index++) ...[
                if (index > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index < quota.done
                          ? AppColors.green
                          : AppColors.surface3,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The card's words when there is nothing to start: today's session is
/// logged, or the week's count is met.
class WeekDoneBody extends StatelessWidget {
  final String title;
  final String line;

  const WeekDoneBody({super.key, required this.title, required this.line});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.greenSoft,
          ),
          alignment: Alignment.center,
          child: const ExcludeSemantics(
            child: Icon(Icons.check_rounded, size: 28, color: AppColors.green),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          line,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Where a session stands in the week's sheet.
enum WeekSessionState { done, next, upcoming, rest }

/// One line of the week's sheet: a session, or a day off between two.
class WeekSessionRow {
  /// "DONE · MONDAY", "TODAY · UP NEXT", "SATURDAY", "NEXT WEEK".
  final String label;

  /// The session's name — "Pull Day" — or "Rest day".
  final String name;
  final WeekSessionState state;

  /// Which session of the week this is; null for a day off.
  final int? number;

  /// Opens the session — a logged workout, or the one up next. Null
  /// leaves the row as words.
  final VoidCallback? onTap;

  const WeekSessionRow({
    required this.label,
    required this.name,
    required this.state,
    this.number,
    this.onTap,
  });
}

/// The week behind "See upcoming": what is done, then the days still
/// ahead in order — sessions and the days off between them — and the one
/// rule the model has.
Future<void> showWeekSheet(
  BuildContext context, {
  required WeeklyQuota quota,
  required List<WeekSessionRow> rows,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final days = quota.daysLeft;
      final sub = quota.isComplete
          ? '${quota.done} of ${quota.target} done · a new week starts Monday'
          : '${quota.done} of ${quota.target} done · '
              '$days ${days == 1 ? 'day' : 'days'} left';

      return Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + media.padding.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'This week',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                itemBuilder: (context, index) => _WeekSheetRow(
                  row: rows[index],
                  onTap: rows[index].onTap == null
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          rows[index].onTap!();
                        },
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'A suggested rhythm, not a schedule: train on any day you '
              'like. A session you don’t get to carries into next week.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _WeekSheetRow extends StatelessWidget {
  final WeekSessionRow row;
  final VoidCallback? onTap;

  const _WeekSheetRow({
    required this.row,
    required this.onTap,
  });

  Color get _tone => switch (row.state) {
        WeekSessionState.done => AppColors.green,
        WeekSessionState.next => AppColors.accentPrimary,
        WeekSessionState.upcoming ||
        WeekSessionState.rest =>
          AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final done = row.state == WeekSessionState.done;
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.greenSoft : null,
              border: done
                  ? null
                  : Border.all(
                      color: row.state == WeekSessionState.next
                          ? AppColors.accentPrimary
                          : AppColors.surface3,
                      width: 1.5,
                    ),
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.green,
                    )
                  : row.number == null
                      ? const Icon(
                          Icons.bedtime_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        )
                      : Text(
                          '${row.number}',
                          style: monoStyle(
                            size: 12,
                            letterSpacing: 0,
                            color: _tone,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: monoStyle(size: 10, letterSpacing: 1.1, color: _tone),
                ),
                const SizedBox(height: 4),
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: row.state == WeekSessionState.rest
                        ? FontWeight.w600
                        : FontWeight.w700,
                    color: row.state == WeekSessionState.rest
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${row.label}, ${row.name}',
      child: content,
    );
  }
}
