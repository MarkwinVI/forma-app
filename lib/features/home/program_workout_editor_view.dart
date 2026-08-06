import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/reorder_exercises_page.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../exercises/exercise_picker_view.dart';
import 'program_day_items.dart';

/// Destructive action colour, matching the design's red.
const _dangerRed = Color(0xFFFF6B57);

/// Full-page editor for one workout type: the schedule is stated once at the
/// top, then it's just the exercise list every scheduled day shares. Each row
/// opens its own options — reorder, replace, remove — and Add exercise goes
/// straight to the exercise search.
class ProgramWorkoutEditorView extends StatefulWidget {
  final TrainingSessionType sessionType;
  final TrainingProgramType programType;
  final Map<TrainingTrack, String> branchSelections;
  final Map<String, ExerciseStatus> progressMap;
  final Map<String, dynamic> sessionItemsConfig;
  final bool hasGym;

  /// The program's skill tracks — the default day is built from these, so
  /// the editor opens on the session the user actually trains rather than
  /// the legacy lane defaults.
  final List<SkillTrack> skillTracks;
  final Future<void> Function(Map<String, dynamic> sessionItemsConfig) onSave;

  const ProgramWorkoutEditorView({
    super.key,
    required this.sessionType,
    required this.programType,
    required this.branchSelections,
    required this.progressMap,
    required this.sessionItemsConfig,
    this.hasGym = true,
    this.skillTracks = const [],
    required this.onSave,
  });

  @override
  State<ProgramWorkoutEditorView> createState() =>
      _ProgramWorkoutEditorViewState();
}

class _ProgramWorkoutEditorViewState extends State<ProgramWorkoutEditorView> {
  final _programService = TrainingProgramService();

  late List<ProgramDayItem> _items;
  late String _initialSerialized;
  bool _saving = false;

  String get _typeName => programWorkoutTypeName(widget.sessionType);

  @override
  void initState() {
    super.initState();
    _items = ProgramSessionPlan.loadDay(
      service: _programService,
      sessionItemsConfig: widget.sessionItemsConfig,
      programType: widget.programType,
      sessionType: widget.sessionType,
      branchSelections: widget.branchSelections,
      progressMap: widget.progressMap,
      skillTracks: widget.skillTracks,
      hasGym: widget.hasGym,
    );
    _initialSerialized = _serialized();
  }

  String _serialized() => jsonEncode(ProgramSessionPlan.serializeDay(_items));

  bool get _dirty => _serialized() != _initialSerialized;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    // One list per workout type: every day running this session shares it.
    final config = Map<String, dynamic>.from(widget.sessionItemsConfig);
    writeProgramDayConfig(
      config,
      widget.sessionType,
      ProgramSessionPlan.serializeDay(_items),
    );

    try {
      await widget.onSave(config);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save $_typeName: $error')),
      );
      setState(() => _saving = false);
    }
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((item) => item.id == id));
  }

  ProgramDayItem _itemFor(Exercise exercise) => ProgramDayItem(
        id: newProgramItemId(),
        kind: ProgramDayItemKind.exercise,
        name: exercise.name,
        exerciseId: exercise.id,
      );

  /// Both adding and replacing open the exercise search. Replacing takes the
  /// first tap and drops it into that row's slot; adding accumulates picks
  /// and appends them all at once.
  Future<void> _openAddPicker({int? replacingIndex}) async {
    final picked = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => ExercisePickerView(
          excludedIds: {
            for (final item in _items)
              if (item.exerciseId != null) item.exerciseId!,
          },
          progressMap: widget.progressMap,
          singlePick: replacingIndex != null,
        ),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    setState(() {
      if (replacingIndex != null && replacingIndex < _items.length) {
        _items[replacingIndex] = _itemFor(picked.first);
        return;
      }
      _items.addAll(picked.map(_itemFor));
    });
  }

  Exercise? _exerciseFor(ProgramDayItem item) =>
      item.exerciseId == null ? null : ExerciseCatalog.findById(item.exerciseId!);

  /// The exercise's own page — how to perform it and its history both live
  /// there, which is why the row's menu no longer duplicates them.
  Future<void> _openItemDetail(ProgramDayItem item) async {
    final exercise = _exerciseFor(item);
    if (exercise == null) return;

    await openExerciseDetailView<void>(
      context,
      exercise: exercise,
      skillCategoryId: item.skillCategoryId,
    );
  }

  /// Options for one row: what you can do to the workout. Reading about the
  /// exercise is a tap on its name instead.
  Future<void> _openItemActions(ProgramDayItem item) async {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;

    final action = await showModalBottomSheet<_ItemAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _ItemMenuSheet(
        title: item.name,
        subtitle: _itemSubtitle(item),
        canReorder: _items.length > 1,
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _ItemAction.reorder:
        await _openReorder();
      case _ItemAction.replace:
        await _openAddPicker(replacingIndex: index);
      case _ItemAction.remove:
        _removeItem(item.id);
    }
  }

  Future<void> _openReorder() async {
    if (_items.length < 2) return;

    final order = await Navigator.of(context).push<List<List<String>>>(
      MaterialPageRoute(
        builder: (_) => ReorderExercisesPage(
          sections: [
            ReorderExercisesSection(
              entries: [
                for (final item in _items)
                  ReorderExerciseEntry(
                    id: item.id,
                    name: item.name,
                    subtitle: _itemSubtitle(item),
                    icon: programPatternIcon(item.category),
                  ),
              ],
            ),
          ],
          footnote: 'Exercises run in this order every time this workout '
              'comes up.',
        ),
      ),
    );
    if (order == null || !mounted) return;

    final byId = {for (final item in _items) item.id: item};
    setState(() {
      _items = [
        for (final id in order.first)
          if (byId[id] != null) byId[id]!,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12, bottom: 4),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 26,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _typeName,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.9,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'Nothing planned for $_typeName yet — add your '
                              'first exercise below.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.55,
                              ),
                            ),
                          )
                        else
                          for (final item in _items)
                            _ItemRow(
                              item: item,
                              subtitle: _itemSubtitle(item),
                              onOptions: () => _openItemActions(item),
                              onOpenDetail: _exerciseFor(item) == null
                                  ? null
                                  : () => _openItemDetail(item),
                            ),
                        _AddExerciseRow(onTap: _openAddPicker),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Nothing to save is nothing to say — the button appears with the
            // first edit rather than sitting there disabled.
            if (dirty || _saving)
              Positioned(
                left: 22,
                right: 22,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: _saving
                    ? const SizedBox(
                        height: 52,
                        child: Center(child: LoadingIndicator()),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x73000000),
                              offset: Offset(0, 10),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: PillButton(
                          label: 'Save $_typeName',
                          onTap: _save,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// Where the exercise came from — the tree that schedules it and advances
  /// it on its own, or the user adding it by hand. That is what decides how
  /// the row behaves, so it is what the row says.
  String _itemSubtitle(ProgramDayItem item) {
    if (item.kind != ProgramDayItemKind.progression) {
      return 'Standalone exercise';
    }

    final category = item.skillCategoryId == null
        ? null
        : SkillCategoryCatalog.findById(item.skillCategoryId!);
    if (category == null) return 'Skill tree progression';
    return 'From: ${category.title} skill tree';
  }
}

/// One exercise in the workout: name, what it trains, and a single options
/// button — everything else lives in the sheet behind it.
class _ItemRow extends StatelessWidget {
  final ProgramDayItem item;
  final String subtitle;
  final VoidCallback onOptions;

  /// Opens the exercise's own page. Null for the rare item whose exercise is
  /// not in the catalog — the name then behaves as plain text.
  final VoidCallback? onOpenDetail;

  const _ItemRow({
    required this.item,
    required this.subtitle,
    required this.onOptions,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only the name is the target — the rest of the row belongs
                // to the options button, and tapping a subtitle that merely
                // states where the exercise came from should do nothing.
                Pressable(
                  onTap: onOpenDetail,
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.25,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Pressable(
            onTap: onOptions,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ItemAction { reorder, replace, remove }

/// The row's options: what you can do to the workout. What the exercise *is*
/// belongs to its own page, which the row's name opens.
class _ItemMenuSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool canReorder;

  const _ItemMenuSheet({
    required this.title,
    required this.subtitle,
    required this.canReorder,
  });

  @override
  Widget build(BuildContext context) {
    void pick(_ItemAction action) => Navigator.of(context).pop(action);

    return SheetShell(
      title: title,
      sub: subtitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SurfaceCard(
              clip: true,
              child: Column(
                children: [
                  _MenuRow(
                    label: 'Reorder exercises',
                    enabled: canReorder,
                    onTap: () => pick(_ItemAction.reorder),
                  ),
                  _MenuRow(
                    label: 'Replace exercise',
                    withDivider: true,
                    onTap: () => pick(_ItemAction.replace),
                  ),
                  _MenuRow(
                    label: 'Remove exercise',
                    danger: true,
                    withDivider: true,
                    onTap: () => pick(_ItemAction.remove),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final bool danger;
  final bool enabled;
  final bool withDivider;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    this.danger = false,
    this.enabled = true,
    this.withDivider = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textMuted
        : danger
            ? _dangerRed
            : AppColors.textPrimary;

    return Pressable(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          border: withDivider
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.25,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: enabled ? AppColors.textMuted : AppColors.surface3,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExerciseRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Add exercise',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
