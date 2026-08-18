import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/exercise_progress_model.dart';
import 'package:forma_app/data/models/progression_event_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/exercise_progression_service.dart';
import 'package:forma_app/data/services/weight_unit_service.dart';

/// Auto progression: what Forma does to an accessory between sessions.
///
/// An accessory is on no path — it masters nothing and unlocks nothing — so
/// the only thing a session can move is its own reps and weight. It runs the
/// way a skill-tree step runs: 3 × 6 climbing a rep at a time towards the
/// global mastery target (3 × 8 by default), and reaching that — from
/// wherever the goal is — moves to the next load the equipment can make and
/// starts again at 3 × 6.
void main() {
  setUp(() => WeightUnitService.notifier.value = WeightUnit.kg);

  // Reps × weight, off a dumbbell rack.
  final lateralRaise = ExerciseCatalog.findById('lateral_raise_dumbbell')!;
  // Reps × weight, on a bar.
  final barbellRow = ExerciseCatalog.findById('bent_over_row_barbell')!;
  final abWheel = ExerciseCatalog.findById('ab_wheel_kneeling')!;
  final archHang = ExerciseCatalog.findById('arch_hang')!;
  final barbellSquatRung = ExerciseCatalog.findById('squat_barbell_plus_25')!;

  ExerciseProgress progress({
    int? value,
    int? sets,
    double? weightKg,
    bool? autoProgression,
    Exercise? exercise,
  }) {
    return ExerciseProgress(
      exerciseId: (exercise ?? lateralRaise).id,
      status: ExerciseStatus.inactive,
      updatedAt: DateTime(2026, 8, 17),
      currentTargetSets: sets,
      currentTargetValue: value,
      currentTargetWeightKg: weightKg,
      autoProgression: autoProgression,
    );
  }

  ExerciseTarget? changeFor({
    required int volume,
    Exercise? exercise,
    ExerciseProgress? stored,
    List<double> setWeights = const [],
  }) {
    return ExerciseProgressionService.accessoryTargetChange(
      result: SessionExerciseResult(
        exercise: exercise ?? lateralRaise,
        volume: volume,
        isAccessory: true,
        sets: [
          for (final weightKg in setWeights)
            SessionSetResult(value: 6, weightKg: weightKg),
        ],
      ),
      progress: stored,
    );
  }

  group('which exercises can be managed', () {
    test('only a reps × weight accessory', () {
      expect(
        ExerciseProgressionService.supportsAutoProgression(lateralRaise),
        isTrue,
      );
      expect(
        ExerciseProgressionService.supportsAutoProgression(barbellRow),
        isTrue,
      );
      // Nothing to step: a movement counted in reps alone carries no weight.
      expect(
        ExerciseProgressionService.supportsAutoProgression(abWheel),
        isFalse,
      );
      // A hold is not counted in reps.
      expect(
        ExerciseProgressionService.supportsAutoProgression(archHang),
        isFalse,
      );
      // A skill-tree rung climbs its own ladder.
      expect(
        ExerciseProgressionService.supportsAutoProgression(barbellSquatRung),
        isFalse,
      );
    });

    test('on by default, and off once the user says so', () {
      expect(
        ExerciseProgressionService.autoProgressionEnabled(lateralRaise),
        isTrue,
      );
      expect(
        ExerciseProgressionService.autoProgressionEnabled(
          lateralRaise,
          progress: progress(autoProgression: false),
        ),
        isFalse,
      );
      // Saying yes to something that cannot have it still reads as off.
      expect(
        ExerciseProgressionService.autoProgressionEnabled(
          abWheel,
          progress: progress(autoProgression: true),
        ),
        isFalse,
      );
    });

    test('a reps × weight accessory opens at 3 × 6, managed or not', () {
      final target = ExerciseProgressionService.accessoryTargetFor(barbellRow);

      expect(target.sets, 3);
      expect(target.value, 6);
      // No stated start: the weight waits for the user's first session.
      expect(target.weightKg, isNull);
      // The prescription is the same with the switch off — only whether it
      // moves changes.
      expect(
          ExerciseProgressionService.targetValueForExercise(lateralRaise), 6);
    });
  });

  group('the accessories a program adds on its own', () {
    final facePull = ExerciseCatalog.findById('face_pull')!;

    test('open on their stated weight', () {
      expect(
        ExerciseProgressionService.accessoryTargetFor(lateralRaise).weightKg,
        2.5,
      );
      expect(
        ExerciseProgressionService.accessoryTargetFor(facePull).weightKg,
        10,
      );
    });

    test('an imperial gym starts on its own plates, not a conversion', () {
      WeightUnitService.notifier.value = WeightUnit.lb;
      const kgPerLb = WeightUnitService.kgPerLb;

      expect(
        ExerciseProgressionService.accessoryTargetFor(lateralRaise).weightKg,
        closeTo(5 * kgPerLb, 1e-9),
      );
      expect(
        ExerciseProgressionService.accessoryTargetFor(facePull).weightKg,
        closeTo(20 * kgPerLb, 1e-9),
      );
    });

    test('a bodyweight start still climbs — to the bar, once 3 × 8 is met', () {
      // The calf raise opens at nothing and is a barbell movement, so its
      // first weight step is the empty bar itself.
      final calfRaise = ExerciseCatalog.findById('standing_calf_raise')!;
      expect(
        ExerciseProgressionService.accessoryTargetFor(calfRaise).weightKg,
        0,
      );

      final change = ExerciseProgressionService.accessoryTargetChange(
        result: SessionExerciseResult(
          exercise: calfRaise,
          volume: 24,
          isAccessory: true,
          sets: const [SessionSetResult(value: 8)],
        ),
        progress: progress(value: 6, sets: 3, weightKg: 0, exercise: calfRaise),
      );

      expect(change!.value, 6);
      expect(change.weightKg, 20);
    });

    test('a weight the user has set wins over the stated start', () {
      expect(
        ExerciseProgressionService.accessoryTargetFor(
          lateralRaise,
          progress: progress(weightKg: 6),
        ).weightKg,
        6,
      );
    });
  });

  group('what a session moves', () {
    test('reaching the target adds a rep', () {
      final change = changeFor(
        volume: 18,
        stored: progress(value: 6, sets: 3, weightKg: 10),
        setWeights: const [10, 10, 10],
      );

      expect(change!.value, 7);
      expect(change.sets, 3);
      // The weight was not touched, so nothing is written over it.
      expect(change.weightKg, isNull);
    });

    test('a first session is what gives an accessory its weight', () {
      // Nothing was stored, so the 10 kg the user picked is the baseline
      // every later step is measured from.
      final change = changeFor(volume: 18, setWeights: const [10, 10, 10]);

      expect(change!.value, 7);
      expect(change.weightKg, 10);
    });

    test('the reps run 6, 7, 8 and then the weight moves', () {
      var stored = progress(value: 6, sets: 3, weightKg: 10);
      final seen = <String>[];
      for (var session = 0; session < 4; session++) {
        final change = changeFor(
          volume: stored.currentTargetValue! * 3,
          stored: stored,
          setWeights: [stored.currentTargetWeightKg!],
        )!;
        seen.add(
            '${change.value}@${change.weightKg ?? stored.currentTargetWeightKg}');
        stored = stored.copyWith(
          currentTargetValue: change.value,
          currentTargetWeightKg: change.weightKg,
        );
      }

      // Off a dumbbell rack, 10 kg is the last of the 1 kg pieces; the next
      // one up is 12. Reaching 3 × 8 is the step, not the session after it.
      expect(seen, ['7@10.0', '8@10.0', '6@12.0', '7@12.0']);
    });

    test('logging 3 × 8 against a 3 × 6 goal is the step, not a rep', () {
      // As on the tree: the ceiling is checked first, so overshooting the
      // goal all the way to the mastery target moves the weight at once.
      final change = changeFor(
        volume: 24,
        stored: progress(value: 6, sets: 3, weightKg: 10),
        setWeights: const [10, 10, 10],
      );

      expect(change!.value, 6);
      expect(change.weightKg, 12);
    });

    test('the ceiling is the live mastery target', () {
      final change = ExerciseProgressionService.accessoryTargetChange(
        result: SessionExerciseResult(
          exercise: lateralRaise,
          volume: 30,
          isAccessory: true,
          sets: const [SessionSetResult(value: 10, weightKg: 10)],
        ),
        progress: progress(value: 9, sets: 3, weightKg: 10),
        masterySettings: const MasteryTargetSettings(repsPerSet: 10),
      );

      expect(change!.value, 6);
      expect(change.weightKg, 12);
    });

    test('topping the window on a bar steps by a plate pair', () {
      final change = changeFor(
        volume: 24,
        exercise: barbellRow,
        stored: progress(
          value: 8,
          sets: 3,
          weightKg: 40,
          exercise: barbellRow,
        ),
        setWeights: const [40, 40, 40],
      );

      expect(change!.value, 6);
      expect(change.weightKg, 42.5);
    });

    test('topping the window off a light dumbbell steps by one kilogram', () {
      final change = changeFor(
        volume: 24,
        stored: progress(value: 8, sets: 3, weightKg: 8),
        setWeights: const [8, 8, 8],
      );

      expect(change!.value, 6);
      expect(change.weightKg, 9);
    });

    test('falling short of the target changes nothing', () {
      expect(
        changeFor(
          volume: 15,
          stored: progress(value: 6, sets: 3, weightKg: 10),
          setWeights: const [10, 10],
        ),
        isNull,
      );
    });

    test('auto progression off leaves the accessory alone', () {
      expect(
        changeFor(
          volume: 60,
          stored: progress(autoProgression: false, weightKg: 10),
          setWeights: const [10],
        ),
        isNull,
      );
    });

    test('an exercise that cannot be managed is left alone', () {
      expect(changeFor(volume: 60, exercise: abWheel), isNull);
    });
  });

  group('a weight the user set by hand', () {
    test('becomes the baseline without turning auto progression off', () {
      // Short of the target, so only the weight moved — and it stays managed.
      final change = changeFor(
        volume: 15,
        stored: progress(value: 6, sets: 3, weightKg: 10),
        setWeights: const [14, 14],
      );

      expect(change!.weightKg, 14);
      expect(change.value, 6, reason: 'the target itself did not move');
    });

    test('is what the next rep is added on top of', () {
      final change = changeFor(
        volume: 18,
        stored: progress(value: 6, sets: 3, weightKg: 10),
        setWeights: const [14, 14, 14],
      );

      expect(change!.value, 7);
      expect(change.weightKg, 14);
    });

    test('is what the weight step is measured from', () {
      final change = changeFor(
        volume: 24,
        stored: progress(value: 8, sets: 3, weightKg: 10),
        setWeights: const [14, 14, 14],
      );

      // The rack's next piece above 14 kg.
      expect(change!.weightKg, 16);
      expect(change.value, 6);
    });

    test('the heaviest set of the session is the one taken', () {
      final change = changeFor(
        volume: 15,
        stored: progress(value: 6, sets: 3, weightKg: 10),
        setWeights: const [12, 16, 14],
      );

      expect(change!.weightKg, 16);
    });
  });

  group('inside a saved session', () {
    test('an accessory moves its target and masters nothing', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: lateralRaise,
            // Far past any mastery volume — an accessory still masters
            // nothing, because it is on no path to master.
            volume: 200,
            isAccessory: true,
            sets: const [SessionSetResult(value: 20, weightKg: 10)],
          ),
        ],
        progressRows: const {},
      );

      expect(outcome.statusChanges, isEmpty);
      // Far past the ceiling: the weight steps and the reps go back to six.
      expect(outcome.targetChanges[lateralRaise.id]!.value, 6);
      expect(outcome.targetChanges[lateralRaise.id]!.weightKg, 12);
    });

    test('an accessory nobody manages leaves the session empty-handed', () {
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [
          SessionExerciseResult(
            exercise: abWheel,
            volume: 200,
            isAccessory: true,
            sets: const [SessionSetResult(value: 20)],
          ),
        ],
        progressRows: const {},
      );

      expect(outcome.isEmpty, isTrue);
    });
  });

  group('what the finish is told', () {
    ProgressionEventInput? eventFor({
      required int volume,
      required ExerciseProgress stored,
      required List<double> setWeights,
    }) {
      final result = SessionExerciseResult(
        exercise: lateralRaise,
        volume: volume,
        isAccessory: true,
        sets: [
          for (final weightKg in setWeights)
            SessionSetResult(value: 8, weightKg: weightKg),
        ],
      );
      final outcome = ExerciseProgressionService.computeSessionOutcome(
        results: [result],
        progressRows: {stored.exerciseId: stored},
      );
      final events = ExerciseProgressionService.buildSessionEvents(
        outcome: outcome,
        results: [result],
        progressRows: {stored.exerciseId: stored},
      );
      return events.isEmpty ? null : events.single;
    }

    test('a weight step carries the load it left and the load it goes to', () {
      final event = eventFor(
        volume: 24,
        stored: progress(value: 8, sets: 3, weightKg: 10),
        setWeights: const [10, 10, 10],
      )!;

      expect(event.kind, ProgressionEventKind.targetIncrease);
      expect(event.valueFrom, 8);
      expect(event.valueTo, 6);
      expect(event.weightFrom, 10);
      expect(event.weightTo, 12);
    });

    test('a rep step carries no weight, even on a hand-set baseline', () {
      // The user lifted 14 where 10 was stored: that is theirs, not a step,
      // and the finish must not roll it as one.
      final event = eventFor(
        volume: 21,
        stored: progress(value: 7, sets: 3, weightKg: 10),
        setWeights: const [14, 14, 14],
      )!;

      expect(event.valueFrom, 7);
      expect(event.valueTo, 8);
      expect(event.weightFrom, isNull);
      expect(event.weightTo, isNull);
    });

    test('a baseline taken on a missed target is no event at all', () {
      expect(
        eventFor(
          volume: 12,
          stored: progress(value: 7, sets: 3, weightKg: 10),
          setWeights: const [14, 14],
        ),
        isNull,
      );
    });
  });
}
