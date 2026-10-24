import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/tab_reset.dart';
import 'package:forma_app/features/home/program_skill_trees_section.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_panels.dart';
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
        WheelNode(
            exerciseId: '$id-$i', name: '$title step $i', state: trunk[i]),
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

/// Edit mode's hint strip over a focused tree.
final _hint = find.textContaining('Tap the step you want to train');

/// Lets a confirm sheet open, or a toast fade all the way out.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The fly-in camera, settled.
Future<void> _flyIn(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 1200));
}

/// Outlives the toast: it holds for 2.2s, then fades 200ms.
Future<void> _outliveToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2500));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('editable overview lists the running progressions',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a', 'b'},
      editable: true,
      startEditing: true,
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);
    // The tree name is the whole row — no "Now:" step subtitle under it.
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Now: Pullups step 1'), findsNothing);
    expect(find.text('Pushups'), findsOneWidget);
    // The hint belongs to a focused tree, not the overview.
    expect(_hint, findsNothing);

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
    expect(_hint, findsNothing);
  });

  testWidgets('pulling the step list down past its top does not leave the tree',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var backs = 0;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      initialCategoryId: 'a',
      exitOnTreeBack: true,
      onBack: () => backs++,
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(WheelExerciseCard), findsOneWidget);

    // A slow pull down from the top of the list, which is already at its
    // top: all overscroll, well past the 60pt that used to mean "back".
    final list = tester.getRect(find.byType(WheelExerciseCard));
    final position = tester
        .state<ScrollableState>(find.descendant(
          of: find.byType(WheelExerciseCard),
          matching: find.byType(Scrollable),
        ))
        .position;
    final gesture =
        await tester.startGesture(list.topCenter + const Offset(0, 24));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(position.pixels, lessThan(-100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 800));

    expect(backs, 0);
    expect(find.byType(WheelExerciseCard), findsOneWidget);
  });

  testWidgets('a focused tree lists its steps as media rows with a status',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      stepStats: const {
        'a-0': WheelStepStats(bestVolume: 27, targetVolume: 24),
        'a-1': WheelStepStats(bestVolume: 12, targetVolume: 24),
      },
      initialCategoryId: 'a',
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    expect(find.text('Pullups step 0'), findsOneWidget);
    expect(find.text('Mastered · 27 reps'), findsOneWidget);
    expect(find.text('Pullups step 1'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Pullups step 2'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    // Viewing: no radios, and nothing opens in place.
    expect(find.byType(WheelStepRadio), findsNothing);
    expect(find.text('Full details'), findsNothing);
  });

  testWidgets('viewing, a tapped row opens the preview sheet; Full details '
      'opens the exercise', (tester) async {
    WheelNode? opened;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      stepStats: const {
        'a-2': WheelStepStats(bestVolume: 0, targetVolume: 24),
      },
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (node) => opened = node,
    )));
    await _flyIn(tester);

    await tester.tap(find.text('Pullups step 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // The sheet: where the step sits, its status, the bar, Full details —
    // and no way to change the step from here.
    expect(find.text('FOUNDATION · STEP 3 OF 3'), findsOneWidget);
    expect(find.text('Full details'), findsOneWidget);
    expect(find.text('BEST WORKOUT'), findsOneWidget);
    expect(find.text('Start training'), findsNothing);
    expect(find.text('Locked'), findsNWidgets(2)); // the row and the sheet

    await tester.tap(find.text('Full details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(opened?.exerciseId, 'a-2');
    expect(find.text('Full details'), findsNothing);
  });

  testWidgets('a locked tree shows the padlock note and the hint',
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
      startEditing: true,
      initialCategoryId: 'c',
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    // The lock note names the prerequisite; the tree is idle, so the hint
    // says nothing about stopping.
    expect(
      find.textContaining('Locked tree.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Tap the step you want to train.'), findsOneWidget);
    expect(find.text('Edit Squat'), findsOneWidget);
  });

  testWidgets(
      'editing, a tap on the trained step asks to stop, on any other to start',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    // Edit mode on a running tree: the title, the hint with its Stop
    // clause, and a radio on every row — filled on the trained step.
    expect(find.text('Edit Pullups'), findsOneWidget);
    expect(
      find.text('Tap the step you want to train. Tap the current one to stop.'),
      findsOneWidget,
    );
    expect(find.byType(WheelStepRadio), findsNWidgets(3));
    expect(
      tester
          .widgetList<WheelStepRadio>(find.byType(WheelStepRadio))
          .map((radio) => radio.on),
      [false, true, false],
    );

    // The trained step: the stop question.
    await tester.tap(find.text('Pullups step 1'));
    await _settle(tester);
    expect(find.text('Stop training Pullups step 1?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    // The locked step: the jump-ahead question, and no preview sheet.
    await tester.tap(find.text('Pullups step 2'));
    await _settle(tester);
    expect(find.text('Start Pullups step 2?'), findsOneWidget);
    expect(find.text('Full details'), findsNothing);
    expect(find.textContaining('Skips the steps before it'), findsNothing);
  });

  testWidgets('stopping asks first, and cancel keeps the progression',
      (tester) async {
    var stopped = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => stopped = true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    await tester.tap(find.text('Pullups step 1'));
    await _settle(tester);
    expect(find.text('Stop training Pullups step 1?'), findsOneWidget);
    expect(
      find.textContaining('Your progress stays saved', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(stopped, isFalse);
    expect(find.text('Done'), findsOneWidget);

    // Confirming does stop it: the toast says so, and edit mode ends.
    await tester.tap(find.text('Pullups step 1'));
    await _settle(tester);
    await tester.tap(find.text('Stop training'));
    await _settle(tester);
    expect(stopped, isTrue);
    expect(find.text('Pullups paused — progress kept'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(_hint, findsNothing);
    expect(find.byType(WheelStepRadio), findsNothing);

    await _outliveToast(tester);
    expect(find.text('Pullups paused — progress kept'), findsNothing);
  });

  testWidgets('a locked step asks to jump ahead; saved, the edit is done',
      (tester) async {
    var trained = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    await tester.tap(find.text('Pullups step 2'));
    await _settle(tester);

    expect(find.text('Start Pullups step 2?'), findsOneWidget);
    expect(
      find.textContaining(
        'the earlier exercises in this path will also be marked as mastered',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Start exercise'));
    await _settle(tester);
    expect(trained, isTrue);

    // Saved: the toast confirms, and the screen is back to viewing.
    expect(find.text('Now training Pullups step 2'), findsOneWidget);
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(_hint, findsNothing);
    await _outliveToast(tester);
    expect(find.text('Now training Pullups step 2'), findsNothing);
  });

  testWidgets('a save that fails keeps edit mode, with no toast',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => false,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    await tester.tap(find.text('Pullups step 2'));
    await _settle(tester);
    await tester.tap(find.text('Start exercise'));
    await _settle(tester);

    expect(find.text('Now training Pullups step 2'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Edit Pullups'), findsOneWidget);
    expect(_hint, findsOneWidget);
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
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    expect(find.text('Unlocked'), findsOneWidget);
    await tester.tap(find.text('Pullups step 0'));
    await _settle(tester);
    expect(find.text('Start training Pullups step 0?'), findsOneWidget);
    expect(
      find.textContaining('activate', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Start training'));
    await _settle(tester);
    expect(trained, isTrue);
    await _outliveToast(tester);
  });

  testWidgets('a cleared step of a running tree asks to go back',
      (tester) async {
    var trained = false;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    // Pullups step 0 is mastered — picking it is a move backward.
    await tester.tap(find.text('Pullups step 0'));
    await _settle(tester);

    expect(find.text('Go back to Pullups step 0?'), findsOneWidget);
    expect(
      find.textContaining('locked again', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Go back'));
    await _settle(tester);
    expect(trained, isTrue);
    await _outliveToast(tester);
  });

  testWidgets('a locked tree asks for the early start', (tester) async {
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
      startEditing: true,
      initialCategoryId: 'c',
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    await tester.tap(find.text('Squat step 0'));
    await _settle(tester);

    expect(find.text('Start Squat step 0 early?'), findsOneWidget);
    expect(
      find.textContaining('prerequisite', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Start anyway'), findsOneWidget);
  });

  testWidgets('Edit turns the overview into edit mode in place, Done back',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    // Viewing: the pill says Edit and the progressions list is not up.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit skill trees'), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);

    // Edit: nothing navigates — the same screen, now with Done and the
    // list of progressions.
    await tester.tap(find.text('Edit'));
    await _settle(tester);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);
    expect(find.text('Skill Trees'), findsOneWidget);

    // Done: back to viewing, still here.
    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);
  });

  testWidgets('Edit on a focused tree edits that tree, with Done up',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    // Viewing the tree: plain rows, no hint, no radios.
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(WheelExerciseCard), findsOneWidget);
    expect(_hint, findsNothing);
    expect(find.byType(WheelStepRadio), findsNothing);

    // Edit: still on Pullups — the title says so — with the hint, radios
    // on the rows and Done in the header. The list of progressions never
    // appears.
    await tester.tap(find.text('Edit'));
    await _settle(tester);
    expect(find.text('Edit Pullups'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(_hint, findsOneWidget);
    expect(find.byType(WheelStepRadio), findsNWidgets(3));
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);

    // Done: the tree stays, the edit chrome goes.
    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(_hint, findsNothing);
    expect(find.byType(WheelStepRadio), findsNothing);
    expect(find.byType(WheelExerciseCard), findsOneWidget);
  });

  testWidgets('opened in edit mode for a host, Done leaves the screen',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      onDone: () => done++,
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    // Edit mode from the first frame, and no back arrow: Done is the exit.
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(done, 1);
    // The host leaves; until it does, the screen stays in edit mode.
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('for a host, a saved pick leaves the screen the way Done does',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onDone: () => done++,
      onTrainNode: (_, __) async => true,
      onStopTraining: (_) async => true,
      onOpenExercise: (_) {},
    )));
    await _flyIn(tester);

    await tester.tap(find.text('Pullups step 2'));
    await _settle(tester);
    await tester.tap(find.text('Start exercise'));
    await _settle(tester);

    expect(done, 1);
    expect(find.text('Now training Pullups step 2'), findsOneWidget);
    await _outliveToast(tester);
  });

  testWidgets('a re-tap on the overview in edit mode ends the edit',
      (tester) async {
    final reset = TabResetNotifier();
    addTearDown(reset.dispose);
    await tester.pumpWidget(_host(TabReset(
      notifier: reset,
      child: SkillWheelScreen(
        families: _families(),
        activeCategoryIds: const {'a'},
        editable: true,
        onTrainNode: (_, __) async => true,
        onStopTraining: (_) async => true,
        onOpenExercise: (_) {},
      ),
    )));
    await tester.pump(const Duration(milliseconds: 800));

    // Viewing: a re-tap has nothing to unwind, so the shell may scroll.
    expect(reset.fire(), isFalse);

    await tester.tap(find.text('Edit'));
    await _settle(tester);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);

    // Editing on the overview: the re-tap is the way out of edit mode.
    expect(reset.fire(), isTrue);
    await _settle(tester);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);
    expect(reset.fire(), isFalse);
  });

  testWidgets('leaving the tab ends the edit, and keeps the tree',
      (tester) async {
    Widget screen({required bool isActive}) => SkillWheelScreen(
          families: _families(),
          activeCategoryIds: const {'a'},
          editable: true,
          isActive: isActive,
          initialCategoryId: 'a',
          onTrainNode: (_, __) async => true,
          onStopTraining: (_) async => true,
          onOpenExercise: (_) {},
        );
    await tester.pumpWidget(_host(screen(isActive: true)));
    await _flyIn(tester);

    await tester.tap(find.text('Edit'));
    await _settle(tester);
    expect(find.text('Done'), findsOneWidget);
    expect(_hint, findsOneWidget);

    // Another tab: the edit ends behind the user's back, the tree stays
    // focused for when they come back.
    await tester.pumpWidget(_host(screen(isActive: false)));
    await _settle(tester);
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(_hint, findsNothing);

    // Back on the tab: still viewing.
    await tester.pumpWidget(_host(screen(isActive: true)));
    await _settle(tester);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(WheelExerciseCard), findsOneWidget);
  });

  testWidgets('without an editor, the header carries no pill',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('program card is the plain door into the trees', (tester) async {
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

  testWidgets(
      'the tab reset signal pulls a focused tree back out to the overview',
      (tester) async {
    final reset = TabResetNotifier();
    addTearDown(reset.dispose);
    await tester.pumpWidget(_host(TabReset(
      notifier: reset,
      child: SkillWheelScreen(
        families: _families(),
        activeCategoryIds: const {'a'},
        editable: true,
        startEditing: true,
        initialCategoryId: 'a',
        onTrainNode: (_, __) async => true,
        onStopTraining: (_) async => true,
        onOpenExercise: (_) {},
      ),
    )));
    await _flyIn(tester);
    // Focused on Pullups, editing: the hint is up, the overview's
    // progression list is gone.
    expect(_hint, findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);

    // The re-tap: the wheel claims it and flies back out.
    expect(reset.fire(), isTrue);
    await _flyIn(tester);
    expect(_hint, findsNothing);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);

    // On the overview, still editing: the next re-tap ends the edit. Then
    // there is nothing left to unwind, so the shell may scroll.
    expect(reset.fire(), isTrue);
    await _settle(tester);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
    expect(reset.fire(), isFalse);
  });
}
