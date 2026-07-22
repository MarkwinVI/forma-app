import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../home/program_overview_view.dart';
import '../home/program_setup_view.dart';

/// Program tab — hosts the program overview (training days, split, sessions,
/// goal skills) that used to be reached through "Your program" on Train.
class ProgramView extends StatefulWidget {
  final bool isActive;

  const ProgramView({
    super.key,
    this.isActive = false,
  });

  @override
  State<ProgramView> createState() => _ProgramViewState();
}

class _ProgramViewState extends State<ProgramView> {
  final _progressService = ProgressService();
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  Map<String, ExerciseStatus> _progressMap = {};
  TrainingProgramLogicSnapshot? _logicSnapshot;

  /// Bumped on every fetch so the hosted overview re-seeds its local state
  /// from the fresh snapshot (it copies `initialLogic` in initState).
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProgramView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — a program created or reset elsewhere would
    // otherwise leave this tab stale.
    if (!oldWidget.isActive && widget.isActive) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _progressService.fetchAll(userId),
        _trainingProgramStoreService.fetchProgramLogic(userId),
      ]);

      if (!mounted) return;
      final progress = results[0] as List<ExerciseProgress>;
      setState(() {
        _progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
        _logicSnapshot = results[1] as TrainingProgramLogicSnapshot?;
        _generation++;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load program data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load your program. Try again later."),
        ),
      );
    }
  }

  Future<TrainingProgramLogicSnapshot> _saveProgramLogic({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      return _logicSnapshot!;
    }

    final snapshot = await _trainingProgramStoreService.updateProgramLogic(
      userId: userId,
      programType: programType,
      branchSelections: branchSelections,
      repGoalProfile: repGoalProfile,
      sessionItemsConfig: sessionItemsConfig,
      frequencyPerWeek: frequencyPerWeek,
      setupAnswers: setupAnswers,
    );
    // Keep the tab's copy in sync without rebuilding the hosted overview —
    // it manages its own state between fetches.
    _logicSnapshot = snapshot;
    return snapshot;
  }

  Future<void> _openProgramSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSetupView(
          onComplete: _completeProgramSetup,
        ),
      ),
    );
    // Re-fetch so the tab reflects the freshly created program even if the
    // user abandoned the wizard midway on a stale state.
    await _loadData();
  }

  Future<void> _completeProgramSetup(ProgramSetupResult result) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    await _trainingProgramStoreService.updateProgramLogic(
      userId: userId,
      programType: result.split,
      // Goal skills pick their branch from day one; every other track
      // starts on its default.
      branchSelections: {
        ..._trainingProgramService.defaultBranchSelections(),
        ..._trainingProgramService.branchSelectionsForGoals(result.skillIds),
      },
      repGoalProfile: RepGoalProfile.balanced,
      sessionItemsConfig: const {},
      frequencyPerWeek: result.daysPerWeek,
      setupAnswers: result.toMap(),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _logicSnapshot;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: Center(child: LoadingIndicator())),
      );
    }

    if (snapshot == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.accentPrimary,
            backgroundColor: AppColors.surface,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(title: 'Program'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: SurfaceCard(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set up your training program',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.48,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tell Forma your goals and schedule. We’ll build a '
                            'balanced program across every movement pattern — '
                            'and adapt it as you progress.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PillButton(
                            label: 'Build my program',
                            icon: Icons.chevron_right_rounded,
                            trailingIcon: true,
                            onTap: _openProgramSetup,
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Takes about 2 minutes',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ProgramOverviewView(
      key: ValueKey('program-$_generation'),
      initialLogic: snapshot,
      progressMap: _progressMap,
      onSave: _saveProgramLogic,
    );
  }
}
