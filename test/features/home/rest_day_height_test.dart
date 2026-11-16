import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/widgets/program_day_card.dart';
import 'package:forma_app/features/home/widgets/week_widgets.dart';

void main() {
  testWidgets('a done card is as tall as the rest day card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                RestDayCard(
                  key: const Key('rest'),
                  nextTitle: 'Pull Day',
                  nextWhen: 'tomorrow',
                  onStartToday: () {},
                ),
                RestDayHeight(
                  key: const Key('done'),
                  child: ProgramDayCard(
                    fillBody: true,
                    body: const WeekDoneBody(
                      fill: true,
                      title: 'Done for today',
                      line: 'Push Day is logged. One more session this week.',
                    ),
                    actions: ProgramCardActions(
                      label: 'View completed workout',
                      quiet: true,
                      onPrimary: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final rest = tester.getSize(find.byKey(const Key('rest')));
    final done = tester.getSize(find.byKey(const Key('done')));
    expect(done.height, rest.height);

    // The action sits on the card's bottom edge, the words above it.
    final card = tester.getRect(find.byKey(const Key('done')));
    final action = tester.getRect(find.text('View completed workout'));
    expect(card.bottom - action.bottom, lessThan(40));
    expect(tester.takeException(), isNull);
  });
}
