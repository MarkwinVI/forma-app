import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/quick_sessions.dart';
import 'package:forma_app/features/home/quick_sessions_view.dart';
import 'package:forma_app/features/home/widgets/quick_sessions_section.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<List<String>> pumpSessions(WidgetTester tester) async {
    phone(tester);
    final blanks = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionsView(
          plannedToday: 'Full Body',
          onBlankWorkout: () => blanks.add('blank'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return blanks;
  }

  testWidgets(
      'every session is listed by group, with a blank workout under them',
      (tester) async {
    final blanks = await pumpSessions(tester);
    // The page itself, not the row of chips, which scrolls sideways.
    final page = find.byType(Scrollable).first;

    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('SHORT ON TIME'), findsOneWidget);
    for (final session in QuickSessions.all) {
      await tester.scrollUntilVisible(
        find.text(session.summary),
        120,
        scrollable: page,
      );
      expect(find.text(session.summary), findsOneWidget);
    }
    expect(find.text('RECOVER'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Blank workout'),
      120,
      scrollable: page,
    );
    expect(find.text('YOUR OWN'), findsOneWidget);
    expect(find.text('Add exercises as you go'), findsOneWidget);
    await tester.tap(find.text('Blank workout'));
    expect(blanks, ['blank']);
  });

  testWidgets('a chip narrows the list, and takes the blank workout with it',
      (tester) async {
    await pumpSessions(tester);

    await tester.tap(find.text('Stretch'));
    await tester.pumpAndSettle();

    expect(find.text('Full-body stretch'), findsOneWidget);
    expect(find.text('Hips & hamstrings'), findsOneWidget);
    expect(find.text('Morning energy'), findsNothing);
    expect(find.text('SHORT ON TIME'), findsNothing);
    expect(find.text('Blank workout'), findsNothing);

    await tester.tap(find.text('Under 10 min'));
    await tester.pumpAndSettle();
    expect(find.text('Push-up primer'), findsOneWidget);
    expect(find.text('Full-body stretch'), findsOneWidget);
    expect(find.text('Morning energy'), findsNothing);
  });

  testWidgets('a session opens its intro, which leaves the program alone',
      (tester) async {
    await pumpSessions(tester);

    await tester.tap(find.text('Morning energy'));
    await tester.pumpAndSettle();

    expect(find.text('QUICK SESSION'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('5 moves'), findsOneWidget);
    expect(find.text('NO REST'), findsOneWidget);
    expect(find.text('WHAT YOU’LL DO'), findsOneWidget);
    expect(find.text('Jumping Jacks'), findsOneWidget);
    expect(
      find.textContaining(
        'Full Body stays planned for today.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    // Start opens the player, on the pause before the first move.
    await tester.tap(find.text('Start session · 10 min'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('GET READY'), findsOneWidget);

    // Unmounts the player, and its timer with it.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the Train tab offers a few, and the way to the rest',
      (tester) async {
    phone(tester);
    final opened = <String>[];
    var seeAll = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickSessionsSection(
            sessions: QuickSessions.featured,
            onOpen: (session) => opened.add(session.id),
            onSeeAll: () => seeAll++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick sessions'), findsOneWidget);
    // The heading stands alone: no line under it.
    expect(find.textContaining('Optional'), findsNothing);
    expect(find.text('Morning energy'), findsOneWidget);
    expect(find.text('10 MIN'), findsOneWidget);

    await tester.tap(find.text('Morning energy'));
    await tester.tap(find.text('See all'));
    expect(opened, ['morning_energy']);
    expect(seeAll, 1);
  });
}
