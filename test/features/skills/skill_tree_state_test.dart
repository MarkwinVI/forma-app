import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/skill_tree_map.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/services/training_program_service.dart';

/// The Progress row and the tree it opens have to name the same step as the
/// one you are on. They used to disagree: Progress picks the first step still
/// to clear, while the tree's list read the stored status and called an
/// untouched step "Locked".
void main() {
  final category = SkillCategoryCatalog.findById(SkillCategoryCatalog.pullupsId)!;
  final path = category.pathFor(category.defaultTrainingPathId);

  TreeNodeState stateOf(
    Map<String, ExerciseStatus> progress,
    String exerciseId,
  ) {
    final states = skillTreeNodeStates(
      category: category,
      progressMap: progress,
      goalBranchId: category.defaultTrainingPathId,
    );
    return states[exerciseId] ?? TreeNodeState.locked;
  }

  String? programCurrent(Map<String, ExerciseStatus> progress) {
    final option = TrainingProgramService().allBranchOptions().firstWhere(
          (option) =>
              option.sourceSkillCategoryId == category.id &&
              option.trainingPathId == category.defaultTrainingPathId,
        );
    return TrainingProgramService()
        .currentExerciseForOption(option, progress)
        ?.id;
  }

  test('an untouched tree is on its first step, not locked out of it', () {
    const progress = <String, ExerciseStatus>{};

    expect(programCurrent(progress), path.first);
    expect(stateOf(progress, path.first), TreeNodeState.cur);
  });

  test('clearing a step moves both readings to the next one', () {
    final progress = {path.first: ExerciseStatus.mastered};

    expect(programCurrent(progress), path[1]);
    expect(stateOf(progress, path.first), TreeNodeState.done);
    expect(stateOf(progress, path[1]), TreeNodeState.cur);
  });

  test('an explicitly active step wins over the first uncleared one', () {
    final progress = {
      path.first: ExerciseStatus.mastered,
      path[2]: ExerciseStatus.active,
    };

    expect(programCurrent(progress), path[2]);
    expect(stateOf(progress, path[2]), TreeNodeState.cur);
  });
}
