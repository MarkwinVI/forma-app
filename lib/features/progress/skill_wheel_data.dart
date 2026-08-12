import '../../core/widgets/skill_tree_map.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/services/training_program_service.dart';
import 'widgets/skill_wheel.dart';

/// Wheel order interleaves the wide fans with the straight lines so the
/// circle reads balanced. Trees the catalog adds later fall in at the end.
const List<String> kWheelOrder = [
  SkillCategoryCatalog.pullupsId,
  SkillCategoryCatalog.plancheId,
  SkillCategoryCatalog.rowsId,
  SkillCategoryCatalog.muscleUpId,
  SkillCategoryCatalog.coreId,
  SkillCategoryCatalog.handstandPushupsId,
  SkillCategoryCatalog.pushupsId,
  SkillCategoryCatalog.dipsId,
  SkillCategoryCatalog.squatId,
];

/// Wheel-specific branch display order, by category. Branches fan from the
/// family's counterclockwise side to its clockwise side in this order — for
/// Pullups (pointing up on the wheel) that reads left to right. Categories
/// not listed keep the catalog's order.
const Map<String, List<String>> _branchDisplayOrder = {
  SkillCategoryCatalog.pullupsId: [
    'l_sit',
    'one_arm',
    'weighted',
    'close_grip',
  ],
};

/// Where a goal sits on the wheel when its own tree is the answer rather
/// than the branch that trains it. Both of these are trained on another
/// tree's branch — Planche through the pushups planche branch, Muscle-up
/// through the pull-up foundation — but the wheel is a map of skills, and
/// this is the tree a user looks in for them.
const Map<String, String> _goalTreePlacements = {
  'planche': SkillCategoryCatalog.plancheId,
  'muscleup': SkillCategoryCatalog.muscleUpId,
};

/// The wheel tip a goal option marks, or null when the goal has no place on
/// it. Keys match [SkillWheel.pickedGoals]: `<categoryId>:<branchId>`, or
/// `<categoryId>:*` for a family drawn without branches.
String? goalTipKey(String goalId, List<WheelFamily> families) {
  WheelFamily? familyOf(String categoryId) {
    for (final family in families) {
      if (family.categoryId == categoryId) return family;
    }
    return null;
  }

  final ownTree = _goalTreePlacements[goalId];
  if (ownTree != null) {
    final family = familyOf(ownTree);
    if (family == null) return null;
    // These trees are drawn as a single line, so their tip is the family's.
    return family.branches.isEmpty ? '$ownTree:*' : null;
  }

  final branchRef = TrainingProgramService.goalBranchIds[goalId];
  if (branchRef == null) return null;
  final parts = branchRef.split(':');
  if (parts.length != 2) return null;
  final family = familyOf(parts[0]);
  if (family == null) return null;
  if (family.branches.isEmpty) return '${parts[0]}:*';
  for (final branch in family.branches) {
    if (branch.id == parts[1]) return branchRef;
  }
  return null;
}

/// The trees still behind an unmet prerequisite, keyed by category id —
/// muscle-up until the pull-up is mastered, handstand pushups and planche
/// until the diamond pushup is. A cleared (mastered or skipped)
/// prerequisite removes the lock entirely.
Map<String, WheelTreeLock> computeTreeLocks(
  Map<String, ExerciseStatus> progressMap,
) {
  final locks = <String, WheelTreeLock>{};
  for (final category in SkillCategoryCatalog.browsable()) {
    final requirement = category.unlockRequirement;
    if (requirement == null || !category.isLockedFor(progressMap)) continue;
    locks[category.id] = WheelTreeLock(
      prereqExerciseName: ExerciseCatalog.findById(requirement.exerciseId)
              ?.name ??
          requirement.exerciseId,
      prereqTreeTitle:
          SkillCategoryCatalog.findById(requirement.targetSkillCategoryId)
                  ?.title ??
              'another',
    );
  }
  return locks;
}

String _branchFor(SkillCategory category, List<SkillTrack> skillTracks) {
  for (final track in skillTracks) {
    if (track.skillCategoryId == category.id) return track.branchId;
  }
  return category.defaultTrainingPathId;
}

/// Builds the wheel's families straight from the skill tree data layer:
/// every browsable category, its foundation trunk (the steps every branch
/// shares) and its branch tails, with statuses resolved by the same rule the
/// rest of the app uses ([skillTreeNodeStates]) against the user's tracks.
List<WheelFamily> buildWheelFamilies({
  required Map<String, ExerciseStatus> progressMap,
  required List<SkillTrack> skillTracks,
}) {
  final categories = [...SkillCategoryCatalog.browsable()];
  categories.sort((a, b) {
    final ia = kWheelOrder.indexOf(a.id), ib = kWheelOrder.indexOf(b.id);
    return (ia < 0 ? kWheelOrder.length : ia)
        .compareTo(ib < 0 ? kWheelOrder.length : ib);
  });

  final families = <WheelFamily>[];
  for (final category in categories) {
    final goalBranchId = _branchFor(category, skillTracks);
    final nodeStates = skillTreeNodeStates(
      category: category,
      progressMap: progressMap,
      goalBranchId: goalBranchId,
    );

    WheelNode node(String exerciseId) {
      final tree = nodeStates[exerciseId];
      final WheelNodeState state;
      if (progressMap[exerciseId] == ExerciseStatus.skipped) {
        state = WheelNodeState.skipped;
      } else if (tree == TreeNodeState.done) {
        state = WheelNodeState.mastered;
      } else if (tree == TreeNodeState.cur) {
        state = WheelNodeState.active;
      } else if (tree == TreeNodeState.unlocked) {
        state = WheelNodeState.available;
      } else {
        state = WheelNodeState.locked;
      }
      return WheelNode(
        exerciseId: exerciseId,
        name: ExerciseCatalog.findById(exerciseId)?.name ?? exerciseId,
        state: state,
      );
    }

    final foundationIds = category.pathFor(category.foundationBranchId);
    final branches = <WheelBranch>[];
    for (final branch in category.branches) {
      if (SkillCategory.isFoundationBranchId(branch.id)) continue;
      final ids = category.pathFor(branch.id);
      if (ids.length <= foundationIds.length) continue;
      branches.add(WheelBranch(
        id: branch.id,
        label: branch.label,
        steps: [
          for (final id in ids.sublist(foundationIds.length)) node(id),
        ],
      ));
    }
    final displayOrder = _branchDisplayOrder[category.id];
    if (displayOrder != null) {
      branches.sort((a, b) {
        final ia = displayOrder.indexOf(a.id), ib = displayOrder.indexOf(b.id);
        return (ia < 0 ? displayOrder.length : ia)
            .compareTo(ib < 0 ? displayOrder.length : ib);
      });
    }

    final trunk = [for (final id in foundationIds) node(id)];
    if (trunk.isEmpty && branches.isEmpty) continue;
    families.add(WheelFamily(
      categoryId: category.id,
      title: category.title,
      trunk: trunk,
      branches: branches,
    ));
  }
  return families;
}
