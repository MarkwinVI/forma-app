import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/features/progress/skill_wheel_data.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';

/// A jump ahead leaves the steps it passed inactive until the jumped-to
/// step is mastered; the wheel calls those "skipped".
void main() {
  const path = ['a', 'b', 'c', 'd', 'e'];

  test('the uncleared steps before the active one are skipped', () {
    final skipped = skippedStepIds(path: path, progressMap: {
      'a': ExerciseStatus.mastered,
      'b': ExerciseStatus.inactive,
      'd': ExerciseStatus.active,
    });
    // b was left inactive, c never written: both jumped over. a was
    // mastered before the jump, e lies ahead.
    expect(skipped, {'b', 'c'});
  });

  test('a route at its first step, or with nothing active, skips nothing',
      () {
    expect(
      skippedStepIds(path: path, progressMap: {'a': ExerciseStatus.active}),
      isEmpty,
    );
    expect(
      skippedStepIds(path: path, progressMap: {
        'a': ExerciseStatus.mastered,
        'b': ExerciseStatus.inactive,
      }),
      isEmpty,
    );
  });

  test('a route trained step by step skips nothing', () {
    expect(
      skippedStepIds(path: path, progressMap: {
        'a': ExerciseStatus.mastered,
        'b': ExerciseStatus.mastered,
        'c': ExerciseStatus.active,
      }),
      isEmpty,
    );
  });

  test('on the wheel, a jumped-over step after a mastered one stays unlocked',
      () {
    final squat = SkillCategoryCatalog.findById(SkillCategoryCatalog.squatId)!;
    final path = squat.pathFor(squat.foundationBranchId);
    expect(path.length, greaterThanOrEqualTo(4));

    // Step 0 mastered, a jump straight to step 3.
    final families = buildWheelFamilies(
      progressMap: {
        path[0]: ExerciseStatus.mastered,
        path[3]: ExerciseStatus.active,
      },
      skillTracks: [
        SkillTrack(
          skillCategoryId: squat.id,
          branchId: squat.foundationBranchId,
          included: true,
          updatedAt: DateTime(2026),
        ),
      ],
    );
    final family = families.firstWhere((f) => f.categoryId == squat.id);
    WheelNode step(int i) =>
        family.flat.firstWhere((node) => node.exerciseId == path[i]);

    expect(step(1).state, WheelNodeState.available);
    expect(step(1).skipped, isFalse);
    expect(step(2).state, WheelNodeState.locked);
    expect(step(2).skipped, isTrue);
    expect(step(3).state, WheelNodeState.active);
    expect(step(3).skipped, isFalse);
  });
}
