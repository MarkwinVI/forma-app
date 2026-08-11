import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/no_program_state.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../home/program_overview_view.dart';
import '../home/program_setup_completion.dart';
import '../home/program_setup_view.dart';

/// Program tab — hosts the program overview (training days, split, sessions,
/// goal skills) that used to be reached through "Your program" on Train.
class ProgramView extends StatefulWidget {
  final bool isActive;

  /// Fired after the setup wizard has written a program and been dismissed,
  /// so the shell can move the user on to Progress, their new home tab.
  final VoidCallback? onProgramCreated;

  const ProgramView({
    super.key,
    this.isActive = false,
    this.onProgramCreated,
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
    var created = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramSetupView(
          onComplete: (result) async {
            await _completeProgramSetup(result);
            created = true;
          },
        ),
      ),
    );
    // Abandoning the wizard midway must not move the user, so the redirect
    // only fires once a program was actually written and the wizard closed.
    if (created) widget.onProgramCreated?.call();
    // Re-fetch so the tab reflects the freshly created program even if the
    // user abandoned the wizard midway on a stale state.
    await _loadData();
  }

  Future<void> _completeProgramSetup(ProgramSetupResult result) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;

    await completeProgramSetup(
      userId: userId,
      result: result,
      trainingProgramService: _trainingProgramService,
      storeService: _trainingProgramStoreService,
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
      // The tab that owns setup carries the detail: what it will ask for and
      // what comes back, over the program that does not exist yet.
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.accentPrimary,
            backgroundColor: AppColors.surface,
            onRefresh: _loadData,
            child: NoProgramState(
              title: 'Build your training program',
              sub: 'Answer a few questions. Forma builds your program and '
                  'adjusts it as you get stronger.',
              onCreateProgram: _openProgramSetup,
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
