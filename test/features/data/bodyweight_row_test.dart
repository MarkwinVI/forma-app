import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/services/weight_unit_service.dart';
import 'package:forma_app/features/data/bodyweight_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    WeightUnitService.notifier.value = WeightUnit.kg;
  });

  Future<double?> openSheet(WidgetTester tester, {double? kg}) async {
    double? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  saved = await showBodyweightSheet(context, kg: kg);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return saved;
  }

  testWidgets('typing a value and saving returns canonical kilograms',
      (tester) async {
    double? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  saved = await showBodyweightSheet(context, kg: 74);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('BODYWEIGHT'), findsOneWidget);
    expect(find.text('74.0'), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(saved, 76);
  });

  testWidgets('the sheet unit toggle converts the value and sticks app-wide',
      (tester) async {
    await openSheet(tester, kg: 74);

    await tester.tap(find.text('lbs'));
    await tester.pump();

    // 74 kg reads as 163.1 lbs and the app-wide unit flips.
    expect(find.text('163.1'), findsOneWidget);
    expect(WeightUnitService.unit, WeightUnit.lb);
  });

  testWidgets('the row shows the stored weight in the active unit',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BodyweightRow(kg: 74, savedNow: false, onOpen: () {}),
        ),
      ),
    );
    expect(find.text('Bodyweight'), findsOneWidget);
    expect(find.text('74 kg'), findsOneWidget);

    WeightUnitService.notifier.value = WeightUnit.lb;
    await tester.pump();
    expect(find.text('163.1 lbs'), findsOneWidget);

    // No weight yet: the row invites rather than showing a number.
    WeightUnitService.notifier.value = WeightUnit.kg;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BodyweightRow(kg: null, savedNow: false, onOpen: () {}),
        ),
      ),
    );
    expect(find.text('Not set'), findsOneWidget);
  });
}
