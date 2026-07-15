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

  Widget host(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF111114),
        body: Center(
          child: SizedBox(width: 370, child: child),
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
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: 'painter failed for ${category.id}');
      expect(find.textContaining('node '), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('GOAL'), findsOneWidget);
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
            onTap: () {},
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
