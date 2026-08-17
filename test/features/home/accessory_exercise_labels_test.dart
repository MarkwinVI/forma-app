import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_workout_editor_view.dart';
import 'package:google_fonts/google_fonts.dart';

/// Work that no tree schedules is called an accessory exercise throughout the
/// app — the row's tag, the row's subtitle, and the button that adds one.
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

  testWidgets('the day labels its non-tree work as accessory exercises',
      (tester) async {
    await pumpEditor(tester);

    // The pull day's gym accessory is the face pull; it wears the accessory
    // tag, never a skill-tree one.
    expect(find.text('Face Pull'), findsOneWidget);
    expect(find.text('Accessory'), findsOneWidget);
    expect(find.textContaining('Standalone'), findsNothing);

    // The pull-up step is still tagged to its tree.
    expect(find.text('Pullups Progression'), findsOneWidget);
  });

  testWidgets('the add button says what it adds', (tester) async {
    await pumpEditor(tester);

    await tester.ensureVisible(find.text('Add accessory exercise'));
    expect(find.text('Add accessory exercise'), findsOneWidget);
    expect(find.text('Add standalone exercise'), findsNothing);
  });
}
