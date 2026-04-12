import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import 'training_program_settings_view.dart';

const _cardShadow = Color(0x40000000);
const _emptyStateBg = Color(0x05FFFFFF);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _exerciseLogService = ExerciseLogService();
  final _progressService = ProgressService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  bool _hasPerformanceData = false;
  Map<String, ExerciseStatus> _progressMap = {};
  DailyTrainingRecommendation? _recommendation;
  TrainingProgramType _selectedProgramType = TrainingProgramType.fullBody;
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
    var hasPerformanceData = false;

    if (userId != null) {
      try {
        hasPerformanceData =
            await _exerciseLogService.hasAtLeastTwoLogs(userId);

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
      _hasPerformanceData = hasPerformanceData;
      _progressMap = progressMap;
      _selectedProgramType =
          programSnapshot?.program.programType ?? TrainingProgramType.fullBody;
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
      _nextSessionType = snapshot.state.nextSessionType;
      _recommendation = _trainingProgramService.buildToday(
        progressMap: _progressMap,
        programType: _selectedProgramType,
        sessionType: _nextSessionType,
      );
    });
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
                    Text(
                      'Home',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_recommendation != null)
                      _TrainingProgramCard(
                        recommendation: _recommendation!,
                        onEditProgram: _openProgramSettings,
                      ),
                    const SizedBox(height: 24),
                    _PerformanceSection(
                      hasPerformanceData: _hasPerformanceData,
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

  String _exerciseSummary() {
    if (recommendation.items.isEmpty) {
      return 'Recover today and come back ready for your next session.';
    }

    return recommendation.items.map((item) => item.exercise.name).join(', ');
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
                  'Today',
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
                      const SizedBox(height: 12),
                      Text(
                        _exerciseSummary(),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () {},
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

class _PerformanceSection extends StatelessWidget {
  final bool hasPerformanceData;

  const _PerformanceSection({
    required this.hasPerformanceData,
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
                    'My Performance',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'OPEN',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'LAST 14 DAYS VS PREV. 14 DAYS',
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
        _PerformanceCard(
          hasPerformanceData: hasPerformanceData,
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final bool hasPerformanceData;

  const _PerformanceCard({
    required this.hasPerformanceData,
  });

  @override
  Widget build(BuildContext context) {
    if (hasPerformanceData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _emptyStateBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Text(
          'Performance insights coming soon.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: _emptyStateBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.bgTertiary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.query_stats,
              size: 24,
              color: Color(0xFF52525C),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No performance data yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 240,
            child: Text(
              'Finish your first workout to start tracking your strength trends over time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
