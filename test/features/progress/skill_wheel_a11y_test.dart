import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        WheelNodeState.available,
        WheelNodeState.locked,
        WheelNodeState.locked,
      ]),
      _family('c', 'Squat', trunk: [
        WheelNodeState.locked,
        WheelNodeState.locked,
        WheelNodeState.locked,
      ]),
    ];

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

/// The wheel's buttons are painter semantics, which element finders do not
/// see — these read the semantics tree itself.
SemanticsNode _node(WidgetTester tester, Pattern label) =>
    find.semantics.byLabel(label).evaluate().single;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the wheel overview exposes one button per skill tree',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(SkillWheel(
      families: _families(),
      activeCategoryIds: const {'a'},
      lockedCategoryIds: const {'c'},
    )));
    await tester.pump(const Duration(milliseconds: 800));

    final pullups = _node(tester, 'Pullups, training, 1 of 3 steps mastered');
    expect(pullups.flagsCollection.isButton, isTrue);
    expect(pullups.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    _node(tester, 'Pushups, unlocked, 0 of 3 steps mastered');
    _node(tester, 'Squat, locked, 0 of 3 steps mastered');
    handle.dispose();
  });

  testWidgets('a focused tree exposes one button per step, the focus selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    final controller = SkillWheelController();
    await tester.pumpWidget(_host(SkillWheel(
      families: _families(),
      controller: controller,
      activeCategoryIds: const {'a'},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    controller.goTo(0, 1);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));

    final active = _node(tester, 'Pullups step 1, training');
    expect(active.flagsCollection.isButton, isTrue);
    expect(active.flagsCollection.isSelected == Tristate.isTrue, isTrue);
    _node(tester, 'Pullups step 0, mastered');
    _node(tester, 'Pullups step 2, locked');
    expect(find.semantics.byLabel(RegExp('^Pushups, ')), findsNothing);

    // Tapping a step's node through semantics moves the selector.
    tester.semantics.tap(find.semantics.byLabel('Pullups step 2, locked'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(
      _node(tester, 'Pullups step 2, locked').flagsCollection.isSelected ==
          Tristate.isTrue,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('a single tree still draws, focused on its own', (tester) async {
    await tester.pumpWidget(_host(SkillWheel(families: [_families().first])));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('a focused tree has a labelled 44pt back button',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(SkillWheelScreen(
      families: _families(),
      initialCategoryId: 'a',
      onOpenExercise: (_) {},
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Pullups'), findsWidgets);

    final size = tester.getSize(find.bySemanticsLabel('Back'));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    handle.dispose();
  });
}
