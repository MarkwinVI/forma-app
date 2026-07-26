import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/skill_category_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/home_dashboard_metrics.dart';
import 'package:forma_app/features/progress/widgets/skill_tree_progress_card.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  JourneySkillProgressData skillData(SkillCategory category, String branchId) {
    return JourneySkillProgressData(
      track: TrainingTrack.verticalPull,
      skillCategoryId: category.id,
      branchId: branchId,
      motionLabel: category.title,
      skillTitle: category.title,
      currentExerciseName: 'Weighted Pull-up',
      nextExerciseName: 'Archer Pull-up',
      targetVolume: 8,
      lastSessionVolume: 6,
      targetLabel: '8 reps',
      lastLabel: '6 reps',
      lastSessionDeltaLabel: '+0',
      lastSessionTrend: JourneySkillTrend.flat,
      progressPercent: 0.52,
      stages: const [],
    );
  }

  Map<String, ExerciseStatus> progressFor(
    SkillCategory category,
    String branchId,
  ) {
    final path = category.pathFor(branchId);
    final map = <String, ExerciseStatus>{};
    for (var index = 0; index < path.length && index < 3; index++) {
      map[path[index]] =
          index < 2 ? ExerciseStatus.mastered : ExerciseStatus.active;
    }
    return map;
  }

  Widget host(Widget child, {double width = 370}) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF111114),
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('renders every catalog tree without errors', (tester) async {
    for (final category in SkillCategoryCatalog.browsable()) {
      final branchId = category.defaultTrainingPathId;
      await tester.pumpWidget(
        host(
          SkillTreeProgressCard(
            skill: skillData(category, branchId),
            category: category,
            progressMap: progressFor(category, branchId),
            stalled: false,
            expanded: true,
            onToggleExpanded: () {},
            onOpenTree: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'painter failed for ${category.id}');
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('Weighted Pull-up'), findsOneWidget);
      expect(find.text('Archer Pull-up'), findsOneWidget);
    }
  });

  testWidgets('collapsed card shows the unlock and the current → next step',
      (tester) async {
    final category = SkillCategoryCatalog.browsable().first;
    await tester.pumpWidget(
      host(
        SkillTreeProgressCard(
          skill: skillData(category, category.defaultTrainingPathId),
          category: category,
          progressMap: const {},
          stalled: false,
          expanded: false,
          onToggleExpanded: () {},
          onOpenTree: () {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(category.title), findsOneWidget);
    expect(find.textContaining('2 reps', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Archer Pull-up', findRichText: true),
      findsOneWidget,
    );
    // The map and its rail belong to the expanded card only.
    expect(find.text('NOW'), findsNothing);
  });

  testWidgets('header toggles expansion instead of opening the tree view',
      (tester) async {
    final category = SkillCategoryCatalog.browsable().first;
    final branchId = category.defaultTrainingPathId;
    var toggles = 0;
    var opens = 0;

    Widget card({required bool expanded}) => host(
          SkillTreeProgressCard(
            skill: skillData(category, branchId),
            category: category,
            progressMap: progressFor(category, branchId),
            stalled: false,
            expanded: expanded,
            onToggleExpanded: () => toggles++,
            onOpenTree: () => opens++,
          ),
        );

    // Expanded: the header collapses, the map opens the full tree.
    await tester.pumpWidget(card(expanded: true));
    await tester.pump();
    await tester.tap(find.text(category.title));
    await tester.pump();
    expect(toggles, 1);
    expect(opens, 0);

    await tester.tap(find.byType(CustomPaint).last);
    await tester.pump();
    expect(opens, 1);
    expect(toggles, 1);

    // Collapsed: tapping anywhere expands, it never navigates.
    await tester.pumpWidget(card(expanded: false));
    await tester.pump();
    await tester.tap(find.text(category.title));
    await tester.pump();
    expect(toggles, 2);
    expect(opens, 1);
  });

  testWidgets('both card states survive narrow phones and long names',
      (tester) async {
    const longSkill = JourneySkillProgressData(
      track: TrainingTrack.squat,
      skillCategoryId: 'squat',
      branchId: 'main',
      motionLabel: 'Squat',
      skillTitle: 'Squat',
      currentExerciseName: 'Bulgarian Split Squat with a Very Long Name',
      nextExerciseName: 'Advanced Elevated Pike Pushup Progression',
      targetVolume: 24,
      lastSessionVolume: 21,
      targetLabel: '24 reps',
      lastLabel: '21 reps',
      lastSessionDeltaLabel: '+1',
      lastSessionTrend: JourneySkillTrend.up,
      progressPercent: 0.875,
      stages: [],
    );

    for (final width in const [288.0, 320.0, 358.0]) {
      for (final category in SkillCategoryCatalog.browsable()) {
        await tester.pumpWidget(
          host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SkillTreeProgressCard(
                  skill: longSkill,
                  category: category,
                  progressMap: const {},
                  stalled: true,
                  expanded: true,
                  onToggleExpanded: () {},
                  onOpenTree: () {},
                ),
                SkillTreeProgressCard(
                  skill: longSkill,
                  category: category,
                  progressMap: const {},
                  stalled: false,
                  expanded: false,
                  onToggleExpanded: () {},
                  onOpenTree: () {},
                ),
              ],
            ),
            width: width,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: 'overflow for ${category.id} at $width');
      }
    }
  });

  testWidgets('captures a preview image of the pull-up tree card',
      (tester) async {
    final category = SkillCategoryCatalog.browsable().first;
    final branchId = category.defaultTrainingPathId;
    final key = GlobalKey();

    await tester.pumpWidget(
      host(
        RepaintBoundary(
          key: key,
          child: SkillTreeProgressCard(
            skill: skillData(category, branchId),
            category: category,
            progressMap: progressFor(category, branchId),
            stalled: true,
            expanded: true,
            onToggleExpanded: () {},
            onOpenTree: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/skill_tree_card_preview.png');
      out.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
