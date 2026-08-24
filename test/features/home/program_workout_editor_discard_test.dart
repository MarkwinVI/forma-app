import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_workout_editor_view.dart';

/// Leaving the editor with unsaved edits asks first: keep editing is the
/// default, discard really leaves. A clean editor pops without a word.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
  });

  Future<void> pumpEditor(
    WidgetTester tester, {
    Future<void> Function(Map<String, dynamic>)? onSave,
  }) async {
    tester.view.physicalSize = const Size(900 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProgramWorkoutEditorView(
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
                      onSave: onSave ?? (_) async {},
                    ),
                  ),
                ),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    // The route transition, then the editor's own first frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> removeRow(WidgetTester tester, String name) async {
    final row = find.ancestor(of: find.text(name), matching: find.byType(Row));
    await tester.tap(
      find
          .descendant(
            of: row.last,
            matching: find.byIcon(Icons.more_horiz_rounded),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove exercise'));
    await tester.pumpAndSettle();
  }

  Future<void> tapBack(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('a clean editor pops straight back', (tester) async {
    await pumpEditor(tester);
    await tapBack(tester);
    expect(find.text('Open editor'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('an edited editor asks, and Keep editing stays', (tester) async {
    await pumpEditor(tester);
    await removeRow(tester, 'Face Pull');
    expect(find.text('Face Pull'), findsNothing);

    await tapBack(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text("Your edits to Pull haven't been saved."), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Open editor'), findsNothing);
    expect(find.text('Save Pull'), findsOneWidget);
  });

  testWidgets('Discard leaves without saving', (tester) async {
    var saved = false;
    await pumpEditor(tester, onSave: (_) async => saved = true);
    await removeRow(tester, 'Face Pull');
    await tapBack(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
    expect(saved, isFalse);
  });
}
