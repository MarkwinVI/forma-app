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

const _cardShadow = Color(0x40000000);
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
      return _UpcomingScheduleEntry(
        date: startDate.add(Duration(days: index)),
        sessionType: cycle[(startIndex + index) % cycle.length],
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
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: _loading
            ? const Center(child: LoadingIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
    final now = DateTime.now();
    final sessionTitle =
        _sessionTypeLabel(recommendation.sessionType).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'TODAY',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderPrimary),
              boxShadow: const [
                BoxShadow(
                  color: _cardShadow,
                  blurRadius: 50,
                  offset: Offset(0, 25),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${_weekdayShortLabel(now)} · ${_monthShortLabel(now)} ${now.day}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        recommendation.isRestDay
                            ? 'RECOVERY'
                            : '${recommendation.items.length} EXERCISES',
                        style: recommendation.isRestDay
                            ? GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 1.4,
                              )
                            : GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.48,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        sessionTitle,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -2.4,
                          height: 0.88,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: recommendation.isRestDay
                              ? () => _openSessionOverview(context)
                              : () => _openLiveWorkout(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentPrimary.withValues(
                                    alpha: 0.32,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  recommendation.isRestDay
                                      ? 'VIEW PLAN'
                                      : 'START WORKOUT',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEditProgram,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
