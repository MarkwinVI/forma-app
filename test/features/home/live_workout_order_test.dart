import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/live_workout_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The workout runs the day in the order the program plans it. Holds carry a
/// skill-work section tag from the catalog, which the list used to group on —
/// floating an L-sit at the end of a plan up to the very top.
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

  /// A pull day as the program plans it: the two pulling trees, then core
  /// last — and core's L-sit step is tagged skill work in the catalog.
  DailyTrainingRecommendation pullDay() {
    final core = ExerciseCatalog.findById('core_foot_supported_l_sit')!;
    expect(core.programSection, ExerciseProgramSection.skillWork);

    return DailyTrainingRecommendation(
      programType: TrainingProgramType.pushPull,
      sessionType: TrainingSessionType.pull,
      sessionLabel: 'Pull Day',
      isRestDay: false,
      items: [
        itemFor('pullups_scapular_pull', TrainingTrack.verticalPull),
        itemFor('rows_vertical_rows', TrainingTrack.horizontalPull),
        itemFor('core_foot_supported_l_sit', TrainingTrack.core),
      ],
    );
  }

  testWidgets('the list keeps the plan order, holds included', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 6);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: LiveWorkoutView(recommendation: pullDay())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    double topOf(String name) =>
        tester.getTopLeft(find.text(name).first).dy;

    // The L-sit is third in the plan, so it is third on the screen — not
    // lifted above the pulling work by its skill-work tag.
    expect(
      topOf('Scapular Pull Ups'),
      lessThan(topOf('Inverted Row (Incline)')),
    );
    expect(
      topOf('Inverted Row (Incline)'),
      lessThan(topOf('L-Sit Hold (Foot-Supported)')),
    );
  });
}
