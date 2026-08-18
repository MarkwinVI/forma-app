import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/progress/performance_overview.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_panels.dart';

Widget _host(PerformanceOverview overview) => MaterialApp(
      home: Scaffold(
        body: PerformancePanel(overview: overview, bottomInset: 0),
      ),
    );

void main() {
  testWidgets('tapping a row pushes the exercise page', (tester) async {
    // The exercise page reads from Supabase as it builds, so the test stops
    // at the push: a route goes on for the row that was tapped. One tap per
    // pump — the pushed page covers the panel afterwards.
    Future<void> tapRow(String name) async {
      final pushed = <Route<dynamic>>[];
      // A fresh app per row: the first push's page would otherwise still be
      // sitting over the panel.
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(name),
        navigatorObservers: [_PushRecorder(pushed)],
        home: const Scaffold(
          body: PerformancePanel(
            overview: PerformanceOverview(
              rows: [
                PerformanceRowData(
                  exerciseId: 'pullups_pull_up',
                  exerciseName: 'Pull Up',
                  isTimed: false,
                  bestValue: 24,
                  delta: 3,
                  daysTrained: 2,
                ),
                PerformanceRowData(
                  exerciseId: 'dips_bench_dips',
                  exerciseName: 'Bench Dips',
                  isTimed: false,
                  bestValue: 10,
                  daysTrained: 1,
                ),
              ],
            ),
            bottomInset: 0,
          ),
        ),
      ));
      pushed.clear();
      await tester.tap(find.text(name));
      await tester.pump();
      expect(pushed, hasLength(1), reason: name);
      expect(pushed.single, isA<MaterialPageRoute<void>>());
      // The page behind the push cannot build here; the error it throws is
      // not the subject of this test.
      tester.takeException();
    }

    // A row with a trend, and one still building its baseline — both open.
    await tapRow('Pull Up');
    await tapRow('Bench Dips');
  });

  testWidgets('a four-figure kilogram delta fits its box', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [
        PerformanceRowData(
          exerciseId: 'row',
          exerciseName: 'Bent Over Row (Barbell)',
          isTimed: false,
          isWeighted: true,
          bestValue: 2880,
          delta: -1520,
          daysTrained: 2,
        ),
      ],
    )));

    // No overflow, and the kilogram figures read compacted.
    expect(tester.takeException(), isNull);
    expect(find.text('2.9k kg'), findsOneWidget);
    expect(find.text('−1.5k'), findsOneWidget);
  });

  test('compact numbers read whole under a thousand, then in thousands', () {
    expect(compactNumber(960), '960');
    expect(compactNumber(999.6), '1000');
    expect(compactNumber(1000), '1k');
    expect(compactNumber(1520), '1.5k');
    expect(compactNumber(2880), '2.9k');
    expect(compactNumber(9960), '10k');
    expect(compactNumber(12400), '12k');
  });

  testWidgets('groups rows by trend with best set and delta', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [
        _RowsFixture.up,
        _RowsFixture.flat,
        _RowsFixture.down,
      ],
    )));

    expect(find.text('MY PERFORMANCE'), findsOneWidget);
    expect(find.text('LAST SESSION VS PREVIOUS SESSION'), findsOneWidget);

    expect(find.text('IMPROVING'), findsOneWidget);
    expect(find.text('Assisted Pull-up'), findsOneWidget);
    expect(find.text('21 reps'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);

    expect(find.text('NO CHANGE'), findsOneWidget);
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    expect(find.text('DECLINING'), findsOneWidget);
    expect(find.text('9s'), findsOneWidget);
    expect(find.text('−2'), findsOneWidget);
  });

  testWidgets('empty groups stay off the panel', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [_RowsFixture.up],
    )));

    expect(find.text('IMPROVING'), findsOneWidget);
    expect(find.text('NO CHANGE'), findsNothing);
    expect(find.text('DECLINING'), findsNothing);
    expect(find.text('BUILDING BASELINE'), findsNothing);
  });

  testWidgets('exercises without a baseline sit in a quiet group with day '
      'counters', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [
        _RowsFixture.up,
        _RowsFixture.oneDay,
        _RowsFixture.neverTrained,
      ],
    )));

    expect(find.text('IMPROVING'), findsOneWidget);
    expect(find.text('BUILDING BASELINE'), findsOneWidget);
    expect(find.text('Handstand'), findsOneWidget);
    expect(find.text('1 OF 2 DAYS'), findsOneWidget);
    expect(find.text('0 OF 2 DAYS'), findsOneWidget);
    expect(
      find.text(
        'Trends appear after an exercise is trained on two separate days.',
      ),
      findsOneWidget,
    );
    // Baseline rows show no best-set value.
    expect(find.text('Last session:'), findsOneWidget);
  });

  testWidgets('without any baseline the panel shows the building-baseline '
      'group instead of an explainer', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [_RowsFixture.oneDay, _RowsFixture.neverTrained],
    )));

    expect(
      find.text('TRAIN AN EXERCISE ON TWO SEPARATE DAYS'),
      findsNothing,
    );
    // The how-trends-start line leads the panel — and only appears once.
    expect(
      find.text(
        'Trends appear after an exercise is trained on two separate days.',
      ),
      findsOneWidget,
    );
    expect(find.text('BUILDING BASELINE'), findsOneWidget);
    expect(find.text('Handstand'), findsOneWidget);
    expect(find.text('Ring Row'), findsOneWidget);
    expect(find.text('1 OF 2 DAYS'), findsOneWidget);
    expect(find.text('0 OF 2 DAYS'), findsOneWidget);
  });
}

abstract final class _RowsFixture {
  static const up = PerformanceRowData(
    exerciseId: 'pullup',
    exerciseName: 'Assisted Pull-up',
    isTimed: false,
    bestValue: 21,
    delta: 4,
    daysTrained: 2,
  );
  static const flat = PerformanceRowData(
    exerciseId: 'pushup',
    exerciseName: 'Push-up',
    isTimed: false,
    bestValue: 12,
    delta: 0,
    daysTrained: 2,
  );
  static const down = PerformanceRowData(
    exerciseId: 'planche',
    exerciseName: 'Tuck Planche',
    isTimed: true,
    bestValue: 9,
    delta: -2,
    daysTrained: 2,
  );
  static const oneDay = PerformanceRowData(
    exerciseId: 'handstand',
    exerciseName: 'Handstand',
    isTimed: true,
    bestValue: 15,
    daysTrained: 1,
  );
  static const neverTrained = PerformanceRowData(
    exerciseId: 'row',
    exerciseName: 'Ring Row',
    isTimed: false,
    bestValue: 0,
  );
}

/// Records every route pushed onto the navigator under test.
class _PushRecorder extends NavigatorObserver {
  final List<Route<dynamic>> pushed;
  _PushRecorder(this.pushed);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}
