import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_workout_editor_view.dart';
import 'package:google_fonts/google_fonts.dart';

/// Auto progression is stated on every exercise's menu, and editable on the
/// ones it can actually manage: accessories measured in reps × weight. A
/// skill-tree step shows it on and untouchable — its tree does the managing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    // Wide surface: the test font is far wider per glyph than the real one,
    // so a phone-width view overflows rows that fit fine on a device.
    tester.view.physicalSize = const Size(900 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ProgramWorkoutEditorView(
          sessionType: TrainingSessionType.pull,
          programType: TrainingProgramType.pushPull,
          branchSelections: const {},
          progressMap: const {},
          sessionItemsConfig: const {},
          skillTracks: [
            SkillTrack(
              skillCategoryId: SkillCategoryCatalog.pullupsId,
              branchId: 'weighted',
              included: true,
              updatedAt: DateTime(2026, 8, 17),
            ),
          ],
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the options menu of the row holding [name].
  Future<void> openMenuFor(WidgetTester tester, String name) async {
    final row = find.ancestor(
      of: find.text(name),
      matching: find.byType(Row),
    );
    await tester.tap(
      find
          .descendant(of: row.last, matching: find.byIcon(Icons.more_horiz_rounded))
          .first,
    );
    await tester.pumpAndSettle();
  }

  Switch switchIn(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  testWidgets('an accessory lifted for reps and weight can be switched off',
      (tester) async {
    await pumpEditor(tester);
    // The pull day's gym accessory: a cable face pull, reps × weight.
    await openMenuFor(tester, 'Face Pull');

    expect(find.text('Auto progression'), findsOneWidget);
    expect(
      find.text(
        'Forma automatically manages your reps and weight as you progress.',
      ),
      findsOneWidget,
    );

    // On by default, and the user's to turn off.
    expect(switchIn(tester).value, isTrue);
    expect(switchIn(tester).onChanged, isNotNull);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // The sheet stays open and answers at once — turning it off is not a
    // reason to leave the menu.
    expect(find.text('Auto progression'), findsOneWidget);
    expect(switchIn(tester).value, isFalse);
  });

  testWidgets('a skill-tree step shows it on, and will not let go',
      (tester) async {
    await pumpEditor(tester);
    await openMenuFor(tester, 'Scapular Pull Ups');

    expect(find.text('Auto progression'), findsOneWidget);
    expect(switchIn(tester).value, isTrue);
    expect(
      switchIn(tester).onChanged,
      isNull,
      reason: 'the tree manages a progression, not the user',
    );
  });
}
