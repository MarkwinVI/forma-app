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
  testWidgets('groups rows by trend with best set and delta', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [
        _RowsFixture.up,
        _RowsFixture.flat,
        _RowsFixture.down,
        _RowsFixture.fresh,
      ],
      comparesRecentSessions: false,
    )));

    expect(find.text('MY PERFORMANCE'), findsOneWidget);
    expect(find.text('LAST 14 DAYS VS PREV. 14 DAYS'), findsOneWidget);

    expect(find.text('IMPROVING'), findsOneWidget);
    expect(find.text('Assisted Pull-up'), findsOneWidget);
    expect(find.text('21 reps'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);

    expect(find.text('NO CHANGE'), findsOneWidget);
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(find.text('9s'), findsOneWidget);
    expect(find.text('−2'), findsOneWidget);

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('Handstand'), findsOneWidget);
  });

  testWidgets('empty groups stay off the panel', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [_RowsFixture.up],
      comparesRecentSessions: false,
    )));

    expect(find.text('IMPROVING'), findsOneWidget);
    expect(find.text('NO CHANGE'), findsNothing);
    expect(find.text('NEEDS ATTENTION'), findsNothing);
    expect(find.text('NEW'), findsNothing);
  });

  testWidgets('without comparisons everything is NEW plus the train-first '
      'note', (tester) async {
    await tester.pumpWidget(_host(const PerformanceOverview(
      rows: [_RowsFixture.fresh, _RowsFixture.neverTrained],
      comparesRecentSessions: true,
    )));

    expect(find.text('LATEST SESSION VS PREV. SESSIONS'), findsOneWidget);
    expect(
      find.textContaining("Once you've trained a bit"),
      findsOneWidget,
    );
    expect(find.text('NEW'), findsOneWidget);
    // A never-trained exercise shows no best-set value.
    expect(find.text('—'), findsOneWidget);
  });
}

abstract final class _RowsFixture {
  static const up = PerformanceRowData(
    exerciseId: 'pullup',
    exerciseName: 'Assisted Pull-up',
    isTimed: false,
    bestValue: 21,
    delta: 4,
  );
  static const flat = PerformanceRowData(
    exerciseId: 'pushup',
    exerciseName: 'Push-up',
    isTimed: false,
    bestValue: 12,
    delta: 0,
  );
  static const down = PerformanceRowData(
    exerciseId: 'planche',
    exerciseName: 'Tuck Planche',
    isTimed: true,
    bestValue: 9,
    delta: -2,
  );
  static const fresh = PerformanceRowData(
    exerciseId: 'handstand',
    exerciseName: 'Handstand',
    isTimed: true,
    bestValue: 15,
  );
  static const neverTrained = PerformanceRowData(
    exerciseId: 'row',
    exerciseName: 'Ring Row',
    isTimed: false,
    bestValue: 0,
  );
}
