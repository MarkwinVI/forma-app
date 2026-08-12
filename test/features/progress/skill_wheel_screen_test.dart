import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/program_skill_trees_section.dart';
import 'package:forma_app/features/home/progression_toast.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_screen.dart';

WheelFamily _family(
  String id,
  String title, {
  required List<WheelNodeState> trunk,
}) {
  return WheelFamily(
    categoryId: id,
    title: title,
    trunk: [
      for (var i = 0; i < trunk.length; i++)
        WheelNode(exerciseId: '$id-$i', name: '$title step $i', state: trunk[i]),
    ],
    branches: const [],
  );
}

List<WheelFamily> _families() => [
      _family('a', 'Pullups', trunk: [
        WheelNodeState.mastered,
        WheelNodeState.active,
        WheelNodeState.locked,
      ]),
      _family('b', 'Pushups', trunk: [
        WheelNodeState.active,
        WheelNodeState.locked,
        WheelNodeState.locked,
      ]),
      _family('c', 'Squat', trunk: [
        WheelNodeState.locked,
        WheelNodeState.locked,
        WheelNodeState.locked,
      ]),
    ];

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('editable overview lists the running progressions',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a', 'b'},
      editable: true,
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);
    // The tree name is the whole row — no "Now:" step subtitle under it.
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Now: Pullups step 1'), findsNothing);
    expect(find.text('Pushups'), findsOneWidget);
    // A tree that isn't running stays off the list.
    expect(find.text('Squat'), findsNothing);
  });

  testWidgets(
      'read-only wheel shows neither progression list nor train controls',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ACTIVE SKILL TREES'), findsNothing);
    expect(find.text('STOP TRAINING'), findsNothing);
    expect(find.text('Train this exercise'), findsNothing);
  });

  testWidgets('a locked tree shows the padlock note and Start anyway',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      treeLocks: const {
        'c': WheelTreeLock(
          prereqExerciseName: 'Diamond Pushup',
          prereqTreeTitle: 'Pushups',
        ),
      },
      editable: true,
      initialCategoryId: 'c',
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    // The lock note names the prerequisite, and the CTA softens to a
    // warned "Start anyway".
    expect(
      find.textContaining('Locked tree.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Start anyway'), findsOneWidget);
    expect(find.text('Start here'), findsNothing);
  });

  testWidgets(
      'focusing an active tree shows STOP TRAINING, and a locked node the CTA',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    // Let the fly-in camera settle.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('STOP TRAINING'), findsOneWidget);
    // Initial focus is the active step — no CTA there.
    expect(find.text('Train this exercise'), findsNothing);

    // Walk the selector onto the locked step via its list row — a step not
    // yet reached gets the quiet "anyway" offer.
    await tester.tap(find.text('Pullups step 2'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Train it anyway'), findsOneWidget);
  });

  testWidgets('program card is the plain door into the trees',
      (tester) async {
    await tester.pumpWidget(_host(SingleChildScrollView(
      child: ProgramSkillTreesCard(
        families: _families(),
        activeCategoryIds: const {'a', 'b'},
        onOpen: () {},
      ),
    )));

    expect(find.text('Edit Progression'), findsOneWidget);
    expect(find.text('OPEN SKILL TREE MAP'), findsNothing);
  });

  testWidgets('moved toast shows the OUT → IN pair with UNDO',
      (tester) async {
    var undone = false;
    await tester.pumpWidget(_host(ProgressionToast(
      data: ProgressionToastData(
        kind: ProgressionToastKind.moved,
        outName: 'Incline Pushup',
        inName: 'Pushup',
        sub: 'Swapped in your workouts.',
        onUndo: () async {},
      ),
      onUndoTap: () => undone = true,
    )));

    expect(find.text('PROGRESSION MOVED'), findsOneWidget);
    expect(find.text('Incline Pushup'), findsOneWidget);
    expect(find.text('Pushup'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    expect(undone, isTrue);
  });
}
