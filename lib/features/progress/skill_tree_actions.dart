import 'package:flutter/foundation.dart';

import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import 'skill_wheel_bundle.dart';
import 'widgets/skill_wheel.dart';

/// The two edits the wheel makes to a progression — train a node, stop a
/// tree — written against a loaded [SkillWheelBundle]. The Progress tab and
/// the Program tab's wheel page share it, so editing in place and editing
/// from Program can never drift apart on what a tap writes.
class SkillTreeActions {
  final ProgressService _progressService;
  final SkillTrackService _skillTrackService;

  SkillTreeActions({
    ProgressService? progressService,
    SkillTrackService? skillTrackService,
  })  : _progressService = progressService ?? ProgressService(),
        _skillTrackService = skillTrackService ?? SkillTrackService();

  static SkillTrack? _trackFor(SkillWheelBundle bundle, String categoryId) {
    for (final track in bundle.skillTracks) {
      if (track.skillCategoryId == categoryId) return track;
    }
    return null;
  }

  /// The branch a node sits on: its own branch for a branch step, the
  /// track's current aim (or the default path) for a shared foundation step.
  static String _branchOf(
    SkillWheelBundle bundle,
    WheelFamily family,
    WheelNode node,
    SkillCategory category,
  ) {
    for (final branch in family.branches) {
      for (final step in branch.steps) {
        if (step.exerciseId == node.exerciseId) return branch.id;
      }
    }
    return _trackFor(bundle, category.id)?.branchId ??
        category.defaultTrainingPathId;
  }

  /// Makes [node] the trained exercise of its tree. Steps on the route
  /// before it are left exactly as they are — jumping ahead keeps the
  /// unfinished ones locked until [node] is mastered, which masters them —
  /// and every step after it locks again, so stepping back onto a cleared
  /// node re-locks what follows. False when the write failed.
  Future<bool> trainNode({
    required String userId,
    required SkillWheelBundle bundle,
    required WheelFamily family,
    required WheelNode node,
    required String source,
  }) async {
    final category = SkillCategoryCatalog.findById(family.categoryId);
    if (category == null) return false;

    final branchId = _branchOf(bundle, family, node, category);
    final path = category.pathFor(branchId);
    final idx = path.indexOf(node.exerciseId);
    if (idx < 0) return false;

    // Every status this write can touch, read once so the new statuses are
    // decided against one consistent picture.
    final touchable = {
      for (final branch in category.branches) ...category.pathFor(branch.id),
    };
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
      return false;
    }

    AnalyticsService.capture('progression_moved', properties: {
      'skill_tree_id': category.id,
      'exercise_id': node.exerciseId,
      'branch_id': branchId,
      'step_index': idx,
      'source': source,
    });
    return true;
  }

  /// Stops the tree's progression: the track pauses, its exercise leaves
  /// future workouts, every status stays put. False when the write failed;
  /// true, with nothing written, for a tree that was not running.
  Future<bool> stopTraining({
    required String userId,
    required SkillWheelBundle bundle,
    required WheelFamily family,
    required String source,
  }) async {
    final track = _trackFor(bundle, family.categoryId);
    if (track == null || !track.included) return true;

    try {
      await _skillTrackService.setIncluded(
        userId,
        family.categoryId,
        included: false,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to stop progression: $error\n$stackTrace');
      return false;
    }

    AnalyticsService.capture('progression_stopped', properties: {
      'skill_tree_id': family.categoryId,
      'source': source,
    });
    return true;
  }
}
