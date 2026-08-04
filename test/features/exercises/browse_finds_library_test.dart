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
    await tester.enterText(find.byType(TextField).first, 'bodyweight 3x10');
    await tester.pumpAndSettle();

    expect(find.text('Bodyweight (3x10)'), findsNothing);
  });

  testWidgets('browsing finds accessory work with no tree at all',
      (tester) async {
    await expectFound(tester, 'curl', 'Bicep Curl (Barbell)');
  });

  // Picking shows the step rather than the movement, and a rung is named for
  // the load it asks for rather than the movement — "Bodyweight (3x10)" is a
  // rung of the weighted inverted row — so it answers to the movement's name
  // as well, which is the name most people would type.
  const picking = ExercisePickerView(excludedIds: {}, progressMap: {});

  testWidgets('picking finds a rung by the movement behind it',
      (tester) async {
    await expectFound(
      tester,
      'inverted row weighted',
      'Bodyweight (3x10)',
      page: picking,
    );
  });

  testWidgets('picking finds that rung by its own name too', (tester) async {
    await expectFound(
      tester,
      'bodyweight 3x10',
      'Bodyweight (3x10)',
      page: picking,
    );
  });
}
