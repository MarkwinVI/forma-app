import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/widgets/workout_done_view.dart';

/// The finished-day burst loops its rings and sparks forever — unless the
/// system asks for reduced motion, when it holds a still frame instead.
void main() {
  setUpAll(() {
  });

  Widget host({required bool reduceMotion}) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: const Scaffold(
          body: WorkoutDoneView(nextTitle: 'Push Day', nextWhen: 'tomorrow'),
        ),
      );

  testWidgets('under Reduce Motion the burst holds still', (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    // Would time out against a looping controller.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('SESSION COMPLETE'), findsOneWidget);
  });

  testWidgets('otherwise the burst keeps looping', (tester) async {
    await tester.pumpWidget(host(reduceMotion: false));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
