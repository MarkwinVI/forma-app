import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/reorder_exercises_page.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../exercises/exercise_picker_view.dart';
import 'program_day_items.dart';
import 'program_skill_wheel_view.dart';

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

  /// Live copies of the parent's progress and tracks — re-fetched after the
  /// user edits a progression in its tree, so the day re-reads fresh state.
  late Map<String, ExerciseStatus> _progress = widget.progressMap;
  late List<SkillTrack> _skillTracks = widget.skillTracks;

  /// exercise id → whether the user has turned auto progression off. Only
  /// what they have said is here; everything else is the default, on.
  Map<String, bool> _autoProgression = const {};

  String get _typeName => programWorkoutTypeName(widget.sessionType);

  @override
  void initState() {
    super.initState();
    _items = _loadDay();
    _initialSerialized = _serialized();
    _loadAutoProgression();
  }

  List<ProgramDayItem> _loadDay() => ProgramSessionPlan.loadDay(
        service: _programService,
        sessionItemsConfig: widget.sessionItemsConfig,
        programType: widget.programType,
        sessionType: widget.sessionType,
        branchSelections: widget.branchSelections,
        progressMap: _progress,
        skillTracks: _skillTracks,
        hasGym: widget.hasGym,
      );

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

  /// Add exercise opens the exercise search; picks accumulate and append all
  /// at once.
  Future<void> _openAddPicker() async {
    final picked = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => ExercisePickerView(
          excludedIds: {
            for (final item in _items)
              if (item.exerciseId != null) item.exerciseId!,
          },
          progressMap: _progress,
        ),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    setState(() => _items.addAll(picked.map(_itemFor)));
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
    final action = await showModalBottomSheet<_ItemAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _ItemMenuSheet(
        title: item.name,
        subtitle: _itemSubtitle(item),
        isProgression: item.kind == ProgramDayItemKind.progression,
        canReorder: _items.length > 1,
        autoProgression: _autoProgressionFor(item),
        autoProgressionEditable: switch (_accessoryExercise(item)) {
          final exercise? =>
            ExerciseProgressionService.supportsAutoProgression(exercise),
          null => false,
        },
        onAutoProgressionChanged: (enabled) =>
            _setAutoProgression(item, enabled),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _ItemAction.editProgression:
        await _openProgressionEditor(item);
      case _ItemAction.reorder:
        await _openReorder();
      case _ItemAction.remove:
        _removeItem(item.id);
    }
  }

  /// "Edit progression" — the skill wheel flown straight into this item's
  /// tree, where the current step and branch live. On return the day is
  /// re-read with fresh progress so a moved progression shows its new step,
  /// unless unsaved edits here would be thrown away by the re-read.
  Future<void> _openProgressionEditor(ProgramDayItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSkillWheelView(
          initialCategoryId: item.skillCategoryId,
          // Back from the tree returns to this list — the wheel overview
          // would be a detour the user never asked for.
          exitOnTreeBack: true,
        ),
      ),
    );
    if (!mounted || _dirty) return;

    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      final results = await Future.wait([
        ProgressService().fetchAll(userId),
        SkillTrackService().fetchAll(userId),
      ]);
      if (!mounted) return;
      final progress = results[0] as List<ExerciseProgress>;
      final tracks = results[1] as List<SkillTrack>;
      setState(() {
        _progress = {for (final row in progress) row.exerciseId: row.status};
        _skillTracks = tracks;
        _items = _loadDay();
        // The re-read is the saved day, just resolved against fresh progress
        // — it must not count as an edit.
        _initialSerialized = _serialized();
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh after editing a progression: '
          '$error\n$stackTrace');
    }
  }

  /// Reads which accessories the user has taken off auto progression. Until
  /// it lands every accessory reads as managed, which is the default anyway,
  /// so the sheet is never wrong for long and never blocks on a fetch.
  Future<void> _loadAutoProgression() async {
    try {
      // Everything is inside the guard, the session lookup included: the page
      // opens with or without this, so nothing here may take it down.
      final userId = AuthService().currentUser?.id;
      if (userId == null) return;
      final rows = await ProgressService().fetchAll(userId);
      if (!mounted) return;
      setState(() {
        _autoProgression = {
          for (final row in rows)
            if (row.autoProgression != null) row.exerciseId: row.autoProgression!,
        };
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to read auto progression: $error\n$stackTrace');
    }
  }

  /// The catalog exercise behind an accessory row, or null for a progression
  /// (its tree owns the exercise) and for a row whose movement is unknown.
  Exercise? _accessoryExercise(ProgramDayItem item) {
    if (item.kind == ProgramDayItemKind.progression) return null;
    final exerciseId = item.exerciseId;
    return exerciseId == null ? null : ExerciseCatalog.findById(exerciseId);
  }

  /// Whether Forma is managing this row between sessions. A progression
  /// always is; an accessory is unless it cannot be, or the user said stop.
  bool _autoProgressionFor(ProgramDayItem item) {
    final exercise = _accessoryExercise(item);
    if (exercise == null) return item.kind == ProgramDayItemKind.progression;
    if (!ExerciseProgressionService.supportsAutoProgression(exercise)) {
      return false;
    }
    return _autoProgression[exercise.id] ?? true;
  }

  Future<void> _setAutoProgression(ProgramDayItem item, bool enabled) async {
    final exercise = _accessoryExercise(item);
    if (exercise == null) return;
    setState(
        () => _autoProgression = {..._autoProgression, exercise.id: enabled});

    try {
      final userId = AuthService().currentUser?.id;
      if (userId == null) return;
      await ProgressService().setAutoProgression(
        userId,
        exercise.id,
        enabled: enabled,
      );
    } catch (error, stackTrace) {
      // Put the switch back rather than show a saved setting that is not.
      if (mounted) {
        setState(() =>
            _autoProgression = {..._autoProgression, exercise.id: !enabled});
      }
      debugPrint('Failed to save auto progression: $error\n$stackTrace');
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
                    icon: programPatternIcon(item.category),
                  ),
              ],
            ),
          ],
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
    // The Save pill floats above the bottom inset — which, inside the tab
    // shell, is the tab bar as well as the home indicator — so the list
    // keeps that much clear under its last row, plus the pill and a gap.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final listBottomPadding = bottomInset + 24 + 52 + 32;

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
                        programWorkoutDayName(widget.sessionType),
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
                    // Always scrollable: a list that just fits the screen
                    // still gives under the thumb, rather than reading as
                    // stuck the moment removing a row makes it fit.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(22, 4, 22, listBottomPadding),
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
                bottom: bottomInset + 24,
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
      return 'Accessory exercise';
    }

    final category = item.skillCategoryId == null
        ? null
        : SkillCategoryCatalog.findById(item.skillCategoryId!);
    if (category == null) return 'Skill tree progression';
    return '${category.title} progression';
  }
}

/// One exercise in the workout: name, where it came from, and a single options
/// button — everything else lives in the sheet behind it.
class _ItemRow extends StatelessWidget {
  final ProgramDayItem item;
  final VoidCallback onOptions;

  /// Opens the exercise's own page. Null for the rare item whose exercise is
  /// not in the catalog — the name then behaves as plain text.
  final VoidCallback? onOpenDetail;

  const _ItemRow({
    required this.item,
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
                const SizedBox(height: 8),
                _SourceChip(item: item),
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

/// Where the exercise came from, worn as a tag: an accent "progression" chip
/// linking it to its skill tree, or a muted "accessory" chip for supporting
/// work that nothing schedules or advances.
class _SourceChip extends StatelessWidget {
  final ProgramDayItem item;

  const _SourceChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final fromTree = item.kind == ProgramDayItemKind.progression;
    final category = item.skillCategoryId == null
        ? null
        : SkillCategoryCatalog.findById(item.skillCategoryId!);
    final label = fromTree
        ? '${category?.title ?? 'Skill Tree'} Progression'
        : 'Accessory';
    final color =
        fromTree ? const Color(0xFF9DB9FF) : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 5, 12, 5),
      decoration: BoxDecoration(
        color: fromTree
            ? AppColors.accentSoft
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fromTree)
            // The diagonal chain link of the reference design — Material only
            // draws it horizontal.
            Transform.rotate(
              angle: -math.pi / 4,
              child: Icon(Icons.link_rounded, size: 13, color: color),
            )
          else
            Icon(Icons.motion_photos_on_rounded, size: 12, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ItemAction { editProgression, reorder, remove }

/// The row's options: what you can do to the workout. What the exercise *is*
/// belongs to its own page, which the row's name opens. A progression also
/// offers its tree — the progression itself is edited there, not here.
class _ItemMenuSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isProgression;
  final bool canReorder;

  /// Whether Forma manages this exercise's reps and weight. A skill-tree
  /// step always does — its ladder is the whole point — so the row states
  /// that rather than hiding it.
  final bool autoProgression;

  /// Only a reps × weight accessory is the user's to decide. Everything else
  /// shows the row and cannot touch it.
  final bool autoProgressionEditable;
  final ValueChanged<bool> onAutoProgressionChanged;

  const _ItemMenuSheet({
    required this.title,
    required this.subtitle,
    required this.isProgression,
    required this.canReorder,
    required this.autoProgression,
    required this.autoProgressionEditable,
    required this.onAutoProgressionChanged,
  });

  @override
  State<_ItemMenuSheet> createState() => _ItemMenuSheetState();
}

class _ItemMenuSheetState extends State<_ItemMenuSheet> {
  late bool _autoProgression = widget.autoProgression;

  String get title => widget.title;
  String get subtitle => widget.subtitle;
  bool get isProgression => widget.isProgression;
  bool get canReorder => widget.canReorder;
  bool get autoProgression => _autoProgression;
  bool get autoProgressionEditable => widget.autoProgressionEditable;

  /// Flipped here and saved by the editor, so the switch answers at once and
  /// the sheet stays open — turning it off is not a reason to leave.
  void onAutoProgressionChanged(bool value) {
    setState(() => _autoProgression = value);
    widget.onAutoProgressionChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    void pick(_ItemAction action) => Navigator.of(context).pop(action);

    return SheetShell(
      title: title,
      sub: subtitle,
      showClose: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SurfaceCard(
              clip: true,
              child: Column(
                children: [
                  if (isProgression)
                    _MenuRow(
                      label: 'Edit progression',
                      onTap: () => pick(_ItemAction.editProgression),
                    ),
                  _MenuRow(
                    label: 'Reorder exercises',
                    enabled: canReorder,
                    withDivider: isProgression,
                    onTap: () => pick(_ItemAction.reorder),
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
            const SizedBox(height: 12),
            SurfaceCard(
              child: _AutoProgressionRow(
                enabled: autoProgressionEditable,
                value: autoProgression,
                onChanged: onAutoProgressionChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auto progression, stated rather than buried: what Forma does to this
/// exercise between sessions, and — for a reps × weight accessory — the
/// switch that stops it.
class _AutoProgressionRow extends StatelessWidget {
  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AutoProgressionRow({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto progression',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color:
                        enabled ? AppColors.textPrimary : AppColors.textMuted,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Forma automatically manages your reps and weight as you '
                  'progress.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeTrackColor: AppColors.accentPrimary,
            onChanged: enabled ? onChanged : null,
          ),
        ],
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
              'Add accessory exercise',
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
