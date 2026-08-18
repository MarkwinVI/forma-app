
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../progress/skill_wheel_bundle.dart';
import '../progress/widgets/skill_wheel.dart';
import '../progress/widgets/skill_wheel_screen.dart';

/// The Program tab's door into the skill trees: the same radial wheel the
/// Progress tab shows, plus the verbs — start a progression at a node, move
/// it to another node, or stop training a tree. Every change lands with a
/// receipt toast and UNDO.
class ProgramSkillWheelView extends StatefulWidget {
  /// Fly straight into this tree on open.
  final String? initialCategoryId;

  /// Backing out of the tree pops this whole view instead of pulling out to
  /// the wheel overview — for hosts (the workout editor) where the wheel
  /// would be a detour on the way back.
  final bool exitOnTreeBack;

  const ProgramSkillWheelView({
    super.key,
    this.initialCategoryId,
    this.exitOnTreeBack = false,
  });

  @override
  State<ProgramSkillWheelView> createState() => _ProgramSkillWheelViewState();
}

class _ProgramSkillWheelViewState extends State<ProgramSkillWheelView> {
  final _progressService = ProgressService();
  final _skillTrackService = SkillTrackService();

  bool _loading = true;
  SkillWheelBundle? _bundle;


  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final bundle = await loadSkillWheelBundle(userId);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load skill trees: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load your skill trees. Try again later."),
        ),
      );
    }
  }

  SkillTrack? _trackFor(String categoryId) {
    for (final track in _bundle?.skillTracks ?? const <SkillTrack>[]) {
      if (track.skillCategoryId == categoryId) return track;
    }
    return null;
  }

  /// The branch a node sits on: its own branch for a branch step, the
  /// track's current aim (or the default path) for a shared foundation step.
  String _branchOf(WheelFamily family, WheelNode node, SkillCategory category) {
    for (final branch in family.branches) {
      for (final step in branch.steps) {
        if (step.exerciseId == node.exerciseId) return branch.id;
      }
    }
    return _trackFor(category.id)?.branchId ?? category.defaultTrainingPathId;
  }

  /// Every exercise the category can reach, across all of its branches —
  /// the set a progression move must keep consistent.
  Set<String> _allCategoryExerciseIds(SkillCategory category) => {
        for (final branch in category.branches)
          ...category.pathFor(branch.id),
      };

  /// Makes [node] the trained exercise of its tree. Steps on the route
  /// before it are left exactly as they are — jumping ahead keeps the
  /// unfinished ones locked until [node] is mastered, which masters them —
  /// and every step after it locks again, so stepping back onto a cleared
  /// node re-locks what follows.
  Future<void> _trainNode(WheelFamily family, WheelNode node) async {
    final userId = AuthService().currentUser?.id;
    final bundle = _bundle;
    final category = SkillCategoryCatalog.findById(family.categoryId);
    if (userId == null || bundle == null || category == null) return;

    final branchId = _branchOf(family, node, category);
    final path = category.pathFor(branchId);
    final idx = path.indexOf(node.exerciseId);
    if (idx < 0) return;

    // Every status this write can touch, read once so the new statuses are
    // decided against one consistent picture.
    final touchable = _allCategoryExerciseIds(category);
    final before = {
      for (final id in touchable)
        id: bundle.progressMap[id] ?? ExerciseStatus.inactive,
    };

    final desired = <String, ExerciseStatus>{};
    for (var i = 0; i < path.length; i++) {
      final id = path[i];
      final existing = before[id]!;
      desired[id] = i < idx
          ? (existing == ExerciseStatus.mastered
              ? ExerciseStatus.mastered
              : ExerciseStatus.inactive)
          : i == idx
              ? ExerciseStatus.active
              : ExerciseStatus.inactive;
    }
    // A working step left behind on another branch stops being active —
    // one tree trains one exercise. And a trunk step restarts the whole
    // tree: every branch runs through it, so cleared steps on the other
    // branches re-lock too.
    final restartsTree =
        category.pathFor(category.foundationBranchId).contains(node.exerciseId);
    for (final id in touchable) {
      if (desired.containsKey(id)) continue;
      final existing = before[id]!;
      if (existing == ExerciseStatus.active ||
          (restartsTree && existing != ExerciseStatus.inactive)) {
        desired[id] = ExerciseStatus.inactive;
      }
    }

    try {
      for (final entry in desired.entries) {
        if (before[entry.key] != entry.value) {
          await _progressService.upsert(userId, entry.key, entry.value);
        }
      }
      await _skillTrackService.upsertTrack(
        userId,
        skillCategoryId: category.id,
        branchId: branchId,
        included: true,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to move progression: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save that change. Try again."),
          ),
        );
      }
      return;
    }

    AnalyticsService.capture('progression_moved', properties: {
      'skill_tree_id': category.id,
      'exercise_id': node.exerciseId,
      'branch_id': branchId,
      'step_index': idx,
      'source': _source,
    });
    await _load();
  }

  /// Stops the tree's progression: the track pauses, its exercise leaves
  /// future workouts, every status stays put.
  Future<void> _stopTraining(WheelFamily family) async {
    final userId = AuthService().currentUser?.id;
    final track = _trackFor(family.categoryId);
    if (userId == null || track == null || !track.included) return;

    try {
      await _skillTrackService.setIncluded(
        userId,
        family.categoryId,
        included: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to stop progression: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save that change. Try again."),
          ),
        );
      }
      return;
    }

    AnalyticsService.capture('progression_stopped', properties: {
      'skill_tree_id': family.categoryId,
      'source': _source,
    });
    await _load();
  }

  /// Where the user came in from — the Program tab's overview, or a
  /// workout row's Edit progression.
  String get _source =>
      widget.exitOnTreeBack ? 'workout_editor' : 'program_tab';

  void _openExercise(WheelNode node) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    if (exercise == null) return;
    AnalyticsService.capture('skill_tree_exercise_opened', properties: {
      'exercise_id': node.exerciseId,
      'node_state': node.state.name,
      if (exercise.skillCategoryId.isNotEmpty)
        'skill_tree_id': exercise.skillCategoryId,
      'source': _source,
    });
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailView(
          exercise: exercise,
          skillCategoryId: exercise.skillCategoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : bundle == null || bundle.families.isEmpty
                ? const SizedBox.shrink()
                : SkillWheelScreen(
                    families: bundle.families,
                    journeyByCategory: bundle.journeyByCategory,
                    activeCategoryIds: bundle.activeCategoryIds,
                    treeLocks: bundle.treeLocks,
                    editable: true,
                    onTrainNode: _trainNode,
                    onStopTraining: _stopTraining,
                    onOpenExercise: _openExercise,
                    onBack: () => Navigator.of(context).pop(),
                    initialCategoryId: widget.initialCategoryId,
                    exitOnTreeBack: widget.exitOnTreeBack,
                  ),
      ),
    );
  }
}
