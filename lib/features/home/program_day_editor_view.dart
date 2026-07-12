import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import 'program_day_items.dart';

/// Full-page editor for one training day: a flat exercise list with
/// remove, reorder, per-exercise set volume, and a two-step add flow
/// (skill path with one active branch per tree, or a single lift).
class ProgramDayEditorView extends StatefulWidget {
  final TrainingSessionType sessionType;
  final TrainingProgramType programType;
  final Map<TrainingTrack, String> branchSelections;
  final Map<String, ExerciseStatus> progressMap;
  final Map<String, dynamic> sessionItemsConfig;
  final Future<void> Function(Map<String, dynamic> sessionItemsConfig) onSave;

  const ProgramDayEditorView({
    super.key,
    required this.sessionType,
    required this.programType,
    required this.branchSelections,
    required this.progressMap,
    required this.sessionItemsConfig,
    required this.onSave,
  });

  @override
  State<ProgramDayEditorView> createState() => _ProgramDayEditorViewState();
}

class _ProgramDayEditorViewState extends State<ProgramDayEditorView> {
  final _programService = TrainingProgramService();

  late List<ProgramDayItem> _items;
  late String _initialSerialized;
  String? _expandedId;
  bool _saving = false;

  String get _dayTitle => programDayTitle(widget.sessionType);

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
    );
    _initialSerialized = _serialized();
  }

  String _serialized() => jsonEncode(ProgramSessionPlan.serializeDay(_items));

  bool get _dirty => _serialized() != _initialSerialized;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final config = Map<String, dynamic>.from(widget.sessionItemsConfig);
    config[widget.sessionType.dbValue] =
        ProgramSessionPlan.serializeDay(_items);

    try {
      await widget.onSave(config);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save $_dayTitle day: $error')),
      );
      setState(() => _saving = false);
    }
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
      if (_expandedId == id) _expandedId = null;
    });
  }

  void _patchItem(String id, {int? sets, String? reps}) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _items[index] = _items[index].copyWith(sets: sets, reps: reps);
    });
  }

  /// One active branch per skill tree per day: picking a new branch replaces
  /// the tree's current one in place; picking the active one removes it.
  void _pickBranch(SkillCategory category, SkillCategoryBranch branch) {
    setState(() {
      final index = _items.indexWhere(
        (item) =>
            item.kind == ProgramDayItemKind.progression &&
            item.skillCategoryId == category.id,
      );

      if (index >= 0 && _items[index].branchId == branch.id) {
        _items.removeAt(index);
        return;
      }

      final current = ProgramSessionPlan.currentExerciseForPath(
        skillCategoryId: category.id,
        branchId: branch.id,
        progressMap: widget.progressMap,
      );
      final item = ProgramDayItem(
        id: newProgramItemId(),
        kind: ProgramDayItemKind.progression,
        name: current?.name ??
            '${programBranchLabel(category, branch)} ${category.title}',
        skillCategoryId: category.id,
        branchId: branch.id,
        exerciseId: current?.id,
      );

      if (index >= 0) {
        _items[index] = item;
      } else {
        _items.add(item);
      }
    });
  }

  void _toggleLift(Exercise exercise) {
    setState(() {
      final index = _items.indexWhere(
        (item) =>
            item.kind == ProgramDayItemKind.exercise &&
            item.exerciseId == exercise.id,
      );
      if (index >= 0) {
        _items.removeAt(index);
      } else {
        _items.add(
          ProgramDayItem(
            id: newProgramItemId(),
            kind: ProgramDayItemKind.exercise,
            name: exercise.name,
            exerciseId: exercise.id,
          ),
        );
      }
    });
  }

  Future<void> _openAddPicker() async {
    setState(() => _expandedId = null);
    final kind = await showModalBottomSheet<_PickerKind>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _AddKindSheet(dayTitle: _dayTitle),
    );
    if (kind == null || !mounted) return;

    if (kind == _PickerKind.path) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _SkillTreePickerPage(
            dayTitle: _dayTitle,
            progressMap: widget.progressMap,
            items: () => _items,
            onPickBranch: _pickBranch,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _LiftPickerPage(
            items: () => _items,
            onToggleLift: _toggleLift,
          ),
        ),
      );
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_dayTitle day',
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${_items.length} exercises · hold ≡ to reorder',
              style: const TextStyle(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SurfaceCard(
                      clip: true,
                      child: Column(
                        children: [
                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                'Nothing planned for $_dayTitle yet — add your first exercise below.',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: _items.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final item = _items.removeAt(oldIndex);
                                  _items.insert(newIndex, item);
                                });
                              },
                              proxyDecorator: (child, _, __) => Material(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(14),
                                child: child,
                              ),
                              itemBuilder: (context, index) => _buildItemRow(
                                index,
                                _items[index],
                              ),
                            ),
                          _AddExerciseRow(
                            withDivider: _items.isNotEmpty,
                            onTap: _openAddPicker,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(2, 10, 2, 0),
                      child: Text(
                        'Tap the sets pill to adjust volume. Removing a skill path pauses it — progress is kept.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 52,
                      child: Center(child: LoadingIndicator()),
                    )
                  : PillButton(
                      label: dirty ? 'Save $_dayTitle day' : 'No changes yet',
                      onTap: dirty ? _save : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, ProgramDayItem item) {
    final open = _expandedId == item.id;
    final isPath = item.kind == ProgramDayItemKind.progression;

    return Container(
      key: ValueKey(item.id),
      decoration: BoxDecoration(
        color: open ? AppColors.cardHighlight : Colors.transparent,
        border: index > 0
            ? const Border(top: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: Row(
              children: [
                const SizedBox(width: 16),
                IconTile(icon: programPatternIcon(item.category), size: 38),
                const SizedBox(width: 11),
                Expanded(
                  child: Pressable(
                    onTap: () => setState(
                      () => _expandedId = open ? null : item.id,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
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
                          _itemSubtitle(item),
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
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: () => setState(
                    () => _expandedId = open ? null : item.id,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: open ? AppColors.accentSoft : AppColors.surface2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      isPath
                          ? '${item.sets} sets'
                          : '${item.sets} × ${item.reps}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: open
                            ? AppColors.accentPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.surface2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.remove_rounded,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox(
                    width: 40,
                    height: 44,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 19,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (open) _buildItemConfig(item),
        ],
      ),
    );
  }

  Widget _buildItemConfig(ProgramDayItem item) {
    final isPath = item.kind == ProgramDayItemKind.progression;

    return Padding(
      padding: const EdgeInsets.fromLTRB(65, 0, 18, 15),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sets',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _patchItem(
                    item.id,
                    sets: item.sets > 1 ? item.sets - 1 : 1,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${item.sets}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () => _patchItem(
                    item.id,
                    sets: item.sets < 6 ? item.sets + 1 : 6,
                  ),
                ),
              ],
            ),
          ),
          if (isPath)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Reps follow your level on this path — Forma sets them each session.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reps',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  for (final option in kProgramRepOptions) ...[
                    const SizedBox(width: 5),
                    Pressable(
                      onTap: () => _patchItem(item.id, reps: option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.reps == option
                              ? AppColors.accentSoft
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: item.reps == option
                                ? AppColors.accentPrimary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: item.reps == option
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _itemSubtitle(ProgramDayItem item) {
    if (item.kind == ProgramDayItemKind.progression) {
      final category = item.skillCategoryId == null
          ? null
          : SkillCategoryCatalog.findById(item.skillCategoryId!);
      if (category != null) {
        final branch = category.branches.firstWhere(
          (candidate) => candidate.id == item.branchId,
          orElse: () => category.branches.first,
        );
        return '${programBranchLabel(category, branch)} '
            '${category.title.toLowerCase()} · advances automatically';
      }
      return 'Skill path · advances automatically';
    }
    return programPatternLabel(item.category);
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: AppColors.textPrimary),
      ),
    );
  }
}

class _AddExerciseRow extends StatelessWidget {
  final bool withDivider;
  final VoidCallback onTap;

  const _AddExerciseRow({required this.withDivider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: withDivider
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 14,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Add exercise',
              style: TextStyle(
                fontSize: 14.5,
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

enum _PickerKind { path, fixed }

/// Step 1 of the add flow: pick what kind of exercise to add. Selecting a
/// kind closes the sheet and opens a full-page picker.
class _AddKindSheet extends StatelessWidget {
  final String dayTitle;

  const _AddKindSheet({required this.dayTitle});

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        kind: _PickerKind.path,
        icon: Icons.route_rounded,
        label: 'Skill path',
        sub:
            'Advances automatically as you level up — one path, many progressions',
      ),
      (
        kind: _PickerKind.fixed,
        icon: Icons.fitness_center,
        label: 'Single lift',
        sub: 'One fixed exercise — you progress by load and reps',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to $dayTitle',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'What kind of exercise?',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                for (final option in options)
                  Pressable(
                    onTap: () => Navigator.of(context).pop(option.kind),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconTile(
                            icon: option.icon,
                            size: 44,
                            tint: option.kind == _PickerKind.path,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  option.sub,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

AppBar _pickerAppBar(
  BuildContext context, {
  required String title,
  required String sub,
}) {
  return AppBar(
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
    titleSpacing: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

/// Full-page list of skill trees; tapping one opens its branches.
class _SkillTreePickerPage extends StatefulWidget {
  final String dayTitle;
  final Map<String, ExerciseStatus> progressMap;
  final List<ProgramDayItem> Function() items;
  final void Function(SkillCategory category, SkillCategoryBranch branch)
      onPickBranch;

  const _SkillTreePickerPage({
    required this.dayTitle,
    required this.progressMap,
    required this.items,
    required this.onPickBranch,
  });

  @override
  State<_SkillTreePickerPage> createState() => _SkillTreePickerPageState();
}

class _SkillTreePickerPageState extends State<_SkillTreePickerPage> {
  List<SkillCategory> get _trees => SkillCategoryCatalog.browsable()
      .where((category) => _selectableBranches(category).isNotEmpty)
      .toList();

  List<SkillCategoryBranch> _selectableBranches(SkillCategory category) {
    return category.branches
        .where((branch) => category.pathFor(branch.id).isNotEmpty)
        .toList();
  }

  bool _treeAdded(SkillCategory category) {
    return widget.items().any(
          (item) =>
              item.kind == ProgramDayItemKind.progression &&
              item.skillCategoryId == category.id,
        );
  }

  Future<void> _openBranches(SkillCategory category) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BranchPickerPage(
          dayTitle: widget.dayTitle,
          category: category,
          progressMap: widget.progressMap,
          items: widget.items,
          onPickBranch: widget.onPickBranch,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _pickerAppBar(
        context,
        title: 'Choose a skill tree',
        sub: 'Each tree has branches you can train',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            for (final category in _trees)
              Builder(builder: (context) {
                final branches = _selectableBranches(category);
                final added = _treeAdded(category);
                return Pressable(
                  onTap: () => _openBranches(category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        IconTile(
                          icon: programPatternIcon(category.track),
                          size: 40,
                          tint: added,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${branches.length} branch${branches.length > 1 ? 'es' : ''} · ${programPatternLabel(category.track)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (added)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Text(
                              'Added',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentPrimary,
                              ),
                            ),
                          ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Full-page branch list for one skill tree. One branch can be active per
/// day — picking another switches it in place.
class _BranchPickerPage extends StatefulWidget {
  final String dayTitle;
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;
  final List<ProgramDayItem> Function() items;
  final void Function(SkillCategory category, SkillCategoryBranch branch)
      onPickBranch;

  const _BranchPickerPage({
    required this.dayTitle,
    required this.category,
    required this.progressMap,
    required this.items,
    required this.onPickBranch,
  });

  @override
  State<_BranchPickerPage> createState() => _BranchPickerPageState();
}

class _BranchPickerPageState extends State<_BranchPickerPage> {
  ProgramDayItem? get _active {
    for (final item in widget.items()) {
      if (item.kind == ProgramDayItemKind.progression &&
          item.skillCategoryId == widget.category.id) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final branches = category.branches
        .where((branch) => category.pathFor(branch.id).isNotEmpty)
        .toList();
    final active = _active;
    SkillCategoryBranch? activeBranch;
    if (active != null) {
      for (final branch in branches) {
        if (branch.id == active.branchId) {
          activeBranch = branch;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _pickerAppBar(
        context,
        title: category.title,
        sub: 'One branch active per day',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            for (final branch in branches)
              Builder(builder: (context) {
                final on = active?.branchId == branch.id;
                final willSwitch = !on && active != null;
                final current = ProgramSessionPlan.currentExerciseForPath(
                  skillCategoryId: category.id,
                  branchId: branch.id,
                  progressMap: widget.progressMap,
                );
                final sub = willSwitch && activeBranch != null
                    ? 'Now: ${current?.name ?? '—'} · switches from ${programBranchLabel(category, activeBranch)}'
                    : 'Now: ${current?.name ?? '—'}';

                return Pressable(
                  onTap: () {
                    widget.onPickBranch(category, branch);
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: on ? AppColors.accentSoft : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            on ? AppColors.accentPrimary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconTile(
                          icon: programPatternIcon(category.track),
                          size: 38,
                          tint: on,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                programBranchLabel(category, branch),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BranchTrailing(on: on, willSwitch: willSwitch),
                      ],
                    ),
                  ),
                );
              }),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
              child: Text(
                'One active branch per ${widget.dayTitle} day — picking another switches it. Paused branches keep their progress.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page searchable list of single lifts. Tapping toggles them on the
/// day being edited.
class _LiftPickerPage extends StatefulWidget {
  final List<ProgramDayItem> Function() items;
  final void Function(Exercise exercise) onToggleLift;

  const _LiftPickerPage({
    required this.items,
    required this.onToggleLift,
  });

  @override
  State<_LiftPickerPage> createState() => _LiftPickerPageState();
}

class _LiftPickerPageState extends State<_LiftPickerPage> {
  String _query = '';

  bool _liftAdded(Exercise exercise) {
    return widget.items().any(
          (item) =>
              item.kind == ProgramDayItemKind.exercise &&
              item.exerciseId == exercise.id,
        );
  }

  /// Lowercase and drop separators so "pullup" matches "Pull-Up" / "Pull Up".
  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<Exercise> get _lifts {
    final tokens = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(_normalize)
        .where((token) => token.isNotEmpty)
        .toList();

    final lifts = ExerciseCatalog.all().where((exercise) {
      if (tokens.isEmpty) return true;
      final haystack = _normalize(
        '${exercise.name} ${programPatternLabel(exercise.category)}',
      );
      return tokens.every(haystack.contains);
    }).toList();

    final queryNorm = _normalize(_query);
    int rank(Exercise exercise) =>
        queryNorm.isNotEmpty && _normalize(exercise.name).startsWith(queryNorm)
            ? 0
            : 1;
    lifts.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.name.compareTo(b.name);
    });
    return lifts;
  }

  @override
  Widget build(BuildContext context) {
    final lifts = _lifts;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _pickerAppBar(
        context,
        title: 'Add a single lift',
        sub: 'Tap to add or remove',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        cursorColor: AppColors.accentPrimary,
                        decoration: const InputDecoration(
                          hintText: 'Search lifts…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: lifts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'No lifts match “${_query.trim()}”.',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      itemCount: lifts.length,
                      itemBuilder: (context, index) {
                        final exercise = lifts[index];
                        final on = _liftAdded(exercise);
                        return Pressable(
                          onTap: () {
                            widget.onToggleLift(exercise);
                            setState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: on
                                  ? AppColors.accentSoft
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: on
                                    ? AppColors.accentPrimary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                IconTile(
                                  icon: programPatternIcon(exercise.category),
                                  size: 36,
                                  tint: on,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        programPatternLabel(
                                            exercise.category),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _CheckCircle(on: on),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchTrailing extends StatelessWidget {
  final bool on;
  final bool willSwitch;

  const _BranchTrailing({required this.on, required this.willSwitch});

  @override
  Widget build(BuildContext context) {
    if (willSwitch) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.8,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.swap_horiz_rounded,
          size: 13,
          color: AppColors.textSecondary,
        ),
      );
    }
    return _CheckCircle(on: on);
  }
}

class _CheckCircle extends StatelessWidget {
  final bool on;

  const _CheckCircle({required this.on});

  @override
  Widget build(BuildContext context) {
    if (on) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.accentPrimary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.8,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.add_rounded,
        size: 13,
        color: AppColors.textSecondary,
      ),
    );
  }
}
