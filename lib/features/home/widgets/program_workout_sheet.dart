import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import 'today_workout_card.dart';

/// One line of the full workout: the exercise, and its target when the day
/// is close enough to have one ("3 × 8").
class ProgramSheetRow {
  final String exerciseId;
  final String name;
  final String? target;
  final TodayRowTag? tag;

  const ProgramSheetRow({
    this.exerciseId = '',
    required this.name,
    this.target,
    this.tag,
  });
}

/// The list button's sheet: the whole workout the card previews, numbered,
/// with Start still within reach at the bottom.
///
/// Resolves once the sheet is gone. [onStart] and [onRowTap] run after it
/// has closed, so what they open is not left under it.
Future<void> showProgramWorkoutSheet(
  BuildContext context, {
  required String kicker,
  required String title,
  required String meta,
  required List<ProgramSheetRow> rows,
  required String startLabel,
  required VoidCallback onStart,
  ValueChanged<ProgramSheetRow>? onRowTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      void closeThen(VoidCallback next) {
        Navigator.of(sheetContext).pop();
        next();
      }

      return Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + media.padding.bottom),
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
            Text(
              kicker,
              style: monoStyle(
                size: 11,
                letterSpacing: 1.76,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              meta,
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
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final content = Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${index + 1}',
                            style: monoStyle(size: 11, letterSpacing: 0),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  row.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
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
                        if (row.target != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              row.target!,
                              style: monoStyle(
                                size: 11.5,
                                weight: FontWeight.w600,
                                letterSpacing: 0.7,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                  if (onRowTap == null || row.exerciseId.isEmpty) {
                    return content;
                  }
                  return Pressable(
                    onTap: () => closeThen(() => onRowTap(row)),
                    child: content,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: startLabel,
              radius: 999,
              onTap: () => closeThen(onStart),
            ),
          ],
        ),
      );
    },
  );
}
