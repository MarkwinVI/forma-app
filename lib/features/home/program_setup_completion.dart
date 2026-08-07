import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/program_start_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/user_profile_service.dart';
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
  UserProfileService? profileService,
}) async {
  final programService = trainingProgramService ?? TrainingProgramService();
  final store = storeService ?? TrainingProgramStoreService();

  await (profileService ?? UserProfileService()).updateBodyweightKg(
    userId,
    result.bodyweightKg,
  );

  // Locked goals are judged against the progress the user actually has:
  // a rebuild by someone who already cleared diamond push-ups keeps their
  // handstand push-up goal, a fresh account cannot smuggle one in.
  final existingProgress = {
    for (final progress in await ProgressService().fetchAll(userId))
      progress.exerciseId: progress.status,
  };

  final plan = ProgramStartPlanner.planFor(
    hasGym: result.hasGym,
    goalSkillIds: result.skillIds,
    startingStrength: result.startingStrength,
    existingProgress: existingProgress,
  );

  await store.updateProgramLogic(
    userId: userId,
    programType: result.split,
    // The legacy per-lane bridge mirrors the planned tracks — and only the
    // planned tracks. Spreading the lane defaults here once wrote core lanes
    // no track backed, and every lane-fallback surface then invented core
    // exercises the program didn't actually run.
    branchSelections: programService.laneSelectionsFromTracks([
      for (final entry in plan.tracks.entries)
        SkillTrack(
          skillCategoryId: entry.key,
          branchId: entry.value,
          included: true,
          updatedAt: DateTime.now(),
        ),
    ]),
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
