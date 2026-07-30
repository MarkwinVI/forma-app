import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/exercise_coaching_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/exercises/exercise_detail_view.dart';
import 'package:forma_app/features/skills/skill_tree_view.dart';
import 'package:forma_app/features/skills/widgets/exercise_preview_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A step in the tree opens the exercise. There used to be a preview sheet in
/// between that only repeated what the detail view already says.
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

  final category = SkillCategoryCatalog.findById(SkillCategoryCatalog.pullupsId)!;
  final firstStep = ExerciseCatalog.findById(
    category.pathFor(category.defaultTrainingPathId).first,
  )!;

  Widget host() => MaterialApp(
        home: SkillTreeView(
          skillCategoryId: category.id,
          progressMap: const <String, ExerciseStatus>{},
          onProgressChanged: (_, __) {},
        ),
      );

  testWidgets('tapping a step opens the exercise, with no sheet in between',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text(firstStep.name).first);
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseDetailView), findsOneWidget);
    expect(find.byType(ExercisePreviewSheet), findsNothing);
  });

  testWidgets('the opened exercise reads its own how-to, not the pattern default',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text(firstStep.name).first);
    await tester.pumpAndSettle();

    final coaching = ExerciseCoachingCatalog.forExercise(firstStep)!;
    expect(find.text(coaching.howTo.first), findsOneWidget);

    // The form checks sit below the fold of a lazily built list.
    await tester.scrollUntilVisible(
      find.text(coaching.formChecks.first),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(coaching.formChecks.first), findsOneWidget);
  });
}
