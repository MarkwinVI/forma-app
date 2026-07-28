import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/progression_event_model.dart';
import 'package:forma_app/features/home/widgets/what_changed_card.dart';

void main() {
  ProgressionEvent raise(String exerciseId, {required DateTime on}) {
    return ProgressionEvent(
      id: 'e-$exerciseId',
      exerciseId: exerciseId,
      kind: ProgressionEventKind.targetIncrease,
      valueFrom: 6,
      valueTo: 7,
      targetSets: 3,
      createdAt: on,
    );
  }

  testWidgets('the updated line compresses the changes to one sentence',
      (tester) async {
    // A Tuesday, a week back — not today, so the line can name the day.
    final events = [
      raise('pull_up', on: DateTime(2026, 7, 21, 18)),
      raise('scapular_pull', on: DateTime(2026, 7, 21, 18)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WhatChangedLine(events: events, onTap: () {}),
        ),
      ),
    );

    expect(find.text('UPDATED'), findsOneWidget);
    expect(find.text('Two targets raised since Tuesday'), findsOneWidget);
    // No exercise names — a second list would compete with the session.
    expect(find.textContaining('Pull'), findsNothing);
  });

  testWidgets('the sheet gives the reason and what earned each raise',
      (tester) async {
    final events = [raise('pull_up', on: DateTime(2026, 7, 21, 18))];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showWhatChangedSheet(context, events),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('UPDATED AFTER TUESDAY'), findsOneWidget);
    expect(find.text('One target raised since Tuesday'), findsOneWidget);
    // No explanation paragraph — the raises say it themselves.
    expect(find.textContaining('moved the bar'), findsNothing);
    expect(find.text('hit 3 × 6'), findsOneWidget);
    expect(find.text('6 → 7'), findsOneWidget);
    expect(find.text('How targets are set'), findsOneWidget);
  });

  testWidgets('the finish receipt lists what moved', (tester) async {
    final events = [raise('pull_up', on: DateTime(2026, 7, 21, 18))];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TrainInsight(events: events)),
      ),
    );

    expect(find.text('WHAT THE PROGRAM CHANGED'), findsOneWidget);
    expect(find.text('target raised'), findsOneWidget);
    expect(find.text('6 → 7'), findsOneWidget);
  });
}
