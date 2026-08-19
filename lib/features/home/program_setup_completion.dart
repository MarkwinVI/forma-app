import 'package:flutter/foundation.dart';

import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/dev_clock_service.dart';
import '../../data/services/program_start_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../../data/services/training_schedule_service.dart';
import '../../data/services/user_profile_service.dart';
import '../progress/skill_wheel_bundle.dart';
import 'program_setup_view.dart';

/// Bumped every time setup writes a program. The tabs are kept alive in the
/// shell whether or not they are showing, so each one listens and re-reads
/// itself at once — while the wizard's ready screen is still up — rather
/// than waiting to be looked at and showing the empty state it last drew.
final ValueNotifier<int> programCreatedSignal = ValueNotifier(0);

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

  /// The day the program is built on — the dev clock's today where there is
  /// one, so a shifted clock lays the week out from the day it shows.
  DateTime? now,
}) async {
  final programService = trainingProgramService ?? TrainingProgramService();
  final store = storeService ?? TrainingProgramStoreService();

  await (profileService ?? UserProfileService()).updateBodyweightKg(
    userId,
    result.bodyweightKg,
  );

  final plan = ProgramStartPlanner.planFor(
    // Free weights count the same as a full gym here: everywhere the plan
    // chooses between a loaded and a bodyweight lift, the question is only
    // whether there is a bar to load.
    hasGym: result.hasWeights,
    // The wizard no longer asks about goal skills, so setup plans the default
    // branch of every tree. The planner still takes goals for whatever picks
    // them next; it just has none to work from here.
    goalSkillIds: const [],
    startingStrength: result.startingStrength,
    // The weighted squat branch's rung loads scale from bodyweight, so the
    // starting rung can only be placed with it.
    bodyweightKg: result.bodyweightKg,
  );

  final snapshot = await store.updateProgramLogic(
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
    setupAnswers: {
      ...result.toMap(),
      // The week is laid out from today: whichever day the program is built
      // on is a training day, and the rest keep the template's spacing. The
      // schedule sheet on the Program tab can move it afterwards.
      'training_days': TrainingScheduleService.weekTemplateStartingOn(
        result.daysPerWeek,
        (now ?? await DevClockService().loadNow()).weekday - 1,
      ),
    },
  );

  await (startService ?? ProgramStartService()).applyPlan(
    userId: userId,
    plan: plan,
  );

  // The wizard lands on Progress next. Start that tab's load now, while its
  // ready screen is still up, so Progress opens on the new program rather
  // than on the empty state it last showed and then catches up — and tell
  // the other tabs, which do the same.
  warmSkillWheelBundle(userId);
  programCreatedSignal.value += 1;

  AnalyticsService.capture('program_created', properties: {
    'program_id': snapshot.program.id,
    'days_per_week': result.daysPerWeek,
    'split': result.split.dbValue,
    'equipment': result.equipment.dbValue,
    'bodyweight_kg': result.bodyweightKg,
    // The wizard's reported strength, one property per answered exercise.
    for (final entry in result.startingStrength.entries)
      if (entry.value != null) 'starting_${entry.key}': entry.value!,
  });
}
