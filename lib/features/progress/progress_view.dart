import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/no_program_state.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/training_program_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../home/program_day_items.dart';
import '../home/program_setup_completion.dart';
import '../home/program_setup_view.dart';
import 'skill_wheel_bundle.dart';
import 'widgets/skill_wheel.dart';
import 'widgets/skill_wheel_screen.dart';

/// Progress tab — every skill tree on one radial wheel. Tap a family to fly
/// in, swipe up/down to spin between families, swipe left/right to walk the
/// steps, tap the background to pull back out.
class ProgressView extends StatefulWidget {
  final bool isActive;

  const ProgressView({
    super.key,
    this.isActive = false,
  });

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final _trainingProgramService = TrainingProgramService();
  final _trainingProgramStoreService = TrainingProgramStoreService();

  bool _loading = true;
  SkillWheelBundle? _bundle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The shell keeps tabs alive in an IndexedStack, so re-fetch whenever
    // this tab becomes active — workouts logged or nodes cleared elsewhere
    // would otherwise leave the trees showing stale statuses.
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
      // A load started elsewhere, when there is one — by main() during the
      // splash, or by the setup wizard once it has written the program — so
      // the tab appears with its data already fetched. Whatever the tab was
      // showing before is about to be wrong, so it does not stay up while
      // the warm bundle lands.
      final warmBundle = takeWarmSkillWheelBundle();
      if (warmBundle != null && !_loading && mounted) {
        setState(() => _loading = true);
      }
      final bundle = await (warmBundle ?? loadSkillWheelBundle(userId));
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load progress data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load your progress. Pull down to retry."),
        ),
      );
    }
  }

  Future<void> _openProgramSetup() async {
    // The setup wizard takes over the whole screen, above the tab bar.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ProgramSetupView(
          onComplete: _completeProgramSetup,
        ),
      ),
    );
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

  void _openExercise(WheelNode node) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    if (exercise == null) return;
    AnalyticsService.capture('skill_tree_exercise_opened', properties: {
      'exercise_id': node.exerciseId,
      'node_state': node.state.name,
      if (exercise.skillCategoryId.isNotEmpty)
        'skill_tree_id': exercise.skillCategoryId,
      'source': 'progress_tab',
    });
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailView(
          exercise: exercise,
          skillCategoryId: exercise.skillCategoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    final empty = !_loading &&
        (bundle == null || !bundle.hasProgram || bundle.families.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : empty
                ? _ProgressEmptyState(onCreateProgram: _openProgramSetup)
                : SkillWheelScreen(
                    families: bundle!.families,
                    journeyByCategory: bundle.journeyByCategory,
                    activeCategoryIds: bundle.activeCategoryIds,
                    treeLocks: bundle.treeLocks,
                    performance: bundle.performance,
                    onOpenExercise: _openExercise,
                  ),
      ),
    );
  }
}

/// Progress before any training: the six movement paths named, none of them
/// started, framed as what the tab will show rather than what it lacks.
class _ProgressEmptyState extends StatelessWidget {
  final VoidCallback onCreateProgram;

  const _ProgressEmptyState({required this.onCreateProgram});

  static const _paths = [
    ExerciseCategory.horizontalPush,
    ExerciseCategory.verticalPush,
    ExerciseCategory.horizontalPull,
    ExerciseCategory.verticalPull,
    ExerciseCategory.squat,
    ExerciseCategory.core,
  ];

  @override
  Widget build(BuildContext context) {
    return NoProgramState(
      title: 'See how your strength develops',
      sub: 'Hit your rep targets to climb each skill tree and unlock harder '
          'exercises.',
      onCreateProgram: onCreateProgram,
      children: [
        const TypeSectionLabel('Skill trees'),
        for (var i = 0; i < _paths.length; i++)
          GhostRow(
            name: programPatternLabel(_paths[i]),
            note: 'NOT STARTED',
            nameSize: 19,
            last: i == _paths.length - 1,
          ),
      ],
    );
  }
}
