import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../home/program_overview_view.dart';
import '../progress/skill_wheel_bundle.dart';

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
    // The landing gate has usually already loaded progress and program
    // logic into the warm bundle; start from that instead of a loader, and
    // let the fresh read below replace it quietly.
    final warm = peekWarmSkillWheelBundle()?.value;
    if (warm != null) {
      _progressMap = Map.of(warm.progressMap);
      _logicSnapshot = warm.logicSnapshot;
      _loading = false;
    }
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProgramView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — progress made on another tab would otherwise
    // leave this one stale.
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
      final fetched = results[1] as TrainingProgramLogicSnapshot?;
      setState(() {
        _progressMap = {
          for (final item in progress) item.exerciseId: item.status,
        };
        // Re-key the hosted overview only when the program actually changed
        // elsewhere — the key change resets all of its state, scroll
        // position included, and coming back to the tab is not a change.
        if (!sameProgramLogic(_logicSnapshot, fetched)) {
          _generation++;
        }
        _logicSnapshot = fetched;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load program data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _retryLoad() async {
    setState(() => _loading = true);
    await _loadData();
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

  @override
  Widget build(BuildContext context) {
    final snapshot = _logicSnapshot;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: Center(child: LoadingIndicator())),
      );
    }

    // No program to host: the read failed, or came back without the program
    // the entry gate saw — either way, Retry.
    if (snapshot == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: ProgramLoadErrorState(onRetry: _retryLoad),
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

/// The Program tab when the fetch came back without a program: names the
/// problem and offers the one way out — the program on the server is almost
/// certainly fine.
///
/// Public for its tests.
class ProgramLoadErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const ProgramLoadErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: AppColors.accentPrimary,
          backgroundColor: AppColors.surface,
          onRefresh: onRetry,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 130),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Program', style: monoStyle()),
                    const SizedBox(height: 10),
                    const TypeTitle(
                      "Couldn't load your program",
                      sub: 'Check your connection and try again. Your '
                          'program is still saved.',
                    ),
                    const SizedBox(height: 26),
                    PillButton(
                      semanticLabel: 'Retry loading your program',
                      label: 'Retry',
                      radius: 14,
                      tonal: true,
                      onTap: onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Whether two fetches describe the same program, by content — the models
/// carry no timestamps, so the fields the overview seeds itself from are the
/// comparison. Progress is deliberately not part of it: the overview reads
/// that live from its widget, so it needs no re-seed to pick it up.
///
/// Public for its tests.
bool sameProgramLogic(
  TrainingProgramLogicSnapshot? a,
  TrainingProgramLogicSnapshot? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;

  return a.program.id == b.program.id &&
      a.program.programType == b.program.programType &&
      a.program.scheduleVariant == b.program.scheduleVariant &&
      a.program.frequencyPerWeek == b.program.frequencyPerWeek &&
      a.program.isActive == b.program.isActive &&
      _sameJson(a.program.variationRules, b.program.variationRules) &&
      _sameJson(a.program.goalSkillIds, b.program.goalSkillIds) &&
      a.state.nextStepIndex == b.state.nextStepIndex &&
      a.state.nextSessionType == b.state.nextSessionType &&
      a.state.lastSessionType == b.state.lastSessionType &&
      a.state.lastCompletedAt == b.state.lastCompletedAt &&
      a.repGoalProfile == b.repGoalProfile &&
      _sameJson(
        a.branchSelections.map((track, branch) => MapEntry(track.name, branch)),
        b.branchSelections.map((track, branch) => MapEntry(track.name, branch)),
      );
}

/// Deep equality for the JSON-shaped parts, immune to map key order — jsonb
/// comes back with sorted keys where locally built maps keep insertion order.
bool _sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_sameJson(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameJson(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
