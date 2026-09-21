import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/features/home/celebration_fork.dart';

ForkUnlockData? forkFor(String masteredId, String newId) {
  return resolveForkUnlock(
    mastered: ExerciseCatalog.findById(masteredId)!,
    newExercise: ExerciseCatalog.findById(newId)!,
    masterySets: 3,
    masteryValue: 8,
    startSets: 3,
    startValue: 6,
  );
}

void main() {
  group('resolveForkUnlock', () {
    test('the last foundation dip opening the weighted branch is a fork', () {
      final fork = forkFor('dips_parallel_bar_dips', 'dips_weighted_dips_120');
      expect(fork, isNotNull);
      expect(fork!.isFork, isTrue);
      expect(fork.masteredIndex, 2);
      expect(fork.treeTitle, 'Dips');
      expect(fork.chosenBranchId, 'weighted');
      expect(fork.foundationNames.length, 3);
      expect(fork.foundationNames.last, 'Chest Dip');
      expect(
        [for (final branch in fork.branches) branch.id],
        ['weighted', 'rings'],
      );
      expect(fork.chosen!.nodeNames.length, 5);
      expect(fork.branches.last.nodeNames.first, 'Ring Dips');
    });

    test('the pull-up foundation forks four ways', () {
      final fork = forkFor('pullups_pull_up', 'pullups_close_grip_pull_up');
      expect(fork, isNotNull);
      expect(fork!.chosenBranchId, 'close_grip');
      expect(fork.branches.length, greaterThanOrEqualTo(3));
      expect(fork.chosen!.label, 'Close Grip');
    });

    test('a step inside a branch draws the tree with that branch chosen', () {
      final data = forkFor('dips_weighted_dips_120', 'dips_weighted_dips_140');
      expect(data, isNotNull);
      expect(data!.isFork, isFalse);
      expect(data.chosenBranchId, 'weighted');
      // Mastered index runs along trunk then branch: 3 trunk steps, then
      // the +20% rung is the branch's first.
      expect(data.masteredIndex, 3);
      expect(data.chosen!.nodeNames.length, 5);
      expect(data.branches.last.nodeNames.length, 2);
    });

    test('a step inside the foundation draws the tree with no branch chosen',
        () {
      final data = forkFor('dips_dip_negatives', 'dips_parallel_bar_dips');
      expect(data, isNotNull);
      expect(data!.isFork, isFalse);
      expect(data.chosenBranchId, isNull);
      expect(data.masteredIndex, 1);
      expect(data.foundationNames.length, 3);
      expect(data.branches.length, 2);
    });

    test('a one-path tree is a straight trunk', () {
      final data = forkFor(
        'handstand_pushups_pike_push_up',
        'handstand_pushups_box_push_up',
      );
      expect(data, isNotNull);
      expect(data!.branches, isEmpty);
      expect(data.foundationNames.length, 7);
      expect(data.masteredIndex, 0);
    });

    test('a step in another tree is not an in-tree unlock', () {
      expect(
        forkFor('dips_parallel_bar_dips', 'handstand_pushups_pike_push_up'),
        isNull,
      );
    });
  });

  testWidgets('the fork screen plays its beats and lands on the new exercise',
      (tester) async {
    final fork = forkFor('dips_parallel_bar_dips', 'dips_weighted_dips_120')!;
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ForkUnlockContent(data: fork))),
    );
    await tester.pump();
    expect(find.text('Chest Dip'), findsOneWidget);
    expect(find.text('PREREQUISITE'), findsOneWidget);
    expect(find.text('EXERCISE MASTERED'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('EXERCISE MASTERED'), findsOneWidget);
    expect(find.text('Chest Dip'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NEW EXERCISE STARTED'), findsOneWidget);
    expect(find.text('STARTING TARGET'), findsOneWidget);
    expect(find.text(fork.newExercise.name), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      find.text(
        'Completing 24 reps of Chest Dip unlocked ${fork.newExercise.name}. '
        'Next workout you’ll work on ${fork.newExercise.name}. You’re on '
        'the Weighted path. Change it anytime on the Program tab.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ForkMap), findsOneWidget);
  });
}
