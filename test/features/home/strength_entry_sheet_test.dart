import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/home/program_setup_view.dart';

/// Direct entry for a starting-strength value: digits build the number, Done
/// hands it back clamped to the maximum, and nothing typed hands back null.
void main() {
  Future<Future<int?>> open(WidgetTester tester, {int? initial}) async {
    late Future<int?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                result = showModalBottomSheet<int?>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => StrengthEntrySheet(
                    label: 'Push-ups',
                    initial: initial,
                    max: 100,
                    unitSuffix: 'reps',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    // Fixed pumps: the sheet's rise, then a settled frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return result;
  }

  testWidgets('typed digits come back on Done', (tester) async {
    final result = await open(tester);
    expect(find.text('Push-ups'), findsOneWidget);
    await tester.tap(find.text('2').last);
    await tester.tap(find.text('5').last);
    await tester.pump();
    expect(find.text('25'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(await result, 25);
  });

  testWidgets('the value is clamped to the maximum', (tester) async {
    final result = await open(tester);
    for (final key in ['9', '9', '9']) {
      await tester.tap(find.text(key).last);
      await tester.pump();
    }
    expect(find.text('Maximum 100 reps'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(await result, 100);
  });

  testWidgets('Done with nothing typed changes nothing', (tester) async {
    final result = await open(tester, initial: 12);
    expect(find.text('12'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(await result, isNull);
  });
}
