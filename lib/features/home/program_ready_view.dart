import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/forma_splash.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/membership_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/membership_service.dart';
import '../exercises/exercise_detail_view.dart';
import '../membership/membership_copy.dart';
import '../membership/paywall_sheet.dart';
import '../progress/skill_wheel_bundle.dart';
import '../progress/widgets/skill_wheel.dart';
import '../progress/widgets/skill_wheel_screen.dart';

/// The end of the setup wizard: the map the answers drew — every tree on
/// the wheel, blue where the program starts — with the starting exercise
/// of each running tree listed under it, and the way on: the trial, or
/// "Not now" into the locked app.
///
/// Tapping a tree opens the full read-only wheel over this screen, the
/// same one the Progress tab shows; backing out of it lands here again, so
/// the choice at the bottom is always where the user ends up.
class ProgramReadyView extends StatefulWidget {
  final int daysPerWeek;
  final MembershipService service;

  /// Leaves the wizard — after "Not now", or once a purchase has landed.
  final VoidCallback onDone;

  /// The wheel data, for tests. Left null, the screen picks up the warm
  /// bundle setup started, or loads its own.
  final Future<SkillWheelBundle>? bundle;

  const ProgramReadyView({
    super.key,
    required this.daysPerWeek,
    required this.service,
    required this.onDone,
    this.bundle,
  });

  @override
  State<ProgramReadyView> createState() => _ProgramReadyViewState();
}

class _ProgramReadyViewState extends State<ProgramReadyView>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1300);

  final _wheelController = SkillWheelController();
  late final AnimationController _reveal;

  SkillWheelBundle? _bundle;
  bool _loading = true;
  List<MembershipPlan>? _plans;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: _duration);
    AnalyticsService.screen('program_ready');
    _load();
    widget.service.plans().then((plans) {
      if (mounted) setState(() => _plans = plans);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Setup started the wheel's load the moment it wrote the program; the
    // Progress tab takes that warm-up later, so this only looks at it.
    var future = widget.bundle ?? peekWarmSkillWheelBundle()?.future;
    if (future == null) {
      final userId = _signedInUserId();
      if (userId != null) future = loadSkillWheelBundle(userId);
    }
    SkillWheelBundle? bundle;
    try {
      bundle = await future;
    } catch (error, stackTrace) {
      debugPrint('Failed to load the program map: $error\n$stackTrace');
    }
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _loading = false;
    });
    _reveal.forward();
  }

  /// Null when nobody is signed in — or, in a widget test, when there is
  /// no Supabase to ask.
  static String? _signedInUserId() {
    try {
      return AuthService().currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Staggered ease-out, one segment per block down the page.
  Animation<double> _segment(int index) {
    final start = (100 + index * 110) / _duration.inMilliseconds;
    final end = start + 520 / _duration.inMilliseconds;
    return CurvedAnimation(
      parent: _reveal,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// A tree tapped on the overview opens the full wheel, flown into that
  /// tree. The wheel here pulls back out meanwhile, so the page is on its
  /// overview again when the user returns.
  void _onWheelChanged(int? selected, int focus) {
    final bundle = _bundle;
    if (selected == null || bundle == null) return;
    final family = bundle.families[selected];
    AnalyticsService.capture('skill_tree_opened', properties: {
      'skill_tree_id': family.categoryId,
      'source': 'program_ready',
      'is_active': bundle.activeCategoryIds.contains(family.categoryId),
    });
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _ProgramReadyWheelScreen(
          bundle: bundle,
          initialCategoryId: family.categoryId,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _wheelController.back();
    });
  }

  Future<void> _startTrial() async {
    final entitled = await showPaywallSheet(
      context,
      service: widget.service,
      source: 'program_ready',
    );
    if (entitled && mounted) widget.onDone();
  }

  void _notNow() {
    AnalyticsService.capture('paywall_deferred', properties: {
      'source': 'program_ready',
    });
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: FormaSplash.endFrame(background: AppColors.bg),
      );
    }

    final bundle = _bundle;
    final families = bundle?.families ?? const <WheelFamily>[];
    final active = bundle?.activeCategoryIds ?? const <String>{};
    final starts = [
      for (final family in families)
        if (active.contains(family.categoryId)) _StartRow.of(family),
    ];
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final membership = widget.service.current;
    final trial = membership?.trialOffered ?? true;
    final copy = MembershipLockCopy.forState(
      membership?.state ?? MembershipState.trialAvailable,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Reveal(
                      animation: _segment(0),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PROGRAM READY', style: monoStyle()),
                            const SizedBox(height: 8),
                            const Text(
                              'Your map is set.',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.9,
                                height: 1.04,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Lead(
                              trees: starts.length,
                              daysPerWeek: widget.daysPerWeek,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (families.isNotEmpty)
                      _Reveal(
                        animation: _segment(1),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                              child: SkillWheel(
                                families: families,
                                controller: _wheelController,
                                activeCategoryIds: active,
                                lockedCategoryIds:
                                    bundle?.treeLocks.keys.toSet() ?? const {},
                                onChanged: _onWheelChanged,
                              ),
                            ),
                            const _Legend(),
                          ],
                        ),
                      ),
                    if (starts.isNotEmpty)
                      _Reveal(
                        animation: _segment(2),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TypeSectionLabel(
                                'Where you start',
                                right: 'Next unlock',
                                top: 22,
                              ),
                              for (var i = 0; i < starts.length; i++)
                                _StartRowTile(
                                  row: starts[i],
                                  last: i == starts.length - 1,
                                  onTap: () => _openExercise(starts[i]),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _Reveal(
              animation: _segment(3),
              child: Container(
                padding: EdgeInsets.fromLTRB(22, 12, 22, 6 + bottomInset),
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PillButton(
                      label: trial
                          ? MembershipLockCopy.trialCta(_plans)
                          : copy.cta(_plans),
                      radius: 14,
                      onTap: _startTrial,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      trial
                          ? MembershipLockCopy.trialTerms(_plans)
                          : copy.sub(_plans),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Pressable(
                      onTap: _notNow,
                      semanticLabel: 'Not now',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          'Not now',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExercise(_StartRow row) {
    final exercise = ExerciseCatalog.findById(row.start.exerciseId);
    if (exercise == null) return;
    AnalyticsService.capture('skill_tree_exercise_opened', properties: {
      'exercise_id': row.start.exerciseId,
      'node_state': row.start.state.name,
      if (exercise.skillCategoryId.isNotEmpty)
        'skill_tree_id': exercise.skillCategoryId,
      'source': 'program_ready',
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
}

/// The full read-only wheel, opened over the ready screen and flown into
/// the tapped tree. Its own back arrow returns to the ready screen.
class _ProgramReadyWheelScreen extends StatelessWidget {
  final SkillWheelBundle bundle;
  final String initialCategoryId;

  const _ProgramReadyWheelScreen({
    required this.bundle,
    required this.initialCategoryId,
  });

  void _openExercise(BuildContext context, WheelNode node) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    if (exercise == null) return;
    AnalyticsService.capture('skill_tree_exercise_opened', properties: {
      'exercise_id': node.exerciseId,
      'node_state': node.state.name,
      if (exercise.skillCategoryId.isNotEmpty)
        'skill_tree_id': exercise.skillCategoryId,
      'source': 'program_ready',
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SkillWheelScreen(
          families: bundle.families,
          journeyByCategory: bundle.journeyByCategory,
          activeCategoryIds: bundle.activeCategoryIds,
          treeLocks: bundle.treeLocks,
          initialCategoryId: initialCategoryId,
          onBack: () => Navigator.of(context).pop(),
          onOpenExercise: (node) => _openExercise(context, node),
        ),
      ),
    );
  }
}

/// "6 skill trees, 3 days a week. Blue is where you start — Forma moves you
/// outward every time you clear a node."
class _Lead extends StatelessWidget {
  final int trees;
  final int daysPerWeek;

  const _Lead({required this.trees, required this.daysPerWeek});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      color: AppColors.textSecondary,
      height: 1.4,
    );
    const bold = TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (trees > 0) ...[
            TextSpan(
              text: '$trees skill ${trees == 1 ? 'tree' : 'trees'}',
              style: bold,
            ),
            TextSpan(
              text: ', $daysPerWeek ${daysPerWeek == 1 ? 'day' : 'days'} a '
                  'week. ',
            ),
          ] else
            TextSpan(
              text: '$daysPerWeek ${daysPerWeek == 1 ? 'day' : 'days'} a '
                  'week. ',
            ),
          const TextSpan(
            text: 'Blue is where you start — Forma moves you outward every '
                'time you clear a node.',
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label, {Color? border}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: border == null ? null : Border.all(color: border),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: monoStyle(size: 10.5, letterSpacing: 1.1)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 6,
        children: [
          item(AppColors.accentPrimary, 'STARTING NOW'),
          item(AppColors.textPrimary.withValues(alpha: 0.85), 'UP NEXT'),
          item(AppColors.surface, 'LOCKED', border: AppColors.surface3),
        ],
      ),
    );
  }
}

/// One running tree: the step it starts on and the one after it.
class _StartRow {
  final String treeTitle;
  final WheelNode start;
  final WheelNode? next;

  const _StartRow({
    required this.treeTitle,
    required this.start,
    required this.next,
  });

  static _StartRow of(WheelFamily family) {
    final flat = family.flat;
    final index = family.activeFlatIndex;
    return _StartRow(
      treeTitle: family.title,
      start: flat[index],
      next: index + 1 < flat.length ? flat[index + 1] : null,
    );
  }
}

class _StartRowTile extends StatelessWidget {
  final _StartRow row;
  final bool last;
  final VoidCallback onTap;

  const _StartRowTile({
    required this.row,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final next = row.next;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.treeTitle.toUpperCase(),
                    style: monoStyle(
                      size: 10.5,
                      color: AppColors.accentPrimary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    row.start.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.16,
                    ),
                  ),
                ],
              ),
            ),
            if (next != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('THEN', style: monoStyle(size: 10, letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(
                    next.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fade + 16px upward slide.
class _Reveal extends AnimatedWidget {
  final Widget child;

  const _Reveal({required Animation<double> animation, required this.child})
      : super(listenable: animation);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _animation.value;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - t)),
        child: child,
      ),
    );
  }
}
