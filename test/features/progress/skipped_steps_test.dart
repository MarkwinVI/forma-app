import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/progress/skill_wheel_data.dart';

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
}
