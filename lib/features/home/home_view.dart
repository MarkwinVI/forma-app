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
import 'session_overview_view.dart';
import 'training_program_settings_view.dart';

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
    UserTrainingProgramSnapshot? programSnapshot;

    if (userId != null) {
      try {
        final progress = await _progressService.fetchAll(userId);
        for (final item in progress) {
          progressMap[item.exerciseId] = item.status;
        }

        programSnapshot =
            await _trainingProgramStoreService.getOrCreateActiveProgram(
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
          programSnapshot?.program.programType ?? TrainingProgramType.fullBody;
      _scheduleVariant = programSnapshot?.program.scheduleVariant;
      _nextStepIndex = programSnapshot?.state.nextStepIndex ?? 0;
      _nextSessionType = programSnapshot?.state.nextSessionType ??
          TrainingSessionType.fullBody;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
      );
      _loading = false;
    });
  }

  Future<void> _saveProgramType(TrainingProgramType type) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null || type == _selectedProgramType) return;

    final snapshot = await _trainingProgramStoreService.updateProgramType(
      userId: userId,
      programType: type,
    );

    if (!mounted) return;

    setState(() {
      _selectedProgramType = snapshot.program.programType;
      _scheduleVariant = snapshot.program.scheduleVariant;
      _nextStepIndex = snapshot.state.nextStepIndex;
      _nextSessionType = snapshot.state.nextSessionType;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
      );
    });
  }

  List<_UpcomingScheduleEntry> _buildUpcomingSchedule() {
    final cycle = _scheduleCycleFor(
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

  List<TrainingSessionType> _scheduleCycleFor({
    required TrainingProgramType programType,
    required String? scheduleVariant,
  }) {
    switch (scheduleVariant) {
      case 'push_rest_pull_rest_push_pull_rest':
        return const [
          TrainingSessionType.push,
          TrainingSessionType.rest,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
        ];
      case 'upper_rest_lower_rest_upper_lower_rest':
        return const [
          TrainingSessionType.upper,
          TrainingSessionType.rest,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
          TrainingSessionType.upper,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
        ];
      case 'full_body_3x':
        return const [
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
        ];
    }

    switch (programType) {
      case TrainingProgramType.pushPull:
        return const [
          TrainingSessionType.push,
          TrainingSessionType.rest,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
          TrainingSessionType.push,
          TrainingSessionType.pull,
          TrainingSessionType.rest,
        ];
      case TrainingProgramType.upperLower:
        return const [
          TrainingSessionType.upper,
          TrainingSessionType.rest,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
          TrainingSessionType.upper,
          TrainingSessionType.lower,
          TrainingSessionType.rest,
        ];
      case TrainingProgramType.fullBody:
        return const [
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.fullBody,
          TrainingSessionType.rest,
          TrainingSessionType.rest,
        ];
    }
  }

  Future<void> _openProgramSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingProgramSettingsView(
          initialProgramType: _selectedProgramType,
          onSave: _saveProgramType,
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
                        onEditProgram: _openProgramSettings,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  'Train',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'VIEW PROGRAM',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 81,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderPrimary),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x05FFFFFF),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          recommendation.sessionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.65,
                          ),
                        ),
                      ),
                      _TrainingProgramMenuButton(
                        onEditProgram: onEditProgram,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EXERCISES',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _openSessionOverview(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 30,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 20,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'START WORKOUT',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: -0.425,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingProgramMenuButton extends StatefulWidget {
  final VoidCallback onEditProgram;

  const _TrainingProgramMenuButton({
    required this.onEditProgram,
  });

  @override
  State<_TrainingProgramMenuButton> createState() =>
      _TrainingProgramMenuButtonState();
}

class _TrainingProgramMenuButtonState
    extends State<_TrainingProgramMenuButton> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(-132, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.bgTertiary),
        surfaceTintColor: WidgetStateProperty.all(AppColors.bgTertiary),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.borderPrimary),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onEditProgram();
          },
          child: Text(
            'Edit program',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
            setState(() {});
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.more_horiz,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
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
                    'Schedule',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'UPCOMING 5 DAYS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _emptyStateBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No upcoming sessions available.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _ScheduleRow(entry: entries[index]),
                  if (index != entries.length - 1)
                    const Divider(
                      height: 1,
                      color: AppColors.borderPrimary,
                    ),
                ],
              ],
            ),
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
    final accentColor =
        entry.isRestDay ? AppColors.textMuted : AppColors.accentPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayLabel(entry.date),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel(entry.date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              _sessionTypeLabel(entry.sessionType),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayLabel(DateTime date) {
  const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return weekdayNames[date.weekday - 1];
}

String _dateLabel(DateTime date) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${monthNames[date.month - 1]} ${date.day}';
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
