import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../progress/skill_tree_actions.dart';
import '../progress/skill_wheel_bundle.dart';
import '../progress/widgets/skill_wheel.dart';
import '../progress/widgets/skill_wheel_screen.dart';

/// What the wheel hands back to a workout that opened it to add a
/// progression: the tree, and the exercise it trains.
class SkillWheelPick {
  final String skillCategoryId;
  final String exerciseId;

  const SkillWheelPick({
    required this.skillCategoryId,
    required this.exerciseId,
  });
}

/// The Program tab's door into the skill trees: the same radial wheel the
/// Progress tab shows, opened straight into its edit mode — start a
/// progression at a node, move it to another node, or stop training a tree
/// — with Done as the way back to the Program tab.
class ProgramSkillWheelView extends StatefulWidget {
  /// Fly straight into this tree on open.
  final String? initialCategoryId;

  /// Backing out of the tree pops this whole view instead of pulling out to
  /// the wheel overview — for hosts (the workout editor) where the wheel
  /// would be a detour on the way back.
  final bool exitOnTreeBack;

  /// Where the user came in from, for analytics — the Program tab's
  /// overview, a workout's Add exercise, or the Progress tab's Edit.
  final String source;

  /// The workout a progression is being added to, by name. Set, the wheel
  /// is a picker for that workout: it pops with a [SkillWheelPick] once an
  /// exercise is chosen, and with nothing when the user backs out.
  final String? addingTo;

  const ProgramSkillWheelView({
    super.key,
    this.initialCategoryId,
    this.exitOnTreeBack = false,
    this.source = 'program_tab',
    this.addingTo,
  });

  @override
  State<ProgramSkillWheelView> createState() => _ProgramSkillWheelViewState();
}

class _ProgramSkillWheelViewState extends State<ProgramSkillWheelView> {
  final _actions = SkillTreeActions();

  bool _loading = true;
  bool _loadFailed = false;
  SkillWheelBundle? _bundle;

  /// What a saved edit chose, for a host that is adding a progression.
  SkillWheelPick? _pick;

  @override
  void initState() {
    super.initState();
    AnalyticsService.screen('program_skill_wheel');
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final bundle = await loadSkillWheelBundle(userId);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
        _loadFailed = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load skill trees: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    await _load();
  }

  /// A failed write is said once, and the wheel stays as it was.
  void _couldNotSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't save that change. Try again.")),
    );
  }

  /// True once the write landed — the wheel then confirms it with a toast
  /// and, this screen being its own route, leaves through Done.
  Future<bool> _trainNode(WheelFamily family, WheelNode node) async {
    final userId = AuthService().currentUser?.id;
    final bundle = _bundle;
    if (userId == null || bundle == null) return false;
    final saved = await _actions.trainNode(
      userId: userId,
      bundle: bundle,
      family: family,
      node: node,
      source: widget.source,
    );
    if (!mounted) return false;
    if (!saved) {
      _couldNotSave();
      return false;
    }
    _pick = SkillWheelPick(
      skillCategoryId: family.categoryId,
      exerciseId: node.exerciseId,
    );
    await _load();
    return true;
  }

  Future<bool> _stopTraining(WheelFamily family) async {
    final userId = AuthService().currentUser?.id;
    final bundle = _bundle;
    if (userId == null || bundle == null) return false;
    final saved = await _actions.stopTraining(
      userId: userId,
      bundle: bundle,
      family: family,
      source: widget.source,
    );
    if (!mounted) return false;
    if (!saved) {
      _couldNotSave();
      return false;
    }
    await _load();
    return true;
  }

  void _openExercise(WheelNode node) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    if (exercise == null) return;
    AnalyticsService.capture('skill_tree_exercise_opened', properties: {
      'exercise_id': node.exerciseId,
      'node_state': node.state.name,
      if (exercise.skillCategoryId.isNotEmpty)
        'skill_tree_id': exercise.skillCategoryId,
      'source': widget.source,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: LoadingIndicator())
            : bundle == null || bundle.families.isEmpty
                ? SkillWheelEmptyState(
                    failed: _loadFailed,
                    onBack: () => Navigator.of(context).pop(),
                    onRetry: _retry,
                  )
                // Opens in edit mode, and Done is the way back to where the
                // user came from. Back only leaves from inside a tree, for
                // the hosts that opened straight into one.
                : SkillWheelScreen(
                    families: bundle.families,
                    stepStats: bundle.stepStats,
                    activeCategoryIds: bundle.activeCategoryIds,
                    treeLocks: bundle.treeLocks,
                    editable: true,
                    startEditing: true,
                    source: widget.source,
                    onTrainNode: _trainNode,
                    onStopTraining: _stopTraining,
                    onOpenExercise: _openExercise,
                    onDone: () => Navigator.of(context).pop(_pick),
                    onBack: widget.exitOnTreeBack || widget.addingTo != null
                        ? () => Navigator.of(context).pop()
                        : null,
                    addingTo: widget.addingTo,
                    // The exercise a tree already trains needs no write —
                    // picking it is the whole answer.
                    onAddTrained: (family, node) => Navigator.of(context).pop(
                      SkillWheelPick(
                        skillCategoryId: family.categoryId,
                        exerciseId: node.exerciseId,
                      ),
                    ),
                    initialCategoryId: widget.initialCategoryId,
                    exitOnTreeBack: widget.exitOnTreeBack,
                  ),
      ),
    );
  }
}

/// What the wheel shows when there is nothing to draw: the load failed, or
/// there are no trees to show. Either way the way back stays on screen.
///
/// Public for its tests.
class SkillWheelEmptyState extends StatelessWidget {
  final bool failed;
  final VoidCallback onBack;
  final Future<void> Function() onRetry;

  const SkillWheelEmptyState({
    super.key,
    required this.failed,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SubScreenHeader(title: 'Skill trees', onBack: onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 130),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TypeTitle(
                  failed
                      ? "Couldn't load your skill trees"
                      : 'No skill trees yet',
                  size: 28,
                  sub: failed
                      ? 'Check your connection and try again.'
                      : 'Create a program first — its skill trees show up '
                          'here, ready to explore.',
                ),
                if (failed) ...[
                  const SizedBox(height: 26),
                  PillButton(
                    semanticLabel: 'Retry loading skill trees',
                    label: 'Retry',
                    radius: 14,
                    tonal: true,
                    onTap: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
