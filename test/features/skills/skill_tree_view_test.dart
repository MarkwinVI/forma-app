import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/theme/app_colors.dart';
import 'package:forma_app/core/widgets/skill_tree_map.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/skill_category_model.dart';
import 'package:forma_app/features/skills/skill_tree_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Map<String, ExerciseStatus> progressFor(SkillCategory category) {
    final path = category.pathFor(category.defaultTrainingPathId);
    return {
      for (var index = 0; index < path.length && index < 3; index++)
        path[index]:
            index < 2 ? ExerciseStatus.mastered : ExerciseStatus.active,
    };
  }

  // A fresh key per category: SkillTreeView reads its category in initState,
  // so reusing the element would keep showing the previous tree.
  Widget host(SkillCategory category) => MaterialApp(
        home: SkillTreeView(
          key: ValueKey(category.id),
          skillCategoryId: category.id,
          progressMap: progressFor(category),
          onProgressChanged: (_, __) {},
        ),
      );

  /// Section headings are the 22pt titles in the list; the selected one is the
  /// only one painted in the primary text colour.
  Iterable<Text> sectionTitles(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => text.style?.fontSize == 22);

  testWidgets('every tree pins its map above the full list of routes',
      (tester) async {
    for (final category in SkillCategoryCatalog.browsable()) {
      await tester.pumpWidget(host(category));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: category.id);
      expect(find.byType(SkillTreeMap), findsOneWidget, reason: category.id);
      // One section per branch, plus the foundation when the branches share
      // an opening step (Core's don't — they fork immediately).
      final paths = category.trainingPaths.values.toList();
      final hasFoundation = paths.length > 1 &&
          paths.every((path) => path.isNotEmpty) &&
          paths.every((path) => path.first == paths.first.first);
      expect(
        sectionTitles(tester).length,
        (paths.length > 1 ? paths.length : 1) + (hasFoundation ? 1 : 0),
        reason: category.id,
      );
      // The first route is the one selected on arrival.
      expect(
        sectionTitles(tester).first.style?.color,
        AppColors.textPrimary,
        reason: category.id,
      );
    }
  });

  testWidgets('tapping a branch on the map selects that route', (tester) async {
    final category = SkillCategoryCatalog.browsable().firstWhere(
      (item) =>
          item.trainingPaths.length > 1 &&
          item.trainingPaths.values.every(
            (path) => path.first == item.trainingPaths.values.first.first,
          ),
    );

    await tester.pumpWidget(host(category));
    await tester.pump();

    expect(sectionTitles(tester).first.data, 'Foundation');
    expect(sectionTitles(tester).first.style?.color, AppColors.textPrimary);

    await tester.tap(
      find
          .descendant(
            of: find.byType(SkillTreeMap),
            matching: find.byType(GestureDetector),
          )
          .last,
    );
    await tester.pumpAndSettle();

    // The map stays put — selection moved off the foundation onto a branch.
    expect(find.byType(SkillTreeMap), findsOneWidget);
    final selected = sectionTitles(tester)
        .where((text) => text.style?.color == AppColors.textPrimary);
    expect(selected.length, 1);
    expect(selected.first.data, isNot('Foundation'));
  });

  testWidgets('steps report where they stand in the route', (tester) async {
    final category = SkillCategoryCatalog.browsable().firstWhere(
      (item) =>
          item.trainingPaths.length > 1 &&
          item.trainingPaths.values.every(
            (path) => path.first == item.trainingPaths.values.first.first,
          ),
    );

    await tester.pumpWidget(host(category));
    await tester.pump();

    // Two mastered, one active — everything ahead of them reads as locked.
    expect(find.text('MASTERED'), findsNWidgets(2));
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('NEXT UP'), findsNothing);
    expect(find.text('LOCKED'), findsWidgets);
  });
}
