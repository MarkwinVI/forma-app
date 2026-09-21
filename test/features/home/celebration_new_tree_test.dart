import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/features/home/celebration_new_tree.dart';

NewTreeUnlockData? handoffFor(String masteredId, String newId) {
  return resolveNewTreeUnlock(
    mastered: ExerciseCatalog.findById(masteredId)!,
    newExercise: ExerciseCatalog.findById(newId)!,
    masterySets: 3,
    masteryValue: 8,
    startSets: 3,
    startValue: 6,
  );
}

void main() {
  group('resolveNewTreeUnlock', () {
    test('the last shared dip opening the handstand tree is a hand-off', () {
      final data = handoffFor(
        'dips_parallel_bar_dips',
        'handstand_pushups_pike_push_up',
      );
      expect(data, isNotNull);
      expect(data!.fromTitle, 'Dips');
      expect(data.fromFoundationNames.last, 'Chest Dip');
      expect(data.fromBranchLabels, ['Weighted', 'Rings']);
      expect(data.toTitle, 'Handstand Pushups');
      expect(data.toNodeNames.length, 3);
      expect(data.toActiveIndex, 0);
      expect(data.slotLabel, 'vertical push');
    });

    test('a step in the same tree is not a hand-off', () {
      expect(
        handoffFor('dips_parallel_bar_dips', 'dips_weighted_dips_120'),
        isNull,
      );
    });
  });

  testWidgets('the hand-off screen plays its beats and lands on the new tree',
      (tester) async {
    final data = handoffFor(
      'dips_parallel_bar_dips',
      'handstand_pushups_pike_push_up',
    )!;
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NewTreeUnlockContent(data: data))),
    );
    await tester.pump();
    expect(find.text('Chest Dip'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('EXERCISE MASTERED'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Handstand Pushups'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NEW SKILL TREE UNLOCKED'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NEW EXERCISE STARTED'), findsOneWidget);
    expect(find.text(data.newExercise.name), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      find.textContaining('now takes your vertical push slot'),
      findsOneWidget,
    );
    expect(find.byType(NewTreeMap), findsOneWidget);
  });
}
