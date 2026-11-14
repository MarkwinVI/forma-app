import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/weekly_quota.dart';
import 'package:forma_app/features/home/widgets/week_widgets.dart';

void main() {
  WeeklyQuota quota({required int done, int target = 3}) => WeeklyQuota(
        target: target,
        done: done,
        weekStart: DateTime(2026, 11, 9),
        daysLeft: 4,
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  testWidgets('the header counts the week and opens the upcoming list',
      (tester) async {
    var opened = 0;
    await pump(
      tester,
      WeekHeader(quota: quota(done: 1), onSeeUpcoming: () => opened++),
    );

    expect(find.text('THIS WEEK · 1 OF 3'), findsOneWidget);
    await tester.tap(find.text('See upcoming'));
    expect(opened, 1);
  });

  testWidgets('the sheet lists sessions and the days off between them',
      (tester) async {
    var openedNext = 0;
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showWeekSheet(
            context,
            quota: quota(done: 1),
            rows: [
              const WeekSessionRow(
                label: 'DONE · MONDAY',
                name: 'Push Day',
                state: WeekSessionState.done,
                number: 1,
              ),
              const WeekSessionRow(
                label: 'TODAY',
                name: 'Rest day',
                state: WeekSessionState.rest,
              ),
              WeekSessionRow(
                label: 'TOMORROW · UP NEXT',
                name: 'Pull Day',
                state: WeekSessionState.next,
                number: 2,
                onTap: () => openedNext++,
              ),
            ],
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('1 of 3 done · 4 days left'), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    // A day off wears the moon, not a session number.
    expect(find.byIcon(Icons.bedtime_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Only a row with somewhere to go is a way out of the sheet.
    await tester.tap(find.text('Pull Day'));
    await tester.pumpAndSettle();
    expect(openedNext, 1);
    expect(find.text('This week'), findsNothing);
  });

  testWidgets('a complete week says when the next one starts',
      (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showWeekSheet(
            context,
            quota: quota(done: 3),
            rows: const [],
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text('3 of 3 done · a new week starts Monday'),
      findsOneWidget,
    );
  });
}
