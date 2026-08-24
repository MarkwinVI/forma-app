import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/forma_splash.dart';

void main() {
  testWidgets('plays once before completing', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: FormaSplash(onDone: () => completed = true),
      ),
    );

    expect(find.text('FORMA'), findsOneWidget);
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 2499));
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(completed, isTrue);
  });

  reduceMotionTests();
  endFrameTests();
}

/// Reduce Motion: the mark holds its lit frame instead of running, and the
/// app still moves on.
void reduceMotionTests() {
  testWidgets('holds still and completes under Reduce Motion', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: FormaSplash(onDone: () => completed = true),
        ),
      ),
    );
    expect(find.text('FORMA'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(completed, isTrue);
  });
}

/// The end frame: the lit mark and wordmark held still, nothing scheduled,
/// on whatever ground the page hands it.
void endFrameTests() {
  testWidgets('endFrame holds the lit mark with no animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FormaSplash.endFrame(background: Color(0xFF111114)),
      ),
    );
    expect(find.text('FORMA'), findsOneWidget);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FormaSplash),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, const Color(0xFF111114));

    // No frames are scheduled: pumping far ahead settles immediately and
    // the wordmark is still up.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('FORMA'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
