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

    // A tree that isn't running lists under its own section below.
    await tester.scrollUntilVisible(
      find.text('Squat'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('INACTIVE SKILL TREES'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
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
    expect(find.text('Stop training'), findsNothing);
    expect(find.text('Start training'), findsNothing);
  });

  testWidgets('a locked tree shows the padlock note and the gray Unlock',
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

    // The lock note names the prerequisite; a locked tree's steps are all
    // locked, so the CTA is the quiet gray Unlock.
    expect(
      find.textContaining('Locked tree.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.text('Start here'), findsNothing);
  });

  testWidgets(
      'the active step offers Stop training, and a locked node Jump here',
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

    // Initial focus is the active step — its CTA is the red stop.
    expect(find.text('Stop training'), findsOneWidget);
    expect(find.text('Start training'), findsNothing);

    // Walk the selector onto the locked step via its list row — a step not
    // yet reached gets the quiet gray unlock, with no helper text above it.
    await tester.tap(find.text('Pullups step 2'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.textContaining('Skips the steps before it'), findsNothing);
  });

  testWidgets('stopping asks first, and cancel keeps the progression',
      (tester) async {
    var stopped = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async => stopped = true,
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Stop training'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Stop training Pullups step 1?'), findsOneWidget);
    expect(
      find.textContaining('Your progress stays saved', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(stopped, isFalse);

    // Confirming does stop it.
    await tester.tap(find.text('Stop training'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Stop training').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(stopped, isTrue);
  });

  testWidgets('a locked step asks to jump ahead before training',
      (tester) async {
    var trained = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Pullups step 2'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Jump ahead to Pullups step 2?'), findsOneWidget);
    await tester.tap(find.text('Jump ahead'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(trained, isTrue);
  });

  testWidgets('an idle tree asks to start training its white step',
      (tester) async {
    final families = [
      _family('a', 'Pullups', trunk: [
        WheelNodeState.available,
        WheelNodeState.locked,
        WheelNodeState.locked,
      ]),
      ..._families().skip(1),
    ];
    var trained = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: families,
      activeCategoryIds: const {},
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Start training'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Start training Pullups step 0?'), findsOneWidget);
    expect(
      find.textContaining('activate', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Start training').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(trained, isTrue);
  });

  testWidgets('a cleared step of a running tree asks to go back',
      (tester) async {
    var trained = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    // Pullups step 0 is mastered — selecting it is a move backward. The
    // list rests with the focused row at its top, so scroll back up first.
    await tester.scrollUntilVisible(
      find.text('Pullups step 0'),
      -60,
      scrollable: find.byType(Scrollable).last,
    );
    // Let the bounce settle before tapping.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Pullups step 0'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.text('Start training'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Go back to Pullups step 0?'), findsOneWidget);
    expect(
      find.textContaining('locked again', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Go back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(trained, isTrue);
  });

  testWidgets('a locked tree asks for the early start',
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

    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Start Squat step 0 early?'), findsOneWidget);
    expect(
      find.textContaining('prerequisite', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Start anyway'), findsOneWidget);
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
