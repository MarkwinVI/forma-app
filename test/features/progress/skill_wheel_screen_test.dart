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

void main() {
  testWidgets('editable overview lists the running progressions',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a', 'b'},
      editable: true,
      startEditing: true,
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

    // A long pull down from the first row: the list is already at its top,
    // so this is all overscroll.
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

  testWidgets('a locked tree shows the padlock note and the start button',
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
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    // The lock note names the prerequisite; no step of the tree is being
    // trained, so the footer offers Start training.
    expect(
      find.textContaining('Locked tree.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Start training'), findsOneWidget);
    expect(find.text('Stop training'), findsNothing);
  });

  testWidgets(
      'the active step offers Stop training, any other Start training',
      (tester) async {
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      activeCategoryIds: const {'a'},
      editable: true,
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    // Let the fly-in camera settle.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    // Initial focus is the active step — its CTA is the red stop, under
    // the same preview view mode shows.
    expect(find.text('Stop training'), findsOneWidget);
    expect(find.text('Start training'), findsNothing);
    expect(find.byType(WheelExercisePreview), findsOneWidget);

    // Walk the selector onto the locked step via its list row — any other
    // step offers Start training, with no helper text above it.
    await tester.tap(find.text('Pullups step 2'));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Start training'), findsOneWidget);
    expect(find.text('Stop training'), findsNothing);
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

    // Confirming does stop it — the sheet's own button is the last one.
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
      startEditing: true,
      initialCategoryId: 'a',
      onTrainNode: (_, __) async => trained = true,
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Pullups step 2'));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.text('Start training'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Start Pullups step 2?'), findsOneWidget);
    expect(
      find.textContaining(
        'the earlier exercises in this path will also be marked as mastered',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Start exercise'));
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
      startEditing: true,
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
      startEditing: true,
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
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Start training'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

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
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);
    expect(find.text('Skill Trees'), findsOneWidget);

    // Done: back to viewing, still here.
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
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
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    // Viewing the tree: the preview, no action.
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(WheelExercisePreview), findsOneWidget);
    expect(find.text('Stop training'), findsNothing);

    // Edit: still on Pullups, the same preview with the step's action
    // under it and Done in the header. The list of progressions never
    // appears.
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Stop training'), findsOneWidget);
    expect(find.byType(WheelExercisePreview), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);

    // Done: the tree and its preview stay, the action goes.
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Stop training'), findsNothing);
    expect(find.byType(WheelExercisePreview), findsOneWidget);
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
      onTrainNode: (_, __) async {},
      onStopTraining: (_) async {},
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
        onTrainNode: (_, __) async {},
        onStopTraining: (_) async {},
        onOpenExercise: (_) {},
      ),
    )));
    await tester.pump(const Duration(milliseconds: 800));

    // Viewing: a re-tap has nothing to unwind, so the shell may scroll.
    expect(reset.fire(), isFalse);

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);

    // Editing on the overview: the re-tap is the way out of edit mode.
    expect(reset.fire(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
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
          onTrainNode: (_, __) async {},
          onStopTraining: (_) async {},
          onOpenExercise: (_) {},
        );
    await tester.pumpWidget(_host(screen(isActive: true)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Stop training'), findsOneWidget);

    // Another tab: the edit ends behind the user's back, the tree stays
    // focused for when they come back.
    await tester.pumpWidget(_host(screen(isActive: false)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pullups'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(find.text('Stop training'), findsNothing);

    // Back on the tab: still viewing.
    await tester.pumpWidget(_host(screen(isActive: true)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(WheelExercisePreview), findsOneWidget);
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
        onTrainNode: (_, __) async {},
        onStopTraining: (_) async {},
        onOpenExercise: (_) {},
      ),
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));
    // Focused on Pullups: the overview's progression list is gone.
    expect(find.text('Stop training'), findsOneWidget);
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);

    // The re-tap: the wheel claims it and flies back out.
    expect(reset.fire(), isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Stop training'), findsNothing);
    expect(find.text('ACTIVE SKILL TREES'), findsOneWidget);

    // On the overview, still editing: the next re-tap ends the edit. Then
    // there is nothing left to unwind, so the shell may scroll.
    expect(reset.fire(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ACTIVE SKILL TREES'), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
    expect(reset.fire(), isFalse);
  });
}
