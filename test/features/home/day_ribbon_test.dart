import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/home/widgets/day_ribbon.dart';

void main() {
  testWidgets('the ribbon scrolls a whole week at a time', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final today = DateTime(2026, 7, 29);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(22),
            child: DayRibbon(
              days: [
                // Week one runs Upper, week two Lower, so each page is
                // recognisable by the letter its markers carry.
                for (var i = 0; i < 14; i++)
                  HomeWeekStripDay(
                    date: today.add(Duration(days: i)),
                    sessionType: i < 7
                        ? TrainingSessionType.upper
                        : TrainingSessionType.lower,
                    isCurrent: i == 0,
                    isCompleted: false,
                  ),
              ],
              selectedDate: today,
              today: today,
              onDayTap: (_) {},
            ),
          ),
        ),
      ),
    );

    // The first week fills the row; the second is a swipe away.
    expect(find.text('U'), findsNWidgets(7));
    expect(find.text('L'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('U'), findsNothing);
    expect(find.text('L'), findsNWidgets(7));
  });

  testWidgets('the week survives the day below it changing', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final today = DateTime(2026, 7, 29);
    var selected = today;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: DayRibbon(
                    days: [
                      for (var i = 0; i < 14; i++)
                        HomeWeekStripDay(
                          date: today.add(Duration(days: i)),
                          sessionType: i < 7
                              ? TrainingSessionType.upper
                              : TrainingSessionType.lower,
                          isCurrent: i == 0,
                          isCompleted: false,
                        ),
                    ],
                    selectedDate: selected,
                    today: today,
                    onDayTap: (day) => setState(() => selected = day.date),
                  ),
                ),
                // The body under the ribbon is a different widget per day,
                // the way the tab swaps between today and any other day.
                Expanded(
                  child: selected == today
                      ? const Text('today')
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L').at(2));
    await tester.pumpAndSettle();

    // Still on the second week: tapping a day must not throw the ribbon back
    // to the week today sits in.
    expect(find.text('L'), findsNWidgets(7));
    expect(find.text('U'), findsNothing);
  });
}
