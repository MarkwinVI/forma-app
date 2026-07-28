import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_skill_track_impact.dart';

void main() {
  group('skill track confirmation copy', () {
    test('adding names the workouts by kind and the balance it moves', () {
      final copy = skillTrackImpactCopy(
        treeName: 'Rows',
        removing: false,
        impact: _impact(
          exerciseName: 'Vertical Rows',
          dayNames: const ['Monday', 'Tuesday', 'Thursday', 'Friday'],
          sessionType: TrainingSessionType.fullBody,
          coversEverySession: true,
          balanceLabel: 'Horizontal pull',
          before: 0,
          after: 4,
        ),
      );

      expect(
        copy.change,
        'The Rows progression, starting with Vertical Rows, will be added to '
        'all four full-body workouts.',
      );
      expect(
        copy.balance,
        'This increases horizontal-pull training from none to four times '
        'per week.',
      );
    });

    test('removing the last of a movement says so, and that progress keeps',
        () {
      final copy = skillTrackImpactCopy(
        treeName: 'Pullups',
        removing: true,
        impact: _impact(
          exerciseName: 'Pull Ups',
          dayNames: const ['Monday', 'Tuesday', 'Thursday', 'Friday'],
          sessionType: TrainingSessionType.fullBody,
          coversEverySession: true,
          balanceLabel: 'Vertical pull',
          before: 4,
          after: 0,
        ),
      );

      expect(
        copy.change,
        'The Pullups progression will be removed from all four full-body '
        'workouts.',
      );
      expect(
        copy.balance,
        'This leaves no vertical-pull training in your program. Your progress '
        'will stay saved.',
      );
    });

    test('removing one of two exercises reduces rather than empties', () {
      final copy = skillTrackImpactCopy(
        treeName: 'Dips',
        removing: true,
        impact: _impact(
          exerciseName: 'Bench Dips',
          dayNames: const ['Monday', 'Thursday'],
          sessionType: TrainingSessionType.push,
          coversEverySession: true,
          balanceLabel: 'Vertical push',
          before: 4,
          after: 2,
        ),
      );

      expect(
        copy.change,
        'The Dips progression will be removed from both push workouts.',
      );
      expect(
        copy.balance,
        'This reduces vertical-push training from four to two times per week. '
        'Your progress will stay saved.',
      );
    });

    test('a single workout is not called "all one"', () {
      final copy = skillTrackImpactCopy(
        treeName: 'Squat',
        removing: false,
        impact: _impact(
          exerciseName: 'Assisted Squat',
          dayNames: const ['Wednesday'],
          sessionType: TrainingSessionType.lower,
          coversEverySession: true,
          balanceLabel: 'Legs',
          before: 0,
          after: 1,
        ),
      );

      expect(
        copy.change,
        'The Squat progression, starting with Assisted Squat, will be added '
        'to your lower-body workout.',
      );
      expect(
        copy.balance,
        'This increases legs training from none to one time per week.',
      );
    });

    test('a tree spanning two kinds of workout lists the days instead', () {
      // Core sits on both push and pull days, so there is no single kind of
      // workout to name — and claiming "all" of either would be wrong.
      final copy = skillTrackImpactCopy(
        treeName: 'Core',
        removing: false,
        impact: _impact(
          exerciseName: 'Tuck L-Sit',
          dayNames: const ['Monday', 'Thursday'],
          balanceLabel: 'Core',
          before: 0,
          after: 2,
        ),
      );

      expect(
        copy.change,
        'The Core progression, starting with Tuck L-Sit, will be added to '
        'your Monday and Thursday workouts.',
      );
    });

    test('covering only some workouts of a kind lists the days', () {
      final copy = skillTrackImpactCopy(
        treeName: 'Rows',
        removing: false,
        impact: _impact(
          exerciseName: 'Vertical Rows',
          dayNames: const ['Monday', 'Friday'],
          sessionType: TrainingSessionType.fullBody,
          coversEverySession: false,
          balanceLabel: 'Horizontal pull',
          before: 1,
          after: 3,
        ),
      );

      expect(
        copy.change,
        'The Rows progression, starting with Vertical Rows, will be added to '
        'your Monday and Friday workouts.',
      );
      expect(
        copy.balance,
        'This increases horizontal-pull training from one to three times '
        'per week.',
      );
    });
  });
}

SkillTrackImpact _impact({
  required String exerciseName,
  required List<String> dayNames,
  required String balanceLabel,
  required int before,
  required int after,
  TrainingSessionType? sessionType,
  bool coversEverySession = false,
}) {
  return SkillTrackImpact(
    exerciseName: exerciseName,
    dayNames: dayNames,
    sessionType: sessionType,
    coversEverySession: coversEverySession,
    balanceLabel: balanceLabel,
    before: before,
    after: after,
    target: 3,
  );
}
