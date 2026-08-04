import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'polished.dart';

/// One draggable row on [ReorderExercisesPage].
class ReorderExerciseEntry {
  /// Stable identity — returned to the caller in the new order.
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;

  const ReorderExerciseEntry({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}

/// A block of rows that reorder among themselves. Exercises never cross from
/// one block into another — skill work stays ahead of the main lifts.
class ReorderExercisesSection {
  final String? title;
  final List<ReorderExerciseEntry> entries;

  const ReorderExercisesSection({this.title, required this.entries});
}

/// Shared drag-to-reorder page, used both by the live workout and by the
/// program's workout editor so reordering feels identical in both places.
///
/// Pops a list of id lists — one per section, in the order the user left
/// them — or null when nothing was saved.
class ReorderExercisesPage extends StatefulWidget {
  final List<ReorderExercisesSection> sections;
  final String footnote;

  const ReorderExercisesPage({
    super.key,
    required this.sections,
    this.footnote = 'Exercises stay inside their block — skill work always '
        'comes before the main lifts.',
  });

  /// Total rows across every section; fewer than two means there is nothing
  /// to reorder and the page is not worth opening.
  static int entryCount(List<ReorderExercisesSection> sections) =>
      sections.fold(0, (sum, section) => sum + section.entries.length);

  @override
  State<ReorderExercisesPage> createState() => _ReorderExercisesPageState();
}

class _ReorderExercisesPageState extends State<ReorderExercisesPage> {
  late final List<List<ReorderExerciseEntry>> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      for (final section in widget.sections) List.of(section.entries),
    ];
  }

  bool get _dirty {
    for (var s = 0; s < _sections.length; s++) {
      final original = widget.sections[s].entries;
      for (var i = 0; i < _sections[s].length; i++) {
        if (_sections[s][i].id != original[i].id) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reorder exercises',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Drag ≡ to change the order',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  for (var s = 0; s < _sections.length; s++) ...[
                    if (widget.sections[s].title != null)
                      SectionHeader(title: widget.sections[s].title!),
                    SurfaceCard(
                      clip: true,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _sections[s].length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final list = _sections[s];
                            list.insert(newIndex, list.removeAt(oldIndex));
                          });
                        },
                        proxyDecorator: (child, _, __) => Material(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                          child: child,
                        ),
                        itemBuilder: (context, index) => _ReorderRow(
                          key: ValueKey(_sections[s][index].id),
                          entry: _sections[s][index],
                          index: index,
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
                    child: Text(
                      widget.footnote,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: PillButton(
                label: dirty ? 'Save order' : 'No changes yet',
                onTap: dirty
                    ? () => Navigator.of(context).pop([
                          for (final section in _sections)
                            [for (final entry in section) entry.id],
                        ])
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderRow extends StatelessWidget {
  final ReorderExerciseEntry entry;
  final int index;

  const _ReorderRow({
    super.key,
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: index > 0
            ? const Border(top: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          IconTile(icon: entry.icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.drag_handle_rounded,
                size: 19,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
