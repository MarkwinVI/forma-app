import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/forma_splash.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../program/program_view.dart';
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
  bool _loading = true;
  SkillWheelBundle? _bundle;

  @override
  void initState() {
    super.initState();
    // A warm-up that already landed (main() starts one during the splash)
    // is taken synchronously: the tab's first frame is the wheel, with no
    // waiting state in between.
    final warm = takeWarmSkillWheelBundle();
    final ready = warm?.value;
    if (ready != null) {
      _bundle = ready;
      _loading = false;
    } else {
      _loadData(warm: warm);
    }
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

  Future<void> _loadData({WarmSkillWheelBundle? warm}) async {
    // A load started elsewhere, when there is one — by main() during the
    // splash, or by the setup wizard once it has written the program — so
    // the tab appears with its data already fetched. It was started for the
    // signed-in user, so it stands on its own even before this tab reads
    // the session.
    warm ??= takeWarmSkillWheelBundle();
    final userId = AuthService().currentUser?.id;
    if (warm == null && userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // Whatever the tab was showing before is about to be wrong, so it
      // does not stay up while the warm bundle lands.
      if (warm != null && !_loading && mounted) {
        setState(() => _loading = true);
      }
      final bundle = await (warm?.future ?? loadSkillWheelBundle(userId!));
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load progress data: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _loading = false);
      // With an older wheel still up, the failure is a passing note; with
      // nothing to show, the tab itself becomes the error state (see build).
      if (_bundle != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't refresh your progress."),
            action: SnackBarAction(label: 'Retry', onPressed: _retryLoad),
          ),
        );
      }
    }
  }

  Future<void> _retryLoad() async {
    setState(() => _loading = true);
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
    // No wheel to draw: the read failed, or came back without the program
    // the entry gate saw — either way, Retry.
    final failed = !_loading &&
        (bundle == null || !bundle.hasProgram || bundle.families.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            // While the first load is still in flight the splash's last
            // frame holds the page — the tab reads as the splash lingering,
            // not a loader — and it never appears when the warm-up already
            // landed (see initState).
            ? const FormaSplash.endFrame(background: AppColors.bg)
            : failed
                ? ProgramLoadErrorState(onRetry: _retryLoad)
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
