
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/skill_track_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/skill_track_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_schedule_service.dart';
import '../progress/skill_wheel_data.dart';
import 'program_balance_view.dart';
import 'program_setup_view.dart';
import 'program_day_items.dart';
import 'program_faq.dart';
import 'program_skill_trees_section.dart';
import 'program_skill_wheel_view.dart';
import 'program_week_strip.dart';
import 'program_workout_editor_view.dart';

class ProgramOverviewView extends StatefulWidget {
  final TrainingProgramLogicSnapshot initialLogic;
  final Map<String, ExerciseStatus> progressMap;
  final Future<TrainingProgramLogicSnapshot> Function({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
  }) onSave;

  const ProgramOverviewView({
    super.key,
    required this.initialLogic,
    required this.progressMap,
    required this.onSave,
  });

  @override
  State<ProgramOverviewView> createState() => _ProgramOverviewViewState();
}

class _ProgramOverviewViewState extends State<ProgramOverviewView> {
  final _programService = TrainingProgramService();
  final _skillTrackService = SkillTrackService();

  late TrainingProgramLogicSnapshot _logic;

  /// Skills-as-tracks state, loaded here so the tab reflects adds/pauses
  /// immediately. Status edits from the adjust sheet land in
  /// [_progressOverrides] on top of the read-only widget.progressMap.
  List<SkillTrack> _skillTracks = const [];
  final Map<String, ExerciseStatus> _progressOverrides = {};

  /// Temporarily hides the "Skill tracks" section from the Program tab. The
  /// tracks themselves still load — sessions and lane selections depend on
  /// them — only the UI is off.
  final bool _showSkillTracksSection = false;

  Map<String, ExerciseStatus> get _progress => {
        ...widget.progressMap,
        ..._progressOverrides,
      };

  @override
  void initState() {
    super.initState();
    _logic = widget.initialLogic;
    _loadSkillTracks();
  }

  Future<void> _loadSkillTracks() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      final tracks = await _skillTrackService.getOrSeed(
        userId,
        laneSelections: _branchSelections,
        goalSkillIds: _logic.program.setupGoalIds,
      );
      if (!mounted) return;
      setState(() => _skillTracks = tracks);
    } catch (error, stackTrace) {
      debugPrint('Failed to load skill tracks: $error\n$stackTrace');
    }
  }

  Map<String, dynamic> get _sessionItemsConfig {
    final raw = _logic.program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Map<String, dynamic> get _setupAnswers {
    final raw = _logic.program.variationRules['program_setup_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  int get _trainingDaysPerWeek => _dayMask.where((day) => day == 1).length;

  /// The week as the user laid it out, falling back to the template for their
  /// session count while they have never touched the calendar.
  List<int> get _dayMask => TrainingScheduleService().weekTemplateFor(
        _logic.program.frequencyPerWeek,
        dayMask: TrainingScheduleService.normalizeDayMask(
          _setupAnswers['training_days'],
        ),
      );

  Map<TrainingTrack, String> get _branchSelections => {
        ..._programService.defaultBranchSelections(),
        ..._logic.branchSelections,
        // Lane-keyed view of the skill tracks for lane-based consumers
        // (day editor, weekly balance).
        ..._programService.laneSelectionsFromTracks(_skillTracks),
      };

  List<TrainingSessionType> _weekPlan(
      List<int> mask, TrainingProgramType type) {
    return TrainingScheduleService().cycleFor(
      programType: type,
      frequencyPerWeek: mask.where((day) => day == 1).length,
      dayMask: mask,
    );
  }

  Future<void> _saveLogic({
    TrainingProgramType? programType,
    Map<String, dynamic>? sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
    required String toast,
  }) async {
    final updated = await widget.onSave(
      programType: programType ?? _logic.program.programType,
      branchSelections: _branchSelections,
      repGoalProfile: _logic.repGoalProfile,
      sessionItemsConfig: sessionItemsConfig ?? _sessionItemsConfig,
      frequencyPerWeek: frequencyPerWeek,
      setupAnswers: setupAnswers,
    );
    if (!mounted) return;
    setState(() => _logic = updated);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(toast)));
  }

  Future<void> _openWorkoutEditor(TrainingSessionType sessionType) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramWorkoutEditorView(
          sessionType: sessionType,
          programType: _logic.program.programType,
          branchSelections: _branchSelections,
          progressMap: widget.progressMap,
          sessionItemsConfig: _sessionItemsConfig,
          hasGym: _hasGym,
          skillTracks: _skillTracks,
          onSave: (config) => _saveLogic(
            sessionItemsConfig: config,
            toast: '${programWorkoutTypeName(sessionType)} updated',
          ),
        ),
      ),
    );
  }

  Future<void> _openDaysSheet() async {
    final picked = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _DaysSheet(
        currentMask: _dayMask,
        weekPlanBuilder: (mask) => _weekPlan(mask, _logic.program.programType),
      ),
    );

    if (picked == null || !mounted) return;

    final days = picked.where((day) => day == 1).length;
    // Both the count and the week itself are stored: the count drives volume
    // and streak targets, the mask decides which days actually train.
    await _saveLogic(
      frequencyPerWeek: days,
      setupAnswers: {
        ..._setupAnswers,
        'days_per_week': days,
        'training_days': picked,
      },
      toast: 'Schedule updated',
    );
  }

  Future<void> _openSplitSheet() async {
    final picked = await showModalBottomSheet<TrainingProgramType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _SplitSheet(current: _logic.program.programType),
    );

    if (picked == null || picked == _logic.program.programType || !mounted) {
      return;
    }

    // Changing the split rebuilds every day plan from the defaults for the
    // new split — an empty config makes the service fall back to them.
    await _saveLogic(
      programType: picked,
      sessionItemsConfig: const {},
      setupAnswers: {..._setupAnswers, 'split': picked.dbValue},
      toast: 'Split changed — sessions rebuilt',
    );
  }

  Future<void> _openEquipmentSheet() async {
    final picked = await showModalBottomSheet<SetupEquipment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _EquipmentSheet(current: _equipment),
    );

    if (picked == null || picked == _equipment || !mounted) return;

    await _saveLogic(
      // Both keys travel together: 'equipment' is the answer itself,
      // 'has_gym' the derived can-load-a-bar flag every planner reads.
      setupAnswers: {
        ..._setupAnswers,
        'equipment': picked.dbValue,
        'has_gym': picked.hasWeights,
      },
      toast: 'Equipment updated',
    );
  }

  Future<void> _openAddTrackSheet() async {
    final trackedIds = {
      for (final track in _skillTracks) track.skillCategoryId,
    };
    final available = [
      for (final category in SkillCategoryCatalog.all())
        if (!trackedIds.contains(category.id) &&
            category.trainingPaths.isNotEmpty)
          category,
    ];
    if (available.isEmpty) return;

    final picked = await showModalBottomSheet<SkillCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _AddTrackSheet(categories: available),
    );
    if (picked == null || !mounted) return;

    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      await _skillTrackService.upsertTrack(
        userId,
        skillCategoryId: picked.id,
        branchId: picked.defaultTrainingPathId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't add the skill track.")),
      );
      return;
    }
    await _loadSkillTracks();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${picked.title} added')));
  }

  Future<void> _openAdjustSheet(SkillTrack track) async {
    final category = SkillCategoryCatalog.findById(track.skillCategoryId);
    if (category == null) return;

    final result = await showModalBottomSheet<_AdjustTrackResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _AdjustTrackSheet(
        track: track,
        category: category,
        progressMap: _progress,
        masterySettings: _logic.masteryTargets,
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _skillTracks = [
        for (final existing in _skillTracks)
          existing.skillCategoryId == result.track.skillCategoryId
              ? result.track
              : existing,
      ];
      _progressOverrides.addAll(result.statusChanges);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${category.title} updated')));
  }

  /// What the balance copy needs to know about the program itself — the split
  /// it can schedule around, the equipment it can suggest for, and the trees
  /// it must not suggest adding when they already run.
  BalanceProgramContext get _balanceContext => BalanceProgramContext(
        programType: _logic.program.programType,
        trainingDaysPerWeek: _trainingDaysPerWeek,
        hasGym: _hasGym,
        skillTracks: _skillTracks,
        progressMap: _progress,
        goalSkillCategoryIds: {
          for (final goalId in _logic.program.setupGoalIds)
            if (TrainingProgramService.goalBranchIds[goalId]
                case final branchId?)
              branchId.split(':').first,
        },
      );

  /// Opens the skill-tree map (the editable wheel), then re-reads progress
  /// and tracks — a progression started, moved, or stopped there must show
  /// here the moment the user comes back.
  Future<void> _openSkillWheel({String? initialCategoryId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSkillWheelView(
          initialCategoryId: initialCategoryId,
        ),
      ),
    );
    if (!mounted) return;

    final userId = AuthService().currentUser?.id;
    if (userId != null) {
      try {
        final rows = await ProgressService().fetchAll(userId);
        if (!mounted) return;
        setState(() {
          _progressOverrides.addAll({
            for (final row in rows) row.exerciseId: row.status,
          });
        });
      } catch (error, stackTrace) {
        debugPrint('Failed to refresh progress: $error\n$stackTrace');
      }
    }
    await _loadSkillTracks();
  }

  @override
  Widget build(BuildContext context) {
    final programType = _logic.program.programType;
    final weekCycle = _weekPlan(_dayMask, programType);

    // One workout per TYPE, not per day: the exercise list stays with the
    // workout, and the strip above says which days run it.
    final typeOrder = <TrainingSessionType>[];
    final daysByType = <TrainingSessionType, List<int>>{};
    for (var i = 0; i < weekCycle.length; i++) {
      final sessionType = weekCycle[i];
      if (sessionType == TrainingSessionType.rest) continue;
      daysByType.putIfAbsent(sessionType, () {
        typeOrder.add(sessionType);
        return [];
      }).add(i);
    }
    final workouts = [
      for (final sessionType in typeOrder)
        (
          sessionType: sessionType,
          weekdays: daysByType[sessionType]!,
          items: ProgramSessionPlan.loadDay(
            service: _programService,
            sessionItemsConfig: _sessionItemsConfig,
            programType: programType,
            sessionType: sessionType,
            branchSelections: _branchSelections,
            progressMap: _progress,
            hasGym: _hasGym,
            skillTracks: _skillTracks,
          ),
        ),
    ];
    final itemsByType = {
      for (final workout in workouts) workout.sessionType: workout.items,
    };
    final week = [
      for (var i = 0; i < weekCycle.length; i++)
        if (weekCycle[i] != TrainingSessionType.rest)
          ProgramWeekDay(
            weekday: i,
            sessionType: weekCycle[i],
            items: itemsByType[weekCycle[i]]!,
          ),
    ];
    final balance = balanceFromWeek(week, context: _balanceContext);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          // Attached to the shell's per-tab controller, so re-tapping the tab
          // scrolls back to the top.
          primary: true,
          // The bottom padding clears the floating tab bar.
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Text(
                  'Program',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.02,
                    height: 1.05,
                  ),
                ),
              ),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProgramSectionLabel('Your program'),
                  _ProgramRow(
                    label: 'Equipment',
                    value: switch (_equipment) {
                      SetupEquipment.fullGym => 'Full gym',
                      SetupEquipment.freeWeights => 'Barbell & dumbbells',
                      SetupEquipment.none => 'No equipment',
                    },
                    onTap: _openEquipmentSheet,
                  ),
                  _ProgramRow(
                    label: 'Training days',
                    value: '$_trainingDaysPerWeek days / week',
                    onTap: _openDaysSheet,
                  ),
                  _ProgramRow(
                    label: 'Split',
                    value: programType.label,
                    onTap: _openSplitSheet,
                  ),
                  _ProgramRow(
                    label: 'Weekly balance',
                    value: balanceSummary(balance),
                    // The only settings value that can carry a warning — an
                    // off-target week is the one thing here worth colouring.
                    warn: balance.any(
                      (entry) =>
                          entry.group.primary && !entry.verdict.onTarget,
                    ),
                    last: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgramBalanceView(
                          week: week,
                          program: _balanceContext,
                        ),
                      ),
                    ),
                  ),
                  if (_showSkillTracksSection) ...[
                    _ProgramSectionLabel(
                      'Skill tracks',
                      sub: 'Each skill progresses on its own — pause any '
                          'without losing progress',
                      action: 'Add',
                      onAction: _openAddTrackSheet,
                    ),
                    if (_skillTracks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 14, bottom: 2),
                        child: Text(
                          'No skill tracks yet — add the skills you want to '
                          'train and each gets its own progression.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      )
                    else
                      for (final track in _skillTracks)
                        _SkillTrackRow(
                          track: track,
                          progressMap: _progress,
                          onTap: () => _openAdjustSheet(track),
                        ),
                  ],
                  const _ProgramSectionLabel('Skill trees'),
                  ProgramSkillTreesCard(
                    families: buildWheelFamilies(
                      progressMap: _progress,
                      skillTracks: _skillTracks,
                    ),
                    activeCategoryIds: {
                      for (final track in _skillTracks)
                        if (track.included) track.skillCategoryId,
                    },
                    lockedCategoryIds: computeTreeLocks(_progress).keys.toSet(),
                    onOpen: _openSkillWheel,
                  ),
                  const _ProgramSectionLabel('Workouts'),
                  for (var i = 0; i < workouts.length; i++)
                    _WorkoutTypeRow(
                      sessionType: workouts[i].sessionType,
                      timesPerWeek: workouts[i].weekdays.length,
                      last: i == workouts.length - 1,
                      onTap: () => _openWorkoutEditor(workouts[i].sessionType),
                    ),
                  const _ProgramSectionLabel('About the program'),
                  for (var i = 0; i < kProgramFaq.length; i++)
                    _FaqRow(
                      question: kProgramFaq[i].question,
                      last: i == kProgramFaq.length - 1,
                      onTap: () => showFaqSheet(context, kProgramFaq[i]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The setup wizard defaults to a full gym, so an unanswered program reads
  /// the same way here.
  bool get _hasGym => _setupAnswers['has_gym'] as bool? ?? true;

  /// The tri-state answer when program setup stored one; programs from
  /// before it map the old boolean onto its ends.
  SetupEquipment get _equipment => switch (_setupAnswers['equipment']) {
        'gym' => SetupEquipment.fullGym,
        'barbell' => SetupEquipment.freeWeights,
        'none' => SetupEquipment.none,
        _ => _hasGym ? SetupEquipment.fullGym : SetupEquipment.none,
      };
}


/// Mono, uppercase section eyebrow — the type-led alternative to a card
/// header, with an optional subtitle and trailing action.
class _ProgramSectionLabel extends StatelessWidget {
  final String label;
  final String? sub;
  final String? action;
  final VoidCallback? onAction;

  const _ProgramSectionLabel(
    this.label, {
    this.sub,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 34, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.65,
                  ),
                ),
              ),
              if (action != null)
                Pressable(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                sub!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A setting is a value pair, not a headline: one compact line, label left and
/// the current value right. Deliberately a different shape from the content
/// rows below, so settings never read as progress.
class _ProgramRow extends StatelessWidget {
  final String label;
  final String value;

  /// Colours the value amber — the row is telling you something is off.
  final bool warn;
  final bool last;
  final VoidCallback onTap;

  const _ProgramRow({
    required this.label,
    required this.value,
    this.warn = false,
    this.last = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  color: warn ? AppColors.amber : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// One row per workout TYPE. Tapping it edits the single exercise list that
/// every scheduled day shares — no remembering which day you're editing.
class _WorkoutTypeRow extends StatelessWidget {
  final TrainingSessionType sessionType;
  final int timesPerWeek;
  final bool last;
  final VoidCallback onTap;

  const _WorkoutTypeRow({
    required this.sessionType,
    required this.timesPerWeek,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ProgramContentRow(
      last: last,
      onTap: onTap,
      child: Row(
        children: [
          ProgramTypeNode(sessionType: sessionType),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              programWorkoutDayName(sessionType),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$timesPerWeek× week',
            style: GoogleFonts.robotoMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One "about the program" question — the answer lives in its sheet.
class _FaqRow extends StatelessWidget {
  final String question;
  final bool last;
  final VoidCallback onTap;

  const _FaqRow({
    required this.question,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ProgramContentRow(
      last: last,
      onTap: onTap,
      child: Text(
        question,
        // The same type the question takes as the sheet's title once it is
        // open, so opening one reads as the row growing rather than a new
        // headline replacing it.
        style: const TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
          height: 1.28,
        ),
      ),
    );
  }
}

/// The shape real content gets: a big name given room to breathe, a hairline
/// under it, and a chevron into wherever it leads.
class _ProgramContentRow extends StatelessWidget {
  final Widget child;
  final bool last;
  final VoidCallback onTap;

  const _ProgramContentRow({
    required this.child,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 20, bottom: 22),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skill tracks ────────────────────────────────────────────

class _SkillTrackRow extends StatelessWidget {
  final SkillTrack track;
  final Map<String, ExerciseStatus> progressMap;
  final VoidCallback onTap;

  const _SkillTrackRow({
    required this.track,
    required this.progressMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = SkillCategoryCatalog.findById(track.skillCategoryId);
    if (category == null) return const SizedBox.shrink();

    final current = ProgramSessionPlan.currentExerciseForPath(
      skillCategoryId: track.skillCategoryId,
      branchId: track.branchId,
      progressMap: progressMap,
    );
    final branchLabel = _trackBranchLabel(category, track.branchId);

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          branchLabel == null
                              ? category.title
                              : '${category.title} · $branchLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: track.included
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (!track.included) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PAUSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    current == null
                        ? programPatternLabel(category.track)
                        : 'Now: ${current.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

String? _trackBranchLabel(SkillCategory category, String branchId) {
  if (category.trainingPaths.length <= 1) return null;
  for (final branch in category.branches) {
    if (branch.id == branchId) return branch.label;
  }
  return branchId;
}

class _AddTrackSheet extends StatelessWidget {
  final List<SkillCategory> categories;

  const _AddTrackSheet({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Add skill track',
      sub: 'Each skill progresses independently',
      expand: true,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
            child: Pressable(
              onTap: () => Navigator.of(context).pop(category),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            programPatternLabel(category.track),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: AppColors.accentPrimary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// What the adjust sheet changed, so the host can update local state.
class _AdjustTrackResult {
  final SkillTrack track;
  final Map<String, ExerciseStatus> statusChanges;

  const _AdjustTrackResult({
    required this.track,
    required this.statusChanges,
  });
}

/// Adjust Progression: change a track's branch, position (current exercise),
/// current target, or pause it — the sanctioned way to correct progression
/// state instead of deleting workout history.
class _AdjustTrackSheet extends StatefulWidget {
  final SkillTrack track;
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;
  final MasteryTargetSettings masterySettings;

  const _AdjustTrackSheet({
    required this.track,
    required this.category,
    required this.progressMap,
    required this.masterySettings,
  });

  @override
  State<_AdjustTrackSheet> createState() => _AdjustTrackSheetState();
}

class _AdjustTrackSheetState extends State<_AdjustTrackSheet> {
  final _progressService = ProgressService();

  late String _branchId;
  late bool _included;
  late int _position;
  Map<String, ExerciseProgress> _progressRows = const {};
  int? _targetValue; // edited per-set value for the current exercise
  bool _saving = false;

  List<String> get _path => widget.category.pathFor(_branchId);

  Exercise? get _currentExercise {
    final path = _path;
    if (path.isEmpty) return null;
    return ExerciseCatalog.findById(path[_position.clamp(0, path.length - 1)]);
  }

  @override
  void initState() {
    super.initState();
    _branchId = widget.track.branchId;
    _included = widget.track.included;
    _position = _derivedPosition();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await _progressService.fetchAll(userId);
      if (!mounted) return;
      setState(() {
        _progressRows = {for (final row in rows) row.exerciseId: row};
      });
    } catch (_) {
      // Target stepper just starts from the ladder default.
    }
  }

  int _derivedPosition() {
    final path = _path;
    for (var i = 0; i < path.length; i++) {
      if (widget.progressMap[path[i]] == ExerciseStatus.active) return i;
    }
    for (var i = 0; i < path.length; i++) {
      if (!(widget.progressMap[path[i]]?.isCleared ?? false)) return i;
    }
    return path.isEmpty ? 0 : path.length - 1;
  }

  int get _effectiveTarget {
    final exercise = _currentExercise;
    if (exercise == null) return ExerciseProgressionService.initialTargetReps;
    return ExerciseProgressionService.currentTargetForExercise(
      exercise,
      progress: _progressRows[exercise.id],
      masterySettings: widget.masterySettings,
    ).value;
  }

  void _selectBranch(String branchId) {
    setState(() {
      _branchId = branchId;
      _targetValue = null;
      final path = _path;
      _position = 0;
      for (var i = 0; i < path.length; i++) {
        if (!(widget.progressMap[path[i]]?.isCleared ?? false)) {
          _position = i;
          return;
        }
      }
      _position = path.isEmpty ? 0 : path.length - 1;
    });
  }

  Future<void> _save() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null || _saving) return;

    setState(() => _saving = true);
    final service = SkillTrackService();
    final statusChanges = <String, ExerciseStatus>{};

    try {
      if (_branchId != widget.track.branchId) {
        await service.setBranch(
          userId,
          widget.track.skillCategoryId,
          branchId: _branchId,
        );
      }
      if (_included != widget.track.included) {
        await service.setIncluded(
          userId,
          widget.track.skillCategoryId,
          included: _included,
        );
      }

      // Position on the path: everything before the current exercise is
      // mastered — "tap where you are" is an assessment, the same claim the
      // setup answers make — the current one is active, everything after is
      // inactive.
      final path = _path;
      for (var i = 0; i < path.length; i++) {
        final existing = widget.progressMap[path[i]] ?? ExerciseStatus.inactive;
        final desired = i < _position
            ? ExerciseStatus.mastered
            : i == _position
                ? ExerciseStatus.active
                : ExerciseStatus.inactive;
        if (existing != desired) {
          await _progressService.upsert(userId, path[i], desired);
          statusChanges[path[i]] = desired;
        }
      }

      final exercise = _currentExercise;
      if (exercise != null &&
          _targetValue != null &&
          _targetValue != _effectiveTarget) {
        final sets = _progressRows[exercise.id]?.currentTargetSets ??
            ExerciseProgressionService.initialTargetSets;
        await _progressService.upsertTarget(
          userId,
          exercise.id,
          targetSets: sets,
          targetValue: _targetValue!,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        _AdjustTrackResult(
          track: widget.track.copyWith(
            branchId: _branchId,
            included: _included,
          ),
          statusChanges: statusChanges,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save the changes. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final exercise = _currentExercise;
    final isTimed = exercise != null &&
        ExerciseProgressionService.isTimedExercise(exercise);
    final step = isTimed
        ? ExerciseProgressionService.targetIncrementSeconds
        : ExerciseProgressionService.targetIncrementReps;
    final shownTarget = _targetValue ?? _effectiveTarget;

    return SheetShell(
      title: widget.category.title,
      sub: 'Adjust progression',
      expand: true,
      footer: PillButton(
        label: _saving ? 'Saving' : 'Save changes',
        onTap: _saving ? null : _save,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.category.trainingPaths.length > 1) ...[
              const Text(
                'BRANCH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pathId in widget.category.trainingPaths.keys)
                    Pressable(
                      onTap: () => _selectBranch(pathId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: pathId == _branchId
                              ? AppColors.accentSoft
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: pathId == _branchId
                                ? AppColors.accentPrimary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _trackBranchLabel(widget.category, pathId) ?? pathId,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: pathId == _branchId
                                ? AppColors.accentPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            const Text(
              'PATH — TAP WHERE YOU ARE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (var i = 0; i < path.length; i++)
                    _AdjustPathRow(
                      first: i == 0,
                      name: ExerciseCatalog.findById(path[i])?.name ?? path[i],
                      state: i < _position
                          ? ExerciseStatus.mastered
                          : i == _position
                              ? ExerciseStatus.active
                              : ExerciseStatus.inactive,
                      onTap: () => setState(() {
                        _position = i;
                        _targetValue = null;
                      }),
                    ),
                ],
              ),
            ),
            if (exercise != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current target · ${exercise.name}',
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _AdjustStepButton(
                      icon: Icons.remove_rounded,
                      onTap: shownTarget - step >= step
                          ? () =>
                              setState(() => _targetValue = shownTarget - step)
                          : null,
                    ),
                    SizedBox(
                      width: 62,
                      child: Text(
                        '3 × $shownTarget${isTimed ? 's' : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    _AdjustStepButton(
                      icon: Icons.add_rounded,
                      onTap: () =>
                          setState(() => _targetValue = shownTarget + step),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _included
                          ? 'Included in your program'
                          : 'Paused — progress is kept',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _included,
                    activeTrackColor: AppColors.accentPrimary,
                    onChanged: (value) => setState(() => _included = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustPathRow extends StatelessWidget {
  final bool first;
  final String name;
  final ExerciseStatus state;
  final VoidCallback onTap;

  const _AdjustPathRow({
    required this.first,
    required this.name,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (state) {
      ExerciseStatus.mastered => AppColors.green,
      ExerciseStatus.active => AppColors.accentPrimary,
      ExerciseStatus.inactive => Colors.white.withValues(alpha: 0.16),
    };

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: first
            ? null
            : const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state == ExerciseStatus.inactive
                    ? Colors.transparent
                    : dotColor,
                border: state == ExerciseStatus.inactive
                    ? Border.all(color: dotColor, width: 2)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: state == ExerciseStatus.active
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: state == ExerciseStatus.inactive
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (state == ExerciseStatus.active)
              const Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentPrimary,
                  letterSpacing: 0.8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdjustStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _AdjustStepButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 17,
          color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DaysSheet extends StatefulWidget {
  /// Monday-first 0/1 mask of the week as it stands today.
  final List<int> currentMask;
  final List<TrainingSessionType> Function(List<int> mask) weekPlanBuilder;

  const _DaysSheet({required this.currentMask, required this.weekPlanBuilder});

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  static const _dayOptions = [1, 2, 3, 4, 5, 6, 7];

  late List<int> _mask;

  @override
  void initState() {
    super.initState();
    _mask = List.of(widget.currentMask);
  }

  int get _days => _mask.where((day) => day == 1).length;

  bool get _dirty {
    for (var i = 0; i < _mask.length; i++) {
      if (_mask[i] != widget.currentMask[i]) return true;
    }
    return false;
  }

  /// Picking a count lays the week out from the default template, so the two
  /// controls always agree: the chips read the count back off the week.
  void _pickCount(int days) {
    setState(() {
      _mask = List.of(
        TrainingScheduleService.weekTemplates[days] ?? widget.currentMask,
      );
    });
  }

  /// Tapping a day flips just that day and lets the chip row follow. The last
  /// training day can't be turned off — a week with no sessions has nothing
  /// to schedule.
  void _toggleDay(int index) {
    if (_mask[index] == 1 && _days == 1) return;
    setState(() => _mask[index] = _mask[index] == 1 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.weekPlanBuilder(_mask);

    return SheetShell(
      title: 'Weekly schedule',
      sub: 'Pick a number or tap the days themselves',
      footer: PillButton(
        label: _dirty ? 'Save schedule' : 'No changes yet',
        onTap: _dirty ? () => Navigator.of(context).pop(_mask) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seven chips don't fit a phone width, so the row scrolls. The
            // chips size to their own text rather than a fixed height, so a
            // large text scale can't clip them.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final option in _dayOptions) ...[
                    if (option != _dayOptions.first) const SizedBox(width: 8),
                    Pressable(
                      onTap: () => _pickCount(option),
                      child: Container(
                        width: 62,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: option == _days
                              ? AppColors.accentPrimary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$option',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: option == _days
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option == 1 ? 'day' : 'days',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: option == _days
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // The same week strip the Workouts section shows, made editable:
            // tapping a day toggles it between training and rest.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProgramWeekStrip(
                weekCycle: plan,
                onDayTap: _toggleDay,
                nodeSize: 24,
                withDivider: false,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Sessions repeat in order. Miss one and it slots into your '
                'next training day.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitSheet extends StatefulWidget {
  final TrainingProgramType current;

  const _SplitSheet({required this.current});

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  late TrainingProgramType _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  String _splitSub(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Every session trains everything';
      case TrainingProgramType.pushPull:
        return 'Alternate pushing and pulling days';
      case TrainingProgramType.upperLower:
        return 'Alternate upper and lower body days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _picked != widget.current;

    return SheetShell(
      title: 'Split',
      sub: 'How your week splits into sessions',
      footer: PillButton(
        label: dirty ? 'Save & rebuild sessions' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_picked) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            for (final type in TrainingProgramType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SheetRadioRow(
                  selected: _picked == type,
                  label: type.label,
                  sub: _splitSub(type),
                  onTap: () => setState(() => _picked = type),
                ),
              ),
            if (dirty)
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 2, 2, 0),
                child: Text(
                  'Changing the split resets your day plans to a fresh default — you can fine-tune each day afterwards.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Where you train — the same three choices the setup wizard asks, so the
/// answer can be revised without re-running it.
class _EquipmentSheet extends StatefulWidget {
  final SetupEquipment current;

  const _EquipmentSheet({required this.current});

  @override
  State<_EquipmentSheet> createState() => _EquipmentSheetState();
}

class _EquipmentSheetState extends State<_EquipmentSheet> {
  late SetupEquipment _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _picked != widget.current;

    return SheetShell(
      title: 'Equipment',
      sub: 'What you have to train with',
      footer: PillButton(
        label: dirty ? 'Save changes' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_picked) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            for (final option in const [
              (
                SetupEquipment.fullGym,
                'Full gym',
                'Pull-up bar, rings, barbells',
              ),
              (
                SetupEquipment.freeWeights,
                'Barbell and dumbbells',
                'A home setup with free weights',
              ),
              (
                SetupEquipment.none,
                'No equipment',
                'Training at home or outdoors',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SheetRadioRow(
                  selected: _picked == option.$1,
                  label: option.$2,
                  sub: option.$3,
                  onTap: () => setState(() => _picked = option.$1),
                ),
              ),
            if (_picked != SetupEquipment.fullGym)
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 2, 2, 0),
                child: Text(
                  'You’ll need access to at least a pull-up bar — most of '
                  'Forma’s pulling work hangs from one. A doorway bar or a '
                  'park is enough.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Radio option card used by the picker sheets.
class _SheetRadioRow extends StatelessWidget {
  final bool selected;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _SheetRadioRow({
    required this.selected,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.accentPrimary
                      : Colors.white.withValues(alpha: 0.14),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
