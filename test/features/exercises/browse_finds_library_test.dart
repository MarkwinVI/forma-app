import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/exercises/exercise_picker_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Browsing the library used to search the skill trees only, so a barbell
/// bench press — in the sheet, but not a step of any tree — could be typed in
/// full and still find nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  /// Searches, then scrolls the results until [expected] shows or the list
  /// runs out — the results are a lazily built list, so an unscrolled miss
  /// says nothing.
  Future<void> expectFound(
    WidgetTester tester,
    String query,
    String expected, {
    Widget page = const ExercisePickerView.browse(),
  }) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, query);
    await tester.pumpAndSettle();

    final target = find.text(expected);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        300,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 200,
      );
    }
    expect(target, findsOneWidget);
  }

  // The query never spells the name it should turn up, because the search
  // field renders its own text and `find.text` would match that instead of a
  // result — a check that passes whether or not anything was found.
  testWidgets('browsing finds a barbell bench press', (tester) async {
    await expectFound(tester, 'bench', 'Bench Press (Barbell)');
  });

  // Browsing is the library only: a scapular pull turns up as the movement
  // `scapular_pull_ups`, not as the pullups tree's step performed with it.
  // One entry per exercise, and the step adds nothing a reader wants.
  testWidgets('browsing finds a movement a tree is stepped through',
      (tester) async {
    await expectFound(tester, 'scapular', 'Scapular Pull Ups');
  });

  // Checked with a rung, because a rung is the one kind of step whose name is
  // its own rather than the movement's — so finding it could only mean the
  // steps had leaked into the library.
  testWidgets('browsing shows no skill-tree steps at all', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ExercisePickerView.browse()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'nverted row bodyweight');
    await tester.pumpAndSettle();

    expect(find.text('nverted Row (Bodyweight)'), findsNothing);
  });

  testWidgets('browsing finds accessory work with no tree at all',
      (tester) async {
    await expectFound(tester, 'curl', 'Bicep Curl (Barbell)');
  });

  // Picking is the library too: tree rungs enter a workout through their
  // skill track, not from the picker, so the picker offers each movement
  // once — "Inverted Row (Weighted)", not the ten rungs stepped through it.
  const picking = ExercisePickerView(excludedIds: {}, progressMap: {});

  testWidgets('picking finds the library movement', (tester) async {
    await expectFound(
      tester,
      'inverted row weighted',
      'Inverted Row (Weighted)',
      page: picking,
    );
  });

  testWidgets('picking shows no skill-tree rungs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: picking));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'nverted row bodyweight');
    await tester.pumpAndSettle();

    expect(find.text('nverted Row (Bodyweight)'), findsNothing);
  });

  // Skill work is not a movement pattern of its own in the filter — anything
  // that would have filed there sits under Other with the rest of the
  // library.
  testWidgets('the movement pattern filter offers no Skill option',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ExercisePickerView.browse()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All patterns'));
    await tester.pumpAndSettle();

    expect(find.text('Movement pattern'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('Skill'), findsNothing);
  });
}
