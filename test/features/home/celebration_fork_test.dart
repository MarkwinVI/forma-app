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
      expect(fork!.treeTitle, 'Dips');
      expect(fork.chosenBranchId, 'weighted');
      expect(fork.foundationNames.length, 3);
      expect(fork.foundationNames.last, 'Chest Dip');
      expect(
        [for (final branch in fork.branches) branch.id],
        ['weighted', 'rings'],
      );
      expect(fork.chosen.nodeNames.length, 2);
      expect(fork.branches.last.nodeNames.first, 'Ring Dips');
    });

    test('the pull-up foundation forks four ways', () {
      final fork = forkFor('pullups_pull_up', 'pullups_close_grip_pull_up');
      expect(fork, isNotNull);
      expect(fork!.chosenBranchId, 'close_grip');
      expect(fork.branches.length, greaterThanOrEqualTo(3));
      expect(fork.chosen.label, 'Close Grip');
    });

    test('a step inside a branch is an ordinary unlock, not a fork', () {
      expect(
        forkFor('dips_weighted_dips_120', 'dips_weighted_dips_140'),
        isNull,
      );
    });

    test('a step inside the foundation is not a fork either', () {
      expect(forkFor('dips_dip_negatives', 'dips_parallel_bar_dips'), isNull);
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
    expect(find.textContaining('You’re on the Weighted path.'), findsOneWidget);
    expect(find.byType(ForkMap), findsOneWidget);
  });
}
