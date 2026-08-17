import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/data/services/training_program_service.dart';
import 'package:forma_app/features/home/program_day_items.dart';

void main() {
  final service = TrainingProgramService();

  List<SkillTrack> tracks(Map<String, String> branchByCategory) => [
        for (final entry in branchByCategory.entries)
          SkillTrack(
            skillCategoryId: entry.key,
            branchId: entry.value,
            included: true,
            updatedAt: DateTime(2026, 8, 17),
          ),
      ];

  List<ProgramDayItem> dayFor(
    TrainingSessionType sessionType,
    Map<String, String> branchByCategory, {
    Map<String, dynamic> sessionItemsConfig = const {},
  }) {
    return ProgramSessionPlan.loadDay(
      service: service,
      sessionItemsConfig: sessionItemsConfig,
      programType: TrainingProgramType.pushPull,
      sessionType: sessionType,
      branchSelections: const {},
      progressMap: const {},
      skillTracks: tracks(branchByCategory),
      hasGym: true,
    );
  }

  group('where a day item says it came from', () {
    test('the gym accessories are standalone, not tree progressions', () {
      final pull = dayFor(TrainingSessionType.pull, {
        SkillCategoryCatalog.pullupsId: 'weighted',
        SkillCategoryCatalog.rowsId: 'front_lever',
        SkillCategoryCatalog.hingeId: 'weighted',
      });

      final facePull =
          pull.firstWhere((item) => item.exerciseId == 'face_pull');
      expect(facePull.kind, ProgramDayItemKind.exercise);
      expect(facePull.skillCategoryId, isNull);
      expect(facePull.branchId, isNull);

      final push = dayFor(TrainingSessionType.push, {
        SkillCategoryCatalog.pushupsId: 'planche',
        SkillCategoryCatalog.dipsId: 'weighted',
        SkillCategoryCatalog.squatId: 'weighted',
        SkillCategoryCatalog.coreId: 'l_sit',
      });

      final lateralRaise =
          push.firstWhere((item) => item.exerciseId == 'lateral_raise_dumbbell');
      expect(lateralRaise.kind, ProgramDayItemKind.exercise);
      expect(lateralRaise.skillCategoryId, isNull);
    });

    test('a step of an included tree still reads as its progression', () {
      final pull = dayFor(TrainingSessionType.pull, {
        SkillCategoryCatalog.pullupsId: 'weighted',
      });

      final pullup = pull.firstWhere(
        (item) => item.skillCategoryId == SkillCategoryCatalog.pullupsId,
      );
      expect(pullup.kind, ProgramDayItemKind.progression);
      expect(pullup.branchId, 'weighted');
    });

    test('a day saved with an accessory as a progression reads back standalone',
        () {
      // Days written before the accessories were classified correctly stored
      // them with an empty skill category; nothing schedules or advances them,
      // so they load as the standalone work they always were.
      final day = dayFor(
        TrainingSessionType.pull,
        const {},
        sessionItemsConfig: {
          'pull': {
            'strength': [
              {
                'id': 'track--face_pull',
                'kind': 'progression',
                'name': 'Face Pull',
                'skill_category_id': '',
                'branch_id': 'main',
                'exercise_id': 'face_pull',
                'sets': 3,
              },
            ],
          },
        },
      );

      expect(day, hasLength(1));
      expect(day.single.kind, ProgramDayItemKind.exercise);
      expect(day.single.exerciseId, 'face_pull');
      expect(day.single.name, 'Face Pull');
      expect(day.single.sets, 3);
    });
  });
}
