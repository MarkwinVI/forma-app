import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../progress/skill_wheel_bundle.dart';
import '../progress/widgets/skill_wheel.dart';
import '../progress/widgets/skill_wheel_screen.dart';
import 'progression_toast.dart';

/// The Program tab's door into the skill trees: the same radial wheel the
/// Progress tab shows, plus the verbs — start a progression at a node, move
/// it to another node, or stop training a tree. Every change lands with a
/// receipt toast and UNDO.
class ProgramSkillWheelView extends StatefulWidget {
  /// Fly straight into this tree on open.
  final String? initialCategoryId;

  const ProgramSkillWheelView({super.key, this.initialCategoryId});

  @override
  State<ProgramSkillWheelView> createState() => _ProgramSkillWheelViewState();
}

class _ProgramSkillWheelViewState extends State<ProgramSkillWheelView> {
  final _progressService = ProgressService();
  final _skillTrackService = SkillTrackService();

  bool _loading = true;
  SkillWheelBundle? _bundle;

  ProgressionToastData? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
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

  void _showToast(ProgressionToastData data) {
    _toastTimer?.cancel();
    setState(() => _toast = data);
    _toastTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _undo(ProgressionToastData toast) async {
    _toastTimer?.cancel();
    setState(() => _toast = null);
    try {
      await toast.onUndo?.call();
    } catch (error, stackTrace) {
      debugPrint('Failed to undo progression change: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't undo that change.")),
        );
      }
    }
    await _load();
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
  /// before it become skipped (mastered ones stay mastered); every step
  /// after it locks again — so jumping ahead skips, and stepping back onto
  /// a cleared node re-locks what follows.
  Future<void> _trainNode(WheelFamily family, WheelNode node) async {
    final userId = AuthService().currentUser?.id;
    final bundle = _bundle;
    final category = SkillCategoryCatalog.findById(family.categoryId);
    if (userId == null || bundle == null || category == null) return;

    final track = _trackFor(category.id);
    final wasRunning = track?.included ?? false;
    final branchId = _branchOf(family, node, category);
    final path = category.pathFor(branchId);
    final idx = path.indexOf(node.exerciseId);
    if (idx < 0) return;

    final oldActiveName = wasRunning
        ? family.flat[family.activeFlatIndex].name
        : null;

    // Snapshot for UNDO: every status this write can touch, plus the track.
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
              : ExerciseStatus.skipped)
          : i == idx
              ? ExerciseStatus.active
              : ExerciseStatus.inactive;
    }
    // A working step left behind on another branch stops being active —
    // one tree trains one exercise.
    for (final id in touchable) {
      if (!desired.containsKey(id) && before[id] == ExerciseStatus.active) {
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

    Future<void> undo() async {
      for (final entry in desired.entries) {
        if (before[entry.key] != entry.value) {
          await _progressService.upsert(userId, entry.key, before[entry.key]!);
        }
      }
      await _skillTrackService.upsertTrack(
        userId,
        skillCategoryId: category.id,
        branchId: track?.branchId ?? category.defaultTrainingPathId,
        included: wasRunning,
      );
    }

    await _load();
    if (!mounted) return;

    if (!wasRunning) {
      _showToast(ProgressionToastData(
        kind: ProgressionToastKind.started,
        title: '${node.name} added to your workouts',
        sub: 'Your current ${family.title} exercise — it advances with '
            'the tree.',
        subBold: [family.title],
        onUndo: undo,
      ));
    } else {
      _showToast(ProgressionToastData(
        kind: ProgressionToastKind.moved,
        outName: oldActiveName,
        inName: node.name,
        sub: 'Swapped in your workouts · the ${family.title} tree now '
            'trains this.',
        subBold: [family.title],
        onUndo: undo,
      ));
    }
  }

  /// Stops the tree's progression: the track pauses, its exercise leaves
  /// future workouts, every status stays put.
  Future<void> _stopTraining(WheelFamily family) async {
    final userId = AuthService().currentUser?.id;
    final track = _trackFor(family.categoryId);
    if (userId == null || track == null || !track.included) return;

    final exerciseName = family.flat[family.activeFlatIndex].name;

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

    await _load();
    if (!mounted) return;

    _showToast(ProgressionToastData(
      kind: ProgressionToastKind.stopped,
      title: '$exerciseName removed from your workouts',
      sub: 'The ${family.title} tree is now inactive · your progress '
          'is saved.',
      subBold: [family.title],
      onUndo: () => _skillTrackService.setIncluded(
        userId,
        family.categoryId,
        included: true,
      ),
    ));
  }

  void _openExercise(WheelNode node) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    if (exercise == null) return;
    Navigator.of(context).push(
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
    final toast = _toast;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : bundle == null || bundle.families.isEmpty
                ? const SizedBox.shrink()
                : Stack(
                    children: [
                      SkillWheelScreen(
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
                      ),
                      if (toast != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 56,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, child) => Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, -8 * (1 - t)),
                                child: child,
                              ),
                            ),
                            child: ProgressionToast(
                              data: toast,
                              onUndoTap: () => _undo(toast),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
