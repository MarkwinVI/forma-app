import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/live_workout_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The workout keeps a local draft of everything typed and ticked, so
/// opening the same workout again picks up where it left off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  TrainingRecommendationItem itemFor(String exerciseId, TrainingTrack track) {
    final exercise = ExerciseCatalog.findById(exerciseId)!;
    return TrainingRecommendationItem(
      track: track,
      exercise: exercise,
      status: ExerciseStatus.active,
      sourceCategory: exercise.category,
      sourceSkillCategoryId: exercise.skillCategoryId,
    );
  }

  DailyTrainingRecommendation pullDay() => DailyTrainingRecommendation(
        programType: TrainingProgramType.pushPull,
        sessionType: TrainingSessionType.pull,
        sessionLabel: 'Pull Day',
        isRestDay: false,
        items: [
          itemFor('pullups_scapular_pull', TrainingTrack.verticalPull),
          itemFor('rows_vertical_rows', TrainingTrack.horizontalPull),
        ],
      );

  Future<void> pumpWorkout(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 4);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: LiveWorkoutView(recommendation: pullDay())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// The text inside a rep field, which is a TextField under the keyed cell.
  String repText(WidgetTester tester, Finder field) => tester
      .widget<TextField>(
        find.descendant(of: field, matching: find.byType(TextField)),
      )
      .controller!
      .text;

  testWidgets('typed sets survive leaving and reopening the same workout',
      (tester) async {
    await pumpWorkout(tester);
    const id = 'rows_vertical_rows';
    await tester.enterText(find.byKey(const ValueKey('rep-$id-1')), '14');
    await tester.pump();
    // The draft is written shortly after the last edit.
    await tester.pump(const Duration(seconds: 1));

    // A fresh screen for the same workout — as after leaving the app.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(home: LiveWorkoutView(recommendation: pullDay())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Restored your unfinished sets'), findsOneWidget);
    expect(repText(tester, find.byKey(const ValueKey('rep-$id-1'))), '14');
  });

  testWidgets('an untouched workout leaves no draft behind', (tester) async {
    await pumpWorkout(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(home: LiveWorkoutView(recommendation: pullDay())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Restored your unfinished sets'), findsNothing);
  });
}
