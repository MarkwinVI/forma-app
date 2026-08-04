import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/program/program_view.dart';

/// The Program tab re-keys — and thereby resets, scroll position and all —
/// its hosted overview only when the program actually changed. That hinges
/// on this comparison saying "same" for two fetches of unchanged data, even
/// though jsonb hands maps back in a different key order than they were
/// written in.
void main() {
  UserTrainingProgram program({
    int frequency = 3,
    Map<String, dynamic> rules = const {'b': 2, 'a': 1},
  }) =>
      UserTrainingProgram(
        id: 'p1',
        userId: 'u1',
        programType: TrainingProgramType.fullBody,
        scheduleVariant: 'full_body_3x',
        frequencyPerWeek: frequency,
        variationRules: rules,
        isActive: true,
      );

  const state = UserTrainingProgramState(
    id: 's1',
    programId: 'p1',
    userId: 'u1',
    nextStepIndex: 2,
    nextSessionType: TrainingSessionType.fullBody,
  );

  TrainingProgramLogicSnapshot snapshot({
    int frequency = 3,
    Map<String, dynamic> rules = const {'b': 2, 'a': 1},
  }) =>
      TrainingProgramLogicSnapshot(
        program: program(frequency: frequency, rules: rules),
        state: state,
        branchSelections: const {TrainingTrack.verticalPull: 'weighted'},
        repGoalProfile: RepGoalProfile.balanced,
        masteryTargets: MasteryTargetSettings.defaults,
      );

  test('two fetches of the same program compare equal', () {
    expect(sameProgramLogic(snapshot(), snapshot()), isTrue);
  });

  test('map key order does not count as a change', () {
    expect(
      sameProgramLogic(
        snapshot(rules: const {'a': 1, 'b': 2}),
        snapshot(rules: const {'b': 2, 'a': 1}),
      ),
      isTrue,
    );
  });

  test('a changed program counts as a change', () {
    expect(sameProgramLogic(snapshot(), snapshot(frequency: 4)), isFalse);
    expect(
      sameProgramLogic(snapshot(), snapshot(rules: const {'a': 1})),
      isFalse,
    );
  });

  test('no program on either side is only the same as itself', () {
    expect(sameProgramLogic(null, null), isTrue);
    expect(sameProgramLogic(null, snapshot()), isFalse);
    expect(sameProgramLogic(snapshot(), null), isFalse);
  });
}
