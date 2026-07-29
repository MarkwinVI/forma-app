import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/skill_tree_map.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../exercises/exercise_detail_view.dart';

/// One tree, one map, one list. The map is pinned at the top and is the only
/// navigation: tapping a route scrolls the list to it, and scrolling the list
/// lights up whichever route you have reached. Every route — the shared
/// foundation and each branch — lives in the same continuous scroll.
class SkillTreeView extends StatefulWidget {
  final String skillCategoryId;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(String exerciseId, ExerciseStatus status)
      onProgressChanged;

  const SkillTreeView({
    super.key,
    required this.skillCategoryId,
    required this.progressMap,
    required this.onProgressChanged,
  });

  @override
  State<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends State<SkillTreeView> {
  /// How far below the list's top edge a section has to sit before the map
  /// counts it as the one you are reading.
  static const double _selectionLine = 34;

  final _listKey = GlobalKey();
  final _sectionKeys = <String, GlobalKey>{};

  late SkillCategory _skillCategory;
  late Map<String, ExerciseStatus> _localProgress;
  late String _selectedRouteId;

  /// A tap on the map animates the list; scroll events are ignored until it
  /// settles, so the two can't fight over the selection.
  DateTime _jumpSettlesAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _skillCategory = SkillCategoryCatalog.findById(widget.skillCategoryId) ??
        SkillCategoryCatalog.defaultForTrack(ExerciseCategory.verticalPull);
    _localProgress = Map.from(widget.progressMap);
    _selectedRouteId = _routes.first.id;
  }

  // ── The routes through this tree ──────────────────────────────────────────

  List<String> get _pathIds => _skillCategory.trainingPaths.isNotEmpty
      ? _skillCategory.trainingPaths.keys.toList()
      : const ['main'];

  /// The opening steps every branch shares — the tree's foundation.
  List<String> get _sharedFoundationExerciseIds {
    if (_pathIds.length < 2) return const [];
    final lists = _pathIds
        .map((pathId) =>
            _skillCategory.trainingPaths[pathId] ?? const <String>[])
        .toList();
    if (lists.any((list) => list.isEmpty)) return const [];

    final shared = <String>[];
    final shortest =
        lists.map((list) => list.length).reduce((a, b) => a < b ? a : b);
    for (var index = 0; index < shortest; index++) {
      final candidate = lists.first[index];
      if (lists.every((list) => list[index] == candidate)) {
        shared.add(candidate);
      } else {
        break;
      }
    }
    return shared;
  }

  bool get _hasFoundation => _sharedFoundationExerciseIds.isNotEmpty;

  String _pathLabel(String pathId) {
    if (_skillCategory.id == SkillCategoryCatalog.pullupsId &&
        pathId == 'close_grip') {
      return 'High Pull-up';
    }
    for (final branch in _skillCategory.branches) {
      if (branch.id == pathId) return branch.label;
    }
    return pathId
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<Exercise> _exercisesFor(List<String> ids) =>
      ids.map(ExerciseCatalog.findById).whereType<Exercise>().toList();

  List<_TreeRoute> get _routes {
    final foundationIds = _sharedFoundationExerciseIds;
    final routes = <_TreeRoute>[];

    if (foundationIds.isNotEmpty) {
      routes.add(_TreeRoute(
        id: SkillTreeMap.foundationRouteId,
        name: 'Foundation',
        exercises: _exercisesFor(foundationIds),
        isFoundation: true,
      ));
    }

    final unlockAfter = foundationIds.isEmpty
        ? null
        : ExerciseCatalog.findById(foundationIds.last)?.name;

    for (final pathId in _pathIds) {
      final ids = _skillCategory.trainingPaths.isEmpty
          ? ExerciseCatalog.forSkillCategory(_skillCategory.id)
              .map((exercise) => exercise.id)
              .toList()
          : List<String>.from(
              _skillCategory.trainingPaths[pathId] ?? const <String>[],
            );
      final exercises = _exercisesFor(ids.skip(foundationIds.length).toList());
      if (exercises.isEmpty) continue;
      routes.add(_TreeRoute(
        id: pathId,
        // A tree with one straight path has no branch to name.
        name: _pathIds.length > 1 ? _pathLabel(pathId) : 'Progression',
        exercises: exercises,
        isFoundation: false,
        unlockAfter: unlockAfter,
      ));
    }

    if (routes.isEmpty) {
      routes.add(_TreeRoute(
        id: 'main',
        name: 'Progression',
        exercises: ExerciseCatalog.forSkillCategory(_skillCategory.id),
        isFoundation: false,
      ));
    }
    return routes;
  }

  ExerciseStatus _statusOf(Exercise exercise) =>
      _localProgress[exercise.id] ?? ExerciseStatus.inactive;

  /// A branch stays shut until every foundation step is cleared — mastered,
  /// or skipped when setup started the user past it.
  bool _routeIsOpen(_TreeRoute route) {
    if (route.isFoundation || !_hasFoundation) return true;
    return _sharedFoundationExerciseIds.every(
      (exerciseId) => _localProgress[exerciseId]?.isCleared ?? false,
    );
  }

  int _masteredCount(_TreeRoute route) => route.exercises
      .where((exercise) => _statusOf(exercise).isCleared)
      .length;

  // ── Selection ↔ scroll ────────────────────────────────────────────────────

  void _syncSelectionToScroll() {
    if (DateTime.now().isBefore(_jumpSettlesAt)) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;

    final line = listBox.localToGlobal(Offset.zero).dy + _selectionLine;
    var reached = _routes.first.id;
    for (final route in _routes) {
      final context = _sectionKeys[route.id]?.currentContext;
      final box = context?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy <= line) reached = route.id;
    }
    if (reached != _selectedRouteId) {
      setState(() => _selectedRouteId = reached);
    }
  }

  void _jumpToRoute(String routeId) {
    setState(() => _selectedRouteId = routeId);
    _jumpSettlesAt = DateTime.now().add(const Duration(milliseconds: 700));
    final context = _sectionKeys[routeId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  /// Tapping a step opens the exercise itself. The preview sheet used to sit
  /// in between, but everything it showed the detail view shows too, so it
  /// only cost a tap.
  void _openExercise(Exercise exercise) {
    openExerciseDetailView<void>(
      context,
      exercise: exercise,
      accentColor: AppColors.accentBright,
      skillCategoryId: _skillCategory.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = _routes;
    for (final route in routes) {
      _sectionKeys.putIfAbsent(route.id, GlobalKey.new);
    }

    // One reading of the tree for the whole screen — the map draws it and
    // the routes below list it, so they cannot disagree about which step you
    // are on.
    final nodeStates = skillTreeNodeStates(
      category: _skillCategory,
      progressMap: _localProgress,
      goalBranchId: _goalBranchId(routes),
    );

    final unlockRequirement = _skillCategory.unlockRequirement;
    final isLocked = unlockRequirement != null &&
        _localProgress[unlockRequirement.exerciseId] != ExerciseStatus.mastered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _LockNotice(
                  message: unlockRequirement.message,
                  ctaLabel: unlockRequirement.ctaLabel,
                  onOpenRequiredTree: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SkillTreeView(
                          skillCategoryId:
                              unlockRequirement.targetSkillCategoryId,
                          progressMap: _localProgress,
                          onProgressChanged: (id, status) {
                            setState(() => _localProgress[id] = status);
                            widget.onProgressChanged(id, status);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            _buildMap(routes),
            Expanded(
              child: AbsorbPointer(
                absorbing: isLocked,
                child: Opacity(
                  opacity: isLocked ? 0.45 : 1,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification ||
                          notification is ScrollEndNotification) {
                        _syncSelectionToScroll();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      key: _listKey,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final route in routes)
                            _RouteSection(
                              key: _sectionKeys[route.id],
                              route: route,
                              first: route == routes.first,
                              selected: route.id == _selectedRouteId,
                              open: _routeIsOpen(route),
                              masteredCount: _masteredCount(route),
                              stateOf: (exercise) =>
                                  nodeStates[exercise.id] ??
                                  TreeNodeState.locked,
                              statusOf: _statusOf,
                              onExerciseTap: _openExercise,
                            ),
                          // Room to scroll the last route up to the line.
                          const SizedBox(height: 320),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _skillCategory.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
    );
  }

  /// The branch the tree is read against — whichever route you are looking
  /// at, or the default when that is the shared foundation. The map and the
  /// list must agree on this or they disagree about which step is current.
  String _goalBranchId(List<_TreeRoute> routes) {
    final branchRouteIds = {
      for (final route in routes)
        if (!route.isFoundation) route.id,
    };
    return branchRouteIds.contains(_selectedRouteId)
        ? _selectedRouteId
        : _skillCategory.defaultTrainingPathId;
  }

  Widget _buildMap(List<_TreeRoute> routes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SkillTreeMap(
        viz: TreeVizModel.fromCategory(
          category: _skillCategory,
          progressMap: _localProgress,
          activeBranchId: _goalBranchId(routes),
        ),
        maxHeight: 210,
        selectedRouteId: _selectedRouteId,
        labelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.14,
        ),
        onBranchTap: (branch) => _jumpToRoute(branch.id),
        onFoundationTap: () => _jumpToRoute(routes.first.id),
      ),
    );
  }
}

/// One route through the tree — the shared foundation, or a branch past it.
class _TreeRoute {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final bool isFoundation;
  final String? unlockAfter;

  const _TreeRoute({
    required this.id,
    required this.name,
    required this.exercises,
    required this.isFoundation,
    this.unlockAfter,
  });
}

/// Where an exercise stands in its route — the list's reading of the states
/// the map draws: cleared, being trained, open to train, or still shut.
enum _StepState { done, skipped, now, unlocked, locked }

extension on _StepState {
  /// Skipped steps are cleared — green, and the path runs past them — but
  /// they were never trained here, so they never claim mastery.
  bool get isCleared => this == _StepState.done || this == _StepState.skipped;

  String get label => switch (this) {
        _StepState.done => 'Mastered',
        _StepState.skipped => 'Skipped',
        _StepState.now => 'Active',
        _StepState.unlocked => 'Unlocked',
        _StepState.locked => 'Locked',
      };

  Color get color => switch (this) {
        _StepState.done => AppColors.green,
        _StepState.skipped => AppColors.green,
        _StepState.now => AppColors.accentBright,
        _StepState.unlocked => AppColors.textSecondary,
        _StepState.locked => AppColors.textMuted,
      };
}

/// A route's heading and its steps. Unselected sections stay legible but step
/// back, so the selected one reads as where you are.
class _RouteSection extends StatelessWidget {
  final _TreeRoute route;
  final bool first;
  final bool selected;
  final bool open;
  final int masteredCount;
  final TreeNodeState Function(Exercise exercise) stateOf;
  final ExerciseStatus Function(Exercise exercise) statusOf;
  final void Function(Exercise exercise) onExerciseTap;

  const _RouteSection({
    super.key,
    required this.route,
    required this.first,
    required this.selected,
    required this.open,
    required this.masteredCount,
    required this.stateOf,
    required this.statusOf,
    required this.onExerciseTap,
  });

  _StepState _stateFor(int index) {
    final exercise = route.exercises[index];
    return switch (stateOf(exercise)) {
      // The map draws cleared steps one way; only this list distinguishes a
      // step you mastered from one program setup started you past.
      TreeNodeState.done =>
        statusOf(exercise) == ExerciseStatus.skipped
            ? _StepState.skipped
            : _StepState.done,
      TreeNodeState.cur => _StepState.now,
      TreeNodeState.unlocked => _StepState.unlocked,
      TreeNodeState.locked => _StepState.locked,
    };
  }

  String? get _subtitle {
    if (route.isFoundation) {
      return 'Master to unlock more advanced exercises';
    }
    return open ? null : 'Master foundation to unlock';
  }

  @override
  Widget build(BuildContext context) {
    final total = route.exercises.length;
    final subtitle = _subtitle;

    return Padding(
      padding: EdgeInsets.only(top: first ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.44,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          // Only routes that need explaining get a line: the foundation says
          // what finishing it buys, a shut branch says what opens it, and an
          // open branch speaks for itself.
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: selected ? AppColors.textSecondary : AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Opacity(
            opacity: selected ? 1 : 0.62,
            child: Column(
              children: [
                for (var index = 0; index < total; index++)
                  _ExerciseRow(
                    exercise: route.exercises[index],
                    state: _stateFor(index),
                    // The rail entering a step is coloured by the step above
                    // it, so a cleared stretch reads as one line — the same
                    // rule the map's segments follow.
                    previousState: index == 0 ? null : _stateFor(index - 1),
                    last: index == total - 1,
                    onTap: () => onExerciseTap(route.exercises[index]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One step: the rail node on the left, the name and its state on the right.
/// Only the step you are on explains itself.
class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final _StepState state;
  final _StepState? previousState;
  final bool last;
  final VoidCallback onTap;

  const _ExerciseRow({
    required this.exercise,
    required this.state,
    required this.previousState,
    required this.last,
    required this.onTap,
  });

  static Color _railColor(_StepState? from) => (from?.isCleared ?? false)
      ? AppColors.green.withValues(alpha: 0.4)
      : AppColors.divider;

  Widget _buildNode() {
    switch (state) {
      case _StepState.done:
      case _StepState.skipped:
        return Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green,
          ),
        );
      case _StepState.now:
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBright,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBright.withValues(alpha: 0.25),
                spreadRadius: 4,
              ),
            ],
          ),
        );
      case _StepState.unlocked:
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface3, width: 2),
          ),
        );
      case _StepState.locked:
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface3,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDescription = state == _StepState.now;

    return Pressable(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  Container(
                    height: 21,
                    width: 1.5,
                    color: _railColor(previousState),
                  ),
                  _buildNode(),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        constraints: const BoxConstraints(minHeight: 12),
                        color: _railColor(state),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 15, 0, 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.25,
                              height: 1.25,
                              color: state == _StepState.locked
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            state.label.toUpperCase(),
                            style: GoogleFonts.robotoMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: state == _StepState.locked
                                  ? AppColors.textMuted
                                  : state.color,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 1, left: 2),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (showDescription && exercise.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          exercise.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockNotice extends StatelessWidget {
  final String message;
  final String? ctaLabel;
  final VoidCallback? onOpenRequiredTree;

  const _LockNotice({
    required this.message,
    this.ctaLabel,
    this.onOpenRequiredTree,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Locked',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.accentBright,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onOpenRequiredTree,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentBright,
              side: BorderSide(
                color: AppColors.accentPrimary.withValues(alpha: 0.45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            child: Text(
              ctaLabel ?? 'Open Required Tree',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
