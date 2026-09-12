import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/equipment_model.dart';

/// The reminder every answer short of a pull-up bar earns, in the setup
/// wizard and on the Program tab alike.
const String kPullUpBarNote =
    'You’ll still need access to at least a pull-up bar — most of Forma’s '
    'pulling work hangs from one. A doorway bar or a park is enough.';

/// Whether [answer] earns [kPullUpBarNote]: "No equipment", or a list of
/// items without a bar in it. An unanswered or still-empty list stays quiet
/// — there is nothing to warn about yet.
bool equipmentNeedsBarNote(EquipmentAnswer? answer) {
  if (answer == null) return false;
  if (answer.isSome && answer.items.isEmpty) return false;
  return !answer.hasPullUpBar;
}

/// The "Some equipment" option: the third radio row of the equipment
/// question. Once picked it shows what was ticked and an Edit affordance;
/// before that, a hint at what the list is for.
class SomeEquipmentRow extends StatelessWidget {
  final bool selected;
  final Set<EquipmentItem> items;
  final VoidCallback onTap;

  const SomeEquipmentRow({
    super.key,
    required this.selected,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = selected && items.isNotEmpty;

    return Pressable(
      onTap: onTap,
      selected: selected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.accentPrimary, width: 1.5)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: selected
                      ? AppColors.accentPrimary
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Some equipment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.16,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    hasItems
                        ? EquipmentAnswer.summarizeItems(items)
                        : 'Rings, a kettlebell, a bar in the garage…',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: hasItems
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (!selected) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Tell Forma exactly what you have.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasItems) ...[
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Two columns of illustrated tiles, one per [EquipmentItem], each a
/// checkbox. Lays itself out as rows so it sits inside any scroll view.
class EquipmentTileGrid extends StatelessWidget {
  final Set<EquipmentItem> picked;
  final ValueChanged<EquipmentItem> onToggle;

  const EquipmentTileGrid({
    super.key,
    required this.picked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const items = EquipmentItem.values;
    return Column(
      children: [
        for (var row = 0; row < items.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: EquipmentTile(
                  item: items[row],
                  selected: picked.contains(items[row]),
                  onTap: () => onToggle(items[row]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: row + 1 < items.length
                    ? EquipmentTile(
                        item: items[row + 1],
                        selected: picked.contains(items[row + 1]),
                        onTap: () => onToggle(items[row + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One illustrated equipment tile: the picture, its name under it, and a
/// check in the corner once ticked.
class EquipmentTile extends StatelessWidget {
  final EquipmentItem item;
  final bool selected;
  final VoidCallback onTap;

  const EquipmentTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: item.label,
      selected: selected,
      child: Container(
        height: 148,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selected ? 1 : 0.85,
                      child: Image.asset(
                        item.asset,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.14,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The CTA label under a tile grid: how many are ticked, or the nudge to
/// tick one.
String equipmentDoneLabel(Set<EquipmentItem> picked) => picked.isEmpty
    ? 'Select at least one item'
    : 'Done — ${picked.length} item${picked.length == 1 ? '' : 's'}';

/// The setup wizard's "What do you have?" sheet: the tile grid, the bar
/// reminder, and Done. Every toggle reaches [onChanged] as it happens, so
/// dismissing the sheet by the scrim or the handle loses nothing — the
/// caller decides what an empty list means.
class EquipmentPickerSheet extends StatefulWidget {
  final Set<EquipmentItem> initial;
  final ValueChanged<Set<EquipmentItem>> onChanged;

  const EquipmentPickerSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  /// Opens the sheet over [context]; resolves once it closes, however it
  /// closed.
  static Future<void> show(
    BuildContext context, {
    required Set<EquipmentItem> initial,
    required ValueChanged<Set<EquipmentItem>> onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => EquipmentPickerSheet(
        initial: initial,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<EquipmentPickerSheet> createState() => _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends State<EquipmentPickerSheet> {
  late final Set<EquipmentItem> _picked = {...widget.initial};

  void _toggle(EquipmentItem item) {
    setState(() {
      if (!_picked.remove(item)) _picked.add(item);
    });
    widget.onChanged({..._picked});
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'What do you have?',
      sub: 'Tick everything you can train with.',
      showClose: false,
      footer: PillButton(
        label: equipmentDoneLabel(_picked),
        onTap: _picked.isEmpty ? null : () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            EquipmentTileGrid(picked: _picked, onToggle: _toggle),
            if (_picked.isNotEmpty &&
                !_picked.contains(EquipmentItem.pullUpBar)) ...[
              const SizedBox(height: 14),
              const EquipmentBarNote(),
            ],
          ],
        ),
      ),
    );
  }
}

/// [kPullUpBarNote] on an amber card, with the bar itself in bold.
class EquipmentBarNote extends StatelessWidget {
  const EquipmentBarNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 17,
              color: AppColors.amber,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'You’ll still need access to at least a '),
                  TextSpan(
                    text: 'pull-up bar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' — most of Forma’s pulling work hangs from one. '
                        'A doorway bar or a park is enough.',
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.amber,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
