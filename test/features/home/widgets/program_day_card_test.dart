import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/widgets/program_day_card.dart';
import 'package:forma_app/features/home/widgets/rest_day_view.dart';
import 'package:forma_app/features/home/widgets/today_workout_card.dart';

void main() {
  /// The card as the Train tab hosts it: in a scrolling page, so it gets no
  /// height from above and has to size itself.
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          // A still frame of the rest rings, so the test can settle.
          data: const MediaQueryData(
            size: Size(393, 852),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: card,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const rows = [
    TodayWorkoutRow(
      name: 'Scapular Pull Ups',
      previousLabel: '—',
      changeLabel: '—',
      changeDir: 0,
    ),
    TodayWorkoutRow(
      name: 'Bench Dip',
      previousLabel: '—',
      changeLabel: '—',
      changeDir: 0,
    ),
    TodayWorkoutRow(
      name: 'Diamond Push Up',
      previousLabel: '—',
      changeLabel: '—',
      changeDir: 0,
      tag: TodayRowTag.levelUp,
    ),
    TodayWorkoutRow(
      name: 'Push-Up (Wall)',
      previousLabel: '—',
      changeLabel: '—',
      changeDir: 0,
    ),
    TodayWorkoutRow(
      name: 'Squat (Assisted)',
      previousLabel: '—',
      changeLabel: '—',
      changeDir: 0,
    ),
  ];

  testWidgets('a session day previews the first exercises and counts the rest',
      (tester) async {
    var starts = 0;
    var lists = 0;
    await pumpCard(
      tester,
      ProgramDayCard(
        kicker: 'TODAY · YOUR PROGRAM',
        kickerRight: 'DAY 1 OF 3',
        title: 'Full Body',
        meta: '5 exercises · about 35 min',
        body: const ProgramPreviewList(rows: rows),
        actions: ProgramCardActions(
          label: 'Start',
          onPrimary: () => starts++,
          onList: () => lists++,
        ),
      ),
    );

    expect(find.text('TODAY · YOUR PROGRAM'), findsOneWidget);
    expect(find.text('DAY 1 OF 3'), findsOneWidget);
    expect(find.text('Full Body'), findsOneWidget);
    expect(find.text('5 exercises · about 35 min'), findsOneWidget);
    expect(find.text('Scapular Pull Ups'), findsOneWidget);
    expect(find.text('Bench Dip'), findsOneWidget);
    expect(find.text('Diamond Push Up'), findsOneWidget);
    expect(find.text('LVL UP'), findsOneWidget);
    expect(find.text('Push-Up (Wall)'), findsNothing);
    expect(find.text('+ 2 more'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.tap(find.bySemanticsLabel('Show the full workout'));
    expect(starts, 1);
    expect(lists, 1);
  });

  testWidgets('a rest day is held inside the card, rings and all',
      (tester) async {
    await pumpCard(
      tester,
      const ProgramDayCard(
        kicker: 'TODAY · YOUR PROGRAM',
        kickerRight: 'REST DAY',
        body: RestDayView(
          contained: true,
          nextTitle: 'Full Body',
          nextWhen: 'tomorrow',
        ),
      ),
    );

    final card = tester.getRect(find.byType(ProgramDayCard));
    // Sized by what it holds, not stretched down the page.
    expect(card.height, lessThan(520));

    for (final inside in [
      find.byIcon(Icons.bedtime_rounded),
      find.text('RECOVERY'),
      find.text('Nothing to do today'),
      find.text('TOMORROW'),
      find.text('Full Body'),
      find.text('REST DAY'),
    ]) {
      expect(
        find.descendant(of: find.byType(ProgramDayCard), matching: inside),
        findsOneWidget,
      );
      final rect = tester.getRect(inside);
      expect(card.contains(rect.topLeft), isTrue);
      expect(card.contains(rect.bottomRight), isTrue);
    }
    // No way out of the day from in here: the extras sit under the card.
    expect(find.textContaining('Train something else'), findsNothing);
  });

  testWidgets('a rest day can start the next session today', (tester) async {
    var starts = 0;
    await pumpCard(
      tester,
      ProgramDayCard(
        kicker: 'TODAY · YOUR PROGRAM',
        kickerRight: 'REST DAY',
        body: RestDayView(
          contained: true,
          nextTitle: 'Push Day',
          nextWhen: 'in 2 days',
          onStartToday: () => starts++,
        ),
      ),
    );

    expect(find.text('IN 2 DAYS'), findsOneWidget);
    expect(find.text('NEXT UP'), findsNothing);
    await tester.tap(find.text('Start today'));
    expect(starts, 1);
  });

  testWidgets('a rest day with nothing to start shows no button',
      (tester) async {
    await pumpCard(
      tester,
      const ProgramDayCard(
        kicker: 'TODAY · YOUR PROGRAM',
        body: RestDayView(
          contained: true,
          nextTitle: 'Push Day',
          nextWhen: 'tomorrow',
        ),
      ),
    );

    expect(find.text('Start today'), findsNothing);
  });

  testWidgets('a quiet start has no list button unless there is a list',
      (tester) async {
    await pumpCard(
      tester,
      ProgramDayCard(
        kicker: 'FIRST WORKOUT · IN 2 DAYS',
        title: 'Full Body',
        actions: ProgramCardActions(
          label: 'Start this early',
          quiet: true,
          onPrimary: () {},
        ),
      ),
    );

    expect(find.text('Start this early'), findsOneWidget);
    expect(find.bySemanticsLabel('Show the full workout'), findsNothing);
  });
}
