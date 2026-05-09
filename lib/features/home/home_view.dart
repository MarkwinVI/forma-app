import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import 'live_workout_view.dart';
import 'session_overview_view.dart';
import 'training_program_logic_view.dart';

const _homeBg = Color(0xFF000000);
const _groupBg = Color(0xFF1C1C1E);
const _groupBgHi = Color(0xFF2C2C2E);
const _hairline = Color(0x14FFFFFF);
const _textTertiary = Color(0xFF636366);
const _emptyStateBg = Color(0x05FFFFFF);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _progressService = ProgressService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  Map<String, ExerciseStatus> _progressMap = {};
  DailyTrainingRecommendation? _recommendation;
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
  String? _scheduleVariant;
  Map<TrainingTrack, String> _branchSelections = {};
  RepGoalProfile _repGoalProfile = RepGoalProfile.balanced;
  int _nextStepIndex = 0;
  TrainingSessionType _nextSessionType = TrainingSessionType.fullBody;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    final userId = AuthService().currentUser?.id;
    final progressMap = <String, ExerciseStatus>{};
    TrainingProgramLogicSnapshot? logicSnapshot;

    if (userId != null) {
      try {
        final progress = await _progressService.fetchAll(userId);
        for (final item in progress) {
          progressMap[item.exerciseId] = item.status;
        }

        logicSnapshot =
            await _trainingProgramStoreService.getOrCreateProgramLogic(
          userId,
        );
      } catch (_) {
        // Keep the widget usable with default local fallback state.
      }
    }

    if (!mounted) return;

    setState(() {
      _progressMap = progressMap;
      _selectedProgramType =
          logicSnapshot?.program.programType ?? TrainingProgramType.fullBody;
      _scheduleVariant = logicSnapshot?.program.scheduleVariant;
      _branchSelections = {
        ..._trainingProgramService.defaultBranchSelections(),
        ...?logicSnapshot?.branchSelections,
      };
      _repGoalProfile =
          logicSnapshot?.repGoalProfile ?? RepGoalProfile.balanced;
      _nextStepIndex = logicSnapshot?.state.nextStepIndex ?? 0;
      _nextSessionType =
          logicSnapshot?.state.nextSessionType ?? TrainingSessionType.fullBody;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
        branchSelections: _branchSelections,
      );
      _loading = false;
    });
  }

  List<_UpcomingScheduleEntry> _buildUpcomingSchedule() {
    final cycle = _trainingProgramService.scheduleCycleFor(
      programType: _selectedProgramType,
      scheduleVariant: _scheduleVariant,
    );
    if (cycle.isEmpty) return const [];

    final startIndex = _resolveStartIndex(cycle);
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);

    return List.generate(5, (index) {
      final offset = index + 1;
      return _UpcomingScheduleEntry(
        date: startDate.add(Duration(days: offset)),
        sessionType: cycle[(startIndex + offset) % cycle.length],
      );
    });
  }

  int _resolveStartIndex(List<TrainingSessionType> cycle) {
    if (_nextStepIndex >= 0 &&
        _nextStepIndex < cycle.length &&
        cycle[_nextStepIndex] == _nextSessionType) {
      return _nextStepIndex;
    }

    final matchedIndex = cycle.indexOf(_nextSessionType);
    return matchedIndex >= 0 ? matchedIndex : 0;
  }

  Future<void> _saveProgramLogic({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    final snapshot = await _trainingProgramStoreService.updateProgramLogic(
      userId: userId,
      programType: programType,
      branchSelections: branchSelections,
      repGoalProfile: repGoalProfile,
    );

    if (!mounted) return;

    setState(() {
      _selectedProgramType = snapshot.program.programType;
      _scheduleVariant = snapshot.program.scheduleVariant;
      _branchSelections = {
        ..._trainingProgramService.defaultBranchSelections(),
        ...snapshot.branchSelections,
      };
      _repGoalProfile = snapshot.repGoalProfile;
      _nextStepIndex = snapshot.state.nextStepIndex;
      _nextSessionType = snapshot.state.nextSessionType;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
        branchSelections: _branchSelections,
      );
    });
  }

  Future<void> _openProgramLogic() async {
    final logicSnapshot = TrainingProgramLogicSnapshot(
      program: UserTrainingProgram(
        id: 'local',
        userId: '',
        programType: _selectedProgramType,
        scheduleVariant: _scheduleVariant,
        frequencyPerWeek: 3,
        variationRules: {
          'rep_goal_profile': _repGoalProfile.dbValue,
        },
        isActive: true,
      ),
      state: UserTrainingProgramState(
        id: 'local',
        programId: 'local',
        userId: '',
        nextStepIndex: _nextStepIndex,
        nextSessionType: _nextSessionType,
      ),
      branchSelections: _branchSelections,
      repGoalProfile: _repGoalProfile,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingProgramLogicView(
          initialLogic: logicSnapshot,
          progressMap: _progressMap,
          onSave: _saveProgramLogic,
        ),
      ),
    );

    if (!mounted) return;
    await _loadRecommendation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _homeBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: LoadingIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HomeHeader(),
                    const SizedBox(height: 16),
                    if (_recommendation != null)
                      _TrainingProgramCard(
                        recommendation: _recommendation!,
                        onEditProgram: _openProgramLogic,
                      ),
                    const SizedBox(height: 24),
                    _ScheduleSection(
                      entries: _buildUpcomingSchedule(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TrainingProgramCard extends StatelessWidget {
  final DailyTrainingRecommendation recommendation;
  final VoidCallback onEditProgram;

  const _TrainingProgramCard({
    required this.recommendation,
    required this.onEditProgram,
  });

  void _openSessionOverview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionOverviewView(
          recommendation: recommendation,
        ),
      ),
    );
  }

  void _openLiveWorkout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveWorkoutView(
          recommendation: recommendation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionTitle = recommendation.isRestDay
        ? 'Recovery'
        : _sessionTypeLabel(recommendation.sessionType);
    final previewItems = recommendation.items.take(4).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _groupBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sessionTitle,
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.0,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onEditProgram,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.accentPrimary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      'Edit program',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recommendation.isRestDay)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _groupBgHi,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Take the day to recover, then review the next session and keep the split moving.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 8),
                    child: Text(
                      'EXERCISES',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _groupBgHi,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < previewItems.length;
                            index++)
                          _ExercisePreviewRow(
                            item: previewItems[index],
                            index: index,
                            showDivider: index != 0,
                          ),
                        if (recommendation.items.length > previewItems.length)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: _hairline),
                              ),
                            ),
                            child: Text(
                              '+ ${recommendation.items.length - previewItems.length} more',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                letterSpacing: -0.05,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: GestureDetector(
              onTap: recommendation.isRestDay
                  ? () => _openSessionOverview(context)
                  : () => _openLiveWorkout(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      recommendation.isRestDay ? 'View plan' : 'Start workout',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingScheduleEntry {
  final DateTime date;
  final TrainingSessionType sessionType;

  const _UpcomingScheduleEntry({
    required this.date,
    required this.sessionType,
  });

  bool get isRestDay => sessionType == TrainingSessionType.rest;

  bool get isToday {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Today',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ExercisePreviewRow extends StatelessWidget {
  final TrainingRecommendationItem item;
  final int index;
  final bool showDivider;

  const _ExercisePreviewRow({
    required this.item,
    required this.index,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                top: BorderSide(color: _hairline),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _trackShortLabel(item.track),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final List<_UpcomingScheduleEntry> entries;

  const _ScheduleSection({
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'UPCOMING',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ScheduleCard(entries: entries),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final List<_UpcomingScheduleEntry> entries;

  const _ScheduleCard({
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _emptyStateBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Text(
          'No upcoming sessions available.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _ScheduleRow(
            entry: entries[index],
          ),
          if (index != entries.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final _UpcomingScheduleEntry entry;

  const _ScheduleRow({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = entry.isToday
        ? AppColors.accentPrimary.withValues(alpha: 0.4)
        : AppColors.borderPrimary;
    final surfaceColor = entry.isToday
        ? AppColors.bgTertiary.withValues(alpha: 0.9)
        : _emptyStateBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayShortLabel(entry.date),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: entry.isToday
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.date.day.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _monthShortLabel(entry.date),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sessionTypeLabel(entry.sessionType).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.isToday
                  ? AppColors.accentPrimary.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.isToday
                    ? AppColors.accentPrimary.withValues(alpha: 0.24)
                    : AppColors.borderPrimary,
              ),
            ),
            child: Icon(
              entry.isRestDay ? Icons.nightlight_round : Icons.fitness_center,
              size: 18,
              color: entry.isToday
                  ? AppColors.accentPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayShortLabel(DateTime date) {
  const weekdayNames = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  return weekdayNames[date.weekday - 1];
}

String _monthShortLabel(DateTime date) {
  const monthNames = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  return monthNames[date.month - 1];
}

String _trackShortLabel(TrainingTrack track) {
  switch (track) {
    case TrainingTrack.skillWork:
      return 'SKILL';
    case TrainingTrack.verticalPush:
      return 'V PUSH';
    case TrainingTrack.horizontalPush:
      return 'H PUSH';
    case TrainingTrack.verticalPull:
      return 'V PULL';
    case TrainingTrack.horizontalPull:
      return 'H PULL';
    case TrainingTrack.core:
      return 'CORE';
    case TrainingTrack.squat:
      return 'SQUAT';
    case TrainingTrack.hinge:
      return 'HINGE';
  }
}

String _sessionTypeLabel(TrainingSessionType sessionType) {
  switch (sessionType) {
    case TrainingSessionType.fullBody:
      return 'Full Body';
    case TrainingSessionType.push:
      return 'Push';
    case TrainingSessionType.pull:
      return 'Pull';
    case TrainingSessionType.upper:
      return 'Upper';
    case TrainingSessionType.lower:
      return 'Lower';
    case TrainingSessionType.rest:
      return 'Rest Day';
  }
}
