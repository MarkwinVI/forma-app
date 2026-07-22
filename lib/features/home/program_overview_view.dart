import 'dart:math' as math;

import 'package:flutter/material.dart';

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
import '../../data/services/training_program_store_service.dart';
import 'program_day_editor_view.dart';
import 'program_day_items.dart';
import 'program_setup_view.dart' show GoalSkillGroup, GoalSkillOption, kGoalSkillGroups, kGoalSkillOptions;

const _statusRed = Color(0xFFE5484D);

/// Balance status: green optimal, amber under target, red over target.
enum _BalanceStatus { under, ok, over }

Color _statusColor(_BalanceStatus status) {
  switch (status) {
    case _BalanceStatus.under:
      return AppColors.amber;
    case _BalanceStatus.ok:
      return AppColors.green;
    case _BalanceStatus.over:
      return _statusRed;
  }
}

/// Movement coverage: 1–2 exercises is optimal, 0 is a gap, more than 2 is
/// overloaded.
_BalanceStatus _coverageStatus(int count) {
  if (count == 0) return _BalanceStatus.under;
  if (count <= 2) return _BalanceStatus.ok;
  return _BalanceStatus.over;
}

_BalanceStatus _muscleStatus(int sets) {
  if (sets < kProgramSetsMin) return _BalanceStatus.under;
  if (sets <= kProgramSetsMax) return _BalanceStatus.ok;
  return _BalanceStatus.over;
}

const _muscleStatusText = {
  _BalanceStatus.under: 'Below target — add a set or two',
  _BalanceStatus.ok: 'In the optimal range',
  _BalanceStatus.over: 'More volume than you need',
};

const _weekTemplates = <int, List<int>>{
  2: [1, 0, 0, 1, 0, 0, 0],
  3: [1, 0, 1, 0, 1, 0, 0],
  4: [1, 1, 0, 1, 1, 0, 0],
  5: [1, 1, 1, 0, 1, 1, 0],
  6: [1, 1, 1, 1, 1, 1, 0],
};
const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
  String? _openBalance; // 'cov' | 'mus' | null

  /// Skills-as-tracks state, loaded here so the tab reflects adds/pauses
  /// immediately. Status edits from the adjust sheet land in
  /// [_progressOverrides] on top of the read-only widget.progressMap.
  List<SkillTrack> _skillTracks = const [];
  final Map<String, ExerciseStatus> _progressOverrides = {};

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

  List<String> get _goalSkillIds {
    final raw = _setupAnswers['skill_ids'];
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }

  int get _trainingDaysPerWeek =>
      _logic.program.frequencyPerWeek.clamp(2, 6);

  Map<TrainingTrack, String> get _branchSelections => {
        ..._programService.defaultBranchSelections(),
        ..._logic.branchSelections,
        // Lane-keyed view of the skill tracks for lane-based consumers
        // (day editor, weekly balance).
        ..._programService.laneSelectionsFromTracks(_skillTracks),
      };

  List<TrainingSessionType> _weekPlan(int days, TrainingProgramType type) {
    final sequence = _programService.trainingDaysForProgramType(type);
    final template = _weekTemplates[days.clamp(2, 6)]!;
    var next = 0;
    return [
      for (final on in template)
        on == 1
            ? sequence[(next++) % sequence.length]
            : TrainingSessionType.rest,
    ];
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

  Future<void> _openDayEditor(TrainingSessionType sessionType) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramDayEditorView(
          sessionType: sessionType,
          programType: _logic.program.programType,
          branchSelections: _branchSelections,
          progressMap: widget.progressMap,
          sessionItemsConfig: _sessionItemsConfig,
          onSave: (config) => _saveLogic(
            sessionItemsConfig: config,
            toast: '${programDayTitle(sessionType)} day updated',
          ),
        ),
      ),
    );
  }

  Future<void> _openDaysSheet() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _DaysSheet(
        current: _trainingDaysPerWeek,
        weekPlanBuilder: (days) =>
            _weekPlan(days, _logic.program.programType),
      ),
    );

    if (picked == null || picked == _trainingDaysPerWeek || !mounted) return;

    await _saveLogic(
      frequencyPerWeek: picked,
      setupAnswers: {..._setupAnswers, 'days_per_week': picked},
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

  Future<void> _openMasterySheet() async {
    final picked = await showModalBottomSheet<MasteryTargetSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _MasterySheet(current: _logic.masteryTargets),
    );

    if (picked == null || !mounted) return;

    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    try {
      // Settings-only write: no progress rows, stored targets, or mastered
      // statuses are touched, and no past workouts are re-evaluated.
      await TrainingProgramStoreService().updateMasteryTargets(
        userId: userId,
        targets: picked,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save the mastery target. Try again."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _logic = TrainingProgramLogicSnapshot(
        program: _logic.program,
        state: _logic.state,
        branchSelections: _logic.branchSelections,
        repGoalProfile: _logic.repGoalProfile,
        masteryTargets: picked,
      );
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Mastery target updated')));
  }

  Future<void> _openSkillsSheet() async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _GoalSkillsSheet(picked: _goalSkillIds),
    );

    if (picked == null || !mounted) return;

    await _saveLogic(
      setupAnswers: {..._setupAnswers, 'skill_ids': picked},
      toast: 'Goal skills updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final programType = _logic.program.programType;
    final trainingDays = _programService.trainingDaysForProgramType(
      programType,
    );
    final coverage = ProgramSessionPlan.weeklyCoverage(
      service: _programService,
      sessionItemsConfig: _sessionItemsConfig,
      programType: programType,
      branchSelections: _branchSelections,
      progressMap: widget.progressMap,
    );
    final muscleSets = ProgramSessionPlan.weeklyMuscleSets(
      service: _programService,
      sessionItemsConfig: _sessionItemsConfig,
      programType: programType,
      branchSelections: _branchSelections,
      progressMap: widget.progressMap,
    );
    final goalSkills = [
      for (final id in _goalSkillIds)
        for (final option in kGoalSkillOptions)
          if (option.id == id) option,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Program settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          // Bottom padding clears the floating tab bar now that this screen
          // is hosted as the Program tab.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Your program'),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    _ProgramRow(
                      first: true,
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
                      label: 'Mastery target',
                      value: '3 × ${_logic.masteryTargets.repsPerSet} reps · '
                          '${_logic.masteryTargets.secondsPerSet}s holds',
                      onTap: _openMasterySheet,
                    ),
                  ],
                ),
              ),
              SectionHeader(
                title: 'Skill tracks',
                sub: 'Each skill progresses on its own — pause any without '
                    'losing progress',
                action: 'Add',
                onAction: _openAddTrackSheet,
              ),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    if (_skillTracks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'No skill tracks yet — add the skills you want to '
                          'train and each gets its own progression.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < _skillTracks.length; i++)
                        _SkillTrackRow(
                          first: i == 0,
                          track: _skillTracks[i],
                          progressMap: _progress,
                          onTap: () => _openAdjustSheet(_skillTracks[i]),
                        ),
                  ],
                ),
              ),
              const SectionHeader(
                title: 'Sessions',
                sub: 'Tap a day to edit its exercises',
              ),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    for (var i = 0; i < trainingDays.length; i++)
                      _SessionRow(
                        first: i == 0,
                        title: programDayTitle(trainingDays[i]),
                        items: ProgramSessionPlan.loadDay(
                          service: _programService,
                          sessionItemsConfig: _sessionItemsConfig,
                          programType: programType,
                          sessionType: trainingDays[i],
                          branchSelections: _branchSelections,
                          progressMap: _progress,
                          skillTracks: _skillTracks,
                        ),
                        onTap: () => _openDayEditor(trainingDays[i]),
                      ),
                  ],
                ),
              ),
              SectionHeader(
                title: 'Goal skills',
                action: 'Edit',
                onAction: _openSkillsSheet,
              ),
              SurfaceCard(
                onTap: _openSkillsSheet,
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                child: goalSkills.isEmpty
                    ? const Text(
                        'No specific skills picked — Forma keeps the program balanced across every movement pattern.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final skill in goalSkills)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 8, 13, 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        skill.icon,
                                        size: 16,
                                        color: AppColors.accentPrimary,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        skill.label,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Each session weaves in progressions toward these skills.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
              const SectionHeader(title: 'Weekly balance'),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    _buildCoverageGroup(coverage),
                    _buildMuscleGroup(muscleSets),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverageGroup(
    Map<ExerciseCategory, List<ProgramDayItem>> coverage,
  ) {
    const categories = ProgramSessionPlan.coverageOrder;
    final missing =
        categories.where((category) => coverage[category]!.isEmpty).length;
    final over =
        categories.where((category) => coverage[category]!.length > 2).length;

    final String summary;
    final Color summaryColor;
    if (missing == 0 && over == 0) {
      summary = 'All ${categories.length} patterns covered';
      summaryColor = AppColors.green;
    } else {
      summary = [
        if (missing > 0) '$missing pattern${missing > 1 ? 's' : ''} missing',
        if (over > 0) '$over overloaded',
      ].join(' · ');
      summaryColor = missing > 0 ? AppColors.amber : _statusRed;
    }

    return _BalanceGroup(
      first: true,
      title: 'Movement coverage',
      summary: summary,
      summaryColor: summaryColor,
      statuses: [
        for (final category in categories)
          _coverageStatus(coverage[category]!.length),
      ],
      open: _openBalance == 'cov',
      onToggle: () => setState(
        () => _openBalance = _openBalance == 'cov' ? null : 'cov',
      ),
      footer: 'Exercises per movement · aim for 1–2',
      children: [
        for (final category in categories)
          _BalanceRow(
            icon: programPatternIcon(category),
            title: programPatternLabel(category),
            subtitle: coverage[category]!.isEmpty
                ? 'No exercises programmed'
                : coverage[category]!.map((item) => item.name).join(' · '),
            subtitleColor: coverage[category]!.isEmpty
                ? AppColors.amber
                : AppColors.textSecondary,
            ringValue: coverage[category]!.length,
            ringFraction: coverage[category]!.length / 2,
            ringColor: _statusColor(
              _coverageStatus(coverage[category]!.length),
            ),
          ),
      ],
    );
  }

  Widget _buildMuscleGroup(Map<String, int> muscleSets) {
    final under = kProgramMuscleGroups
        .where((group) => _muscleStatus(muscleSets[group]!) ==
            _BalanceStatus.under)
        .toList();
    final over = kProgramMuscleGroups
        .where(
            (group) => _muscleStatus(muscleSets[group]!) == _BalanceStatus.over)
        .toList();

    final String summary;
    final Color summaryColor;
    if (under.isEmpty && over.isEmpty) {
      summary = 'All muscle groups in range';
      summaryColor = AppColors.green;
    } else {
      summary = [...over, ...under].join(', ') +
          (over.isNotEmpty ? ' overworked' : ' below target');
      summaryColor = over.isNotEmpty ? _statusRed : AppColors.amber;
    }

    return _BalanceGroup(
      title: 'Muscle volume',
      summary: summary,
      summaryColor: summaryColor,
      statuses: [
        for (final group in kProgramMuscleGroups)
          _muscleStatus(muscleSets[group]!),
      ],
      open: _openBalance == 'mus',
      onToggle: () => setState(
        () => _openBalance = _openBalance == 'mus' ? null : 'mus',
      ),
      footer: 'Sets per week · aim for $kProgramSetsMin–$kProgramSetsMax',
      children: [
        for (final group in kProgramMuscleGroups)
          _BalanceRow(
            icon: programMuscleIcon(group),
            title: group,
            subtitle: _muscleStatusText[_muscleStatus(muscleSets[group]!)]!,
            subtitleColor: _muscleStatus(muscleSets[group]!) ==
                    _BalanceStatus.ok
                ? AppColors.textSecondary
                : _statusColor(_muscleStatus(muscleSets[group]!)),
            ringValue: muscleSets[group]!,
            ringFraction: muscleSets[group]! / kProgramSetsMax,
            ringColor: _statusColor(_muscleStatus(muscleSets[group]!)),
          ),
      ],
    );
  }
}

/// Plain settings row: label · value · chevron.
class _ProgramRow extends StatelessWidget {
  final bool first;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ProgramRow({
    this.first = false,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
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

class _SessionRow extends StatelessWidget {
  final bool first;
  final String title;
  final List<ProgramDayItem> items;
  final VoidCallback onTap;

  const _SessionRow({
    required this.first,
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${items.length} exercises',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items.map((item) => item.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
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

/// Collapsible balance group: summary row with status dots → detail rows.
class _BalanceGroup extends StatelessWidget {
  final bool first;
  final String title;
  final String summary;
  final Color summaryColor;
  final List<_BalanceStatus> statuses;
  final bool open;
  final VoidCallback onToggle;
  final List<Widget> children;
  final String footer;

  const _BalanceGroup({
    this.first = false,
    required this.title,
    required this.summary,
    required this.summaryColor,
    required this.statuses,
    required this.open,
    required this.onToggle,
    required this.children,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Pressable(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: summaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final status in statuses)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(status),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            ...children,
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  footer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final int ringValue;
  final double ringFraction;
  final Color ringColor;

  const _BalanceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.ringValue,
    required this.ringFraction,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconTile(icon: icon, size: 36),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CountRing(
            value: ringValue,
            fraction: ringFraction,
            color: ringColor,
          ),
        ],
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  final int value;
  final double fraction;
  final Color color;

  const _CountRing({
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _RingPainter(fraction: fraction, color: color),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = Colors.white.withValues(alpha: 0.09);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = 2 * math.pi * fraction.clamp(0.02, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

/// Shared scrim + slide-up sheet chrome: grabber, title, close, content.
class _SheetShell extends StatelessWidget {
  final String title;
  final String sub;
  final Widget child;
  final Widget? footer;
  final bool expand;

  const _SheetShell({
    required this.title,
    required this.sub,
    required this.child,
    this.footer,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height - media.padding.top - 24;

    return Container(
      constraints: BoxConstraints(
        maxHeight: math.min(media.size.height * 0.88, maxHeight),
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: media.padding.bottom + 14),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expand) Expanded(child: child) else Flexible(child: child),
          if (footer != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

// ── Skill tracks ────────────────────────────────────────────

class _SkillTrackRow extends StatelessWidget {
  final bool first;
  final SkillTrack track;
  final Map<String, ExerciseStatus> progressMap;
  final VoidCallback onTap;

  const _SkillTrackRow({
    required this.first,
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
        decoration: first
            ? null
            : const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
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
    return _SheetShell(
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
      if (widget.progressMap[path[i]] != ExerciseStatus.mastered) return i;
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
        if (widget.progressMap[path[i]] != ExerciseStatus.mastered) {
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
      // mastered, the current one is active, everything after is inactive.
      final path = _path;
      for (var i = 0; i < path.length; i++) {
        final desired = i < _position
            ? ExerciseStatus.mastered
            : i == _position
                ? ExerciseStatus.active
                : ExerciseStatus.inactive;
        final existing =
            widget.progressMap[path[i]] ?? ExerciseStatus.inactive;
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

    return _SheetShell(
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
                          ? () => setState(
                              () => _targetValue = shownTarget - step)
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
          color:
              onTap == null ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MasterySheet extends StatefulWidget {
  final MasteryTargetSettings current;

  const _MasterySheet({required this.current});

  @override
  State<_MasterySheet> createState() => _MasterySheetState();
}

class _MasterySheetState extends State<_MasterySheet> {
  static const _minReps = 6;
  static const _maxReps = 15;
  static const _minSeconds = 10;
  static const _maxSeconds = 60;
  static const _secondsStep = 5;

  late int _reps;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _reps = widget.current.repsPerSet.clamp(_minReps, _maxReps);
    _seconds = widget.current.secondsPerSet.clamp(_minSeconds, _maxSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _reps != widget.current.repsPerSet ||
        _seconds != widget.current.secondsPerSet;

    return _SheetShell(
      title: 'Mastery target',
      sub: 'What it takes to level an exercise up',
      footer: PillButton(
        label: dirty ? 'Save target' : 'No changes yet',
        onTap: dirty
            ? () => Navigator.of(context).pop(
                  MasteryTargetSettings(
                    repsPerSet: _reps,
                    secondsPerSet: _seconds,
                  ),
                )
            : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MasteryStepperRow(
              label: 'Rep exercises',
              valueLabel: '3 × $_reps reps',
              onDecrease: _reps > _minReps
                  ? () => setState(() => _reps -= 1)
                  : null,
              onIncrease: _reps < _maxReps
                  ? () => setState(() => _reps += 1)
                  : null,
            ),
            const SizedBox(height: 10),
            _MasteryStepperRow(
              label: 'Timed holds',
              valueLabel: '3 × ${_seconds}s',
              onDecrease: _seconds > _minSeconds
                  ? () => setState(() => _seconds -= _secondsStep)
                  : null,
              onIncrease: _seconds < _maxSeconds
                  ? () => setState(() => _seconds += _secondsStep)
                  : null,
            ),
            const SizedBox(height: 14),
            const Text(
              'Reaching this target masters an exercise and unlocks the next '
              'move in its path. Changing it applies to exercises you are '
              'still working on — everything already mastered stays mastered, '
              'and your current session targets keep climbing from where '
              'they are.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryStepperRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _MasteryStepperRow({
    required this.label,
    required this.valueLabel,
    required this.onDecrease,
    required this.onIncrease,
  });

  Widget _stepButton({required IconData icon, required VoidCallback? onTap}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _stepButton(icon: Icons.remove_rounded, onTap: onDecrease),
          SizedBox(
            width: 86,
            child: Text(
              valueLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _stepButton(icon: Icons.add_rounded, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _DaysSheet extends StatefulWidget {
  final int current;
  final List<TrainingSessionType> Function(int days) weekPlanBuilder;

  const _DaysSheet({required this.current, required this.weekPlanBuilder});

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  static const _dayOptions = [2, 3, 4, 5, 6];
  late int _days;

  @override
  void initState() {
    super.initState();
    _days = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _days != widget.current;
    final plan = widget.weekPlanBuilder(_days);

    return _SheetShell(
      title: 'Weekly schedule',
      sub: 'How many days a week you train',
      footer: PillButton(
        label: dirty ? 'Save schedule' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_days) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final option in _dayOptions)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == _dayOptions.last ? 0 : 8,
                      ),
                      child: Pressable(
                        onTap: () => setState(() => _days = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: option == _days
                                ? AppColors.accentPrimary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
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
                                'days',
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
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < plan.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == plan.length - 1 ? 0 : 5,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _weekdayLetters[i],
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: plan[i] == TrainingSessionType.rest
                                  ? AppColors.surface2
                                  : AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _dayAbbr(plan[i]),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: plan[i] == TrainingSessionType.rest
                                      ? AppColors.textMuted
                                      : AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Sessions repeat in order — miss one and it slots into your next training day.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayAbbr(TrainingSessionType type) {
    switch (type) {
      case TrainingSessionType.fullBody:
        return 'FB';
      case TrainingSessionType.push:
        return 'PU';
      case TrainingSessionType.pull:
        return 'PL';
      case TrainingSessionType.upper:
        return 'UP';
      case TrainingSessionType.lower:
        return 'LO';
      case TrainingSessionType.rest:
        return 'RE';
    }
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
        return 'Alternate upper- and lower-body days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _picked != widget.current;

    return _SheetShell(
      title: 'Split',
      sub: 'How each week is divided into sessions',
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
                child: Pressable(
                  onTap: () => setState(() => _picked = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _picked == type
                          ? AppColors.accentSoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _picked == type
                            ? AppColors.accentPrimary
                            : Colors.transparent,
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
                              color: _picked == type
                                  ? AppColors.accentPrimary
                                  : Colors.white.withValues(alpha: 0.14),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _picked == type
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
                                type.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _splitSub(type),
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

class _GoalSkillsSheet extends StatefulWidget {
  final List<String> picked;

  const _GoalSkillsSheet({required this.picked});

  @override
  State<_GoalSkillsSheet> createState() => _GoalSkillsSheetState();
}

class _GoalSkillsSheetState extends State<_GoalSkillsSheet> {
  late List<String> _picked;

  @override
  void initState() {
    super.initState();
    _picked = List.of(widget.picked);
  }

  bool get _dirty {
    final a = [..._picked]..sort();
    final b = [...widget.picked]..sort();
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;

    return _SheetShell(
      title: 'Goal skills',
      sub: 'Pick anything that excites you — Forma builds the path from where you are today',
      expand: true,
      footer: PillButton(
        label: dirty ? 'Save goal skills' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_picked) : null,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
            child: Text(
              '${_picked.length} picked',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _picked.isEmpty
                    ? AppColors.textMuted
                    : AppColors.accentPrimary,
              ),
            ),
          ),
          for (final group in kGoalSkillGroups) ..._buildGroup(group),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(GoalSkillGroup group) {
    final skills = kGoalSkillOptions
        .where((skill) => skill.group == group.id)
        .toList();
    if (skills.isEmpty) return const [];

    final rows = <Widget>[];
    for (var index = 0; index < skills.length; index += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSkillCard(skills[index])),
              const SizedBox(width: 8),
              Expanded(
                child: index + 1 < skills.length
                    ? _buildSkillCard(skills[index + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 9),
        child: Text(
          group.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      ...rows,
    ];
  }

  Widget _buildSkillCard(GoalSkillOption skill) {
    final on = _picked.contains(skill.id);

    return Pressable(
      onTap: () => _toggle(skill.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? AppColors.accentPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  skill.icon,
                  size: 22,
                  color: on
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                ),
                if (on)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              skill.label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                for (var dot = 1; dot <= 3; dot++)
                  Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.only(right: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot <= skill.difficulty + 1
                          ? (on
                              ? AppColors.accentPrimary
                              : AppColors.textSecondary)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
