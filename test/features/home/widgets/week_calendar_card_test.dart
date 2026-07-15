import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/home/widgets/week_calendar_card.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows a cell per cycle day with training and rest states',
      (tester) async {
    final monday = DateTime(2026, 7, 13);
    final strip = HomeWeekStripData(
      days: [
        HomeWeekStripDay(
          date: monday,
          sessionType: TrainingSessionType.push,
          isCurrent: false,
          isCompleted: true,
        ),
        HomeWeekStripDay(
          date: monday.add(const Duration(days: 1)),
          sessionType: TrainingSessionType.rest,
          isCurrent: false,
          isCompleted: false,
        ),
        HomeWeekStripDay(
          date: monday.add(const Duration(days: 2)),
          sessionType: TrainingSessionType.pull,
          isCurrent: true,
          isCompleted: false,
        ),
        HomeWeekStripDay(
          date: monday.add(const Duration(days: 3)),
          sessionType: TrainingSessionType.fullBody,
          isCurrent: false,
          isCompleted: false,
        ),
      ],
      completedSessions: 1,
      totalSessions: 3,
      supportingText: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 370,
              child: WeekCalendarCard(weekStrip: strip),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
    // Full Body is shortened to fit the cell.
    expect(find.text('Full'), findsOneWidget);
    // The completed day renders a check instead of a dot.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
