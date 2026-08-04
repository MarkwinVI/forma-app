import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/program_start_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import 'program_setup_view.dart';

/// Everything a finished "Build your program" wizard writes, in one place so
/// the Train and Program tabs cannot drift apart on what setup means:
/// the program row (split, frequency, answers), the skill tracks the split
/// trains, and the starting position the reported strength implies.
Future<void> completeProgramSetup({
  required String userId,
  required ProgramSetupResult result,
  TrainingProgramService? trainingProgramService,
  TrainingProgramStoreService? storeService,
  ProgramStartService? startService,
}) async {
  final programService = trainingProgramService ?? TrainingProgramService();
  final store = storeService ?? TrainingProgramStoreService();

  final plan = ProgramStartPlanner.planFor(
    hasGym: result.hasGym,
    goalSkillIds: result.skillIds,
    startingStrength: result.startingStrength,
  );

  await store.updateProgramLogic(
    userId: userId,
    programType: result.split,
    // The legacy per-lane bridge mirrors the planned tracks, so the views
    // that still read lanes agree with the tracks the program actually runs.
    branchSelections: {
      ...programService.defaultBranchSelections(),
      ...programService.laneSelectionsFromTracks([
        for (final entry in plan.tracks.entries)
          SkillTrack(
            skillCategoryId: entry.key,
            branchId: entry.value,
            included: true,
            updatedAt: DateTime.now(),
          ),
      ]),
    },
    repGoalProfile: RepGoalProfile.balanced,
    sessionItemsConfig: const {},
    frequencyPerWeek: result.daysPerWeek,
    setupAnswers: result.toMap(),
  );

  await (startService ?? ProgramStartService()).applyPlan(
    userId: userId,
    plan: plan,
  );
}
