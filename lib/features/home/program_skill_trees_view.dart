import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/skill_tree_map.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/skill_track_model.dart';
import 'program_skill_track_impact.dart';

export 'program_skill_track_impact.dart'
    show
        SkillTrackChange,
        SkillTrackImpact,
        SkillTrackImpactProbe,
        SkillTrackUpdate;

/// The program's own view of the skill trees: which are training now, which
/// are not, and — unlike the Progress tab's read-only tree — the ability to
/// aim a tree at a goal branch or take it out of the program entirely.
class ProgramSkillTreesView extends StatefulWidget {
  final List<SkillTrack> tracks;
  final Map<String, ExerciseStatus> progressMap;
  final SkillTrackUpdate onUpdate;
  final SkillTrackImpactProbe describeImpact;

  const ProgramSkillTreesView({
    super.key,
    required this.tracks,
    required this.progressMap,
    required this.onUpdate,
    required this.describeImpact,
  });

  @override
  State<ProgramSkillTreesView> createState() => _ProgramSkillTreesViewState();
}

class _ProgramSkillTreesViewState extends State<ProgramSkillTreesView> {
  late List<SkillTrack> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = List.of(widget.tracks);
  }

  SkillTrack? _trackFor(String categoryId) {
    for (final track in _tracks) {
      if (track.skillCategoryId == categoryId) return track;
    }
    return null;
  }

  bool _isActive(SkillCategory category) =>
      _trackFor(category.id)?.included ?? false;

  Future<void> _apply({
    required String skillCategoryId,
    String? branchId,
    bool? included,
  }) async {
    final change = await widget.onUpdate(
      skillCategoryId: skillCategoryId,
      branchId: branchId,
      included: included,
    );
    if (change == null || !mounted) return;

    setState(() => _tracks = change.tracks);
    final message = change.message;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      for (final category in SkillCategoryCatalog.browsable())
        if (category.trainingPaths.isNotEmpty) category,
    ];
    final active = categories.where(_isActive).toList();
    final rest = categories.where((c) => !_isActive(c)).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TreesHeader(title: 'Skill trees'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 50),
                children: [
                  if (active.isNotEmpty) ...[
                    const _Kicker('Training now'),
                    for (final category in active) _row(category, true),
                  ],
                  if (rest.isNotEmpty) ...[
                    const _Kicker('Not active'),
                    for (final category in rest) _row(category, false),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(SkillCategory category, bool active) {
    final track = _trackFor(category.id);
    final locked = category.isLockedFor(widget.progressMap);

    return _TreeRow(
      name: category.title,
      detail: _detailFor(category, track, active, locked),
      detailColor: active
          ? (_goalBranch(category, track) != null
              ? AppColors.accentPrimary
              : AppColors.green)
          : AppColors.textSecondary,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _TreeDetailView(
            category: category,
            track: track,
            active: active,
            locked: locked,
            progressMap: widget.progressMap,
            onSetGoal: (branchId) => _apply(
              skillCategoryId: category.id,
              branchId: branchId,
            ),
            onSetActive: (included) => _apply(
              skillCategoryId: category.id,
              branchId: track?.branchId ?? category.defaultTrainingPathId,
              included: included,
            ),
            describeImpact: (include) =>
                widget.describeImpact(category.id, include),
          ),
        ),
      ),
    );
  }

  String _detailFor(
    SkillCategory category,
    SkillTrack? track,
    bool active,
    bool locked,
  ) {
    if (!active) {
      if (locked) {
        final name = ExerciseCatalog.findById(
          category.unlockRequirement!.exerciseId,
        );
        return 'Unlocks after ${name?.name ?? 'earlier work'}';
      }
      return 'Not in your program';
    }
    final goal = _goalBranch(category, track);
    if (goal != null) return '${goal.label} as goal';
    return currentStepName(category, track, widget.progressMap) ??
        'In your program';
  }

  /// The branch a track is aimed at, or null for trees that never fork.
  SkillCategoryBranch? _goalBranch(SkillCategory category, SkillTrack? track) {
    final branchId = track?.branchId;
    if (branchId == null) return null;
    final routes = goalBranchesOf(category);
    for (final branch in routes) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }
}

/// Branches a tree can be aimed at — the routes that actually fork away from
/// the shared foundation.
List<SkillCategoryBranch> goalBranchesOf(SkillCategory category) {
  final foundation = category.pathFor('main');
  return [
    for (final branch in category.branches)
      if (branch.id != 'main' &&
          category.pathFor(branch.id).length > foundation.length)
        branch,
  ];
}

/// The exercise a tree is currently sitting on, by the same rule the program
/// uses: the active step, else the first unmastered one.
String? currentStepName(
  SkillCategory category,
  SkillTrack? track,
  Map<String, ExerciseStatus> progressMap,
) {
  final path = category.pathFor(
    track?.branchId ?? category.defaultTrainingPathId,
  );
  for (final id in path) {
    if (progressMap[id] == ExerciseStatus.active) {
      return ExerciseCatalog.findById(id)?.name;
    }
  }
  for (final id in path) {
    if (progressMap[id] != ExerciseStatus.mastered) {
      return ExerciseCatalog.findById(id)?.name;
    }
  }
  return null;
}

/// One tree's page: the map with its goal route lit and tappable, the routes
/// as railed step lists, and the control that adds or removes it.
class _TreeDetailView extends StatefulWidget {
  final SkillCategory category;
  final SkillTrack? track;
  final bool active;
  final bool locked;
  final Map<String, ExerciseStatus> progressMap;
  final Future<void> Function(String branchId) onSetGoal;
  final Future<void> Function(bool included) onSetActive;
  final SkillTrackImpact? Function(bool include) describeImpact;

  const _TreeDetailView({
    required this.category,
    required this.track,
    required this.active,
    required this.locked,
    required this.progressMap,
    required this.onSetGoal,
    required this.onSetActive,
    required this.describeImpact,
  });

  @override
  State<_TreeDetailView> createState() => _TreeDetailViewState();
}

class _TreeDetailViewState extends State<_TreeDetailView> {
  /// One per route section, so picking a branch can scroll to it — the same
  /// move the Progress tab's tree makes.
  final _sectionKeys = <String, GlobalKey>{};

  late String? _goalId;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = widget.active;
    _goalId = widget.track?.branchId;
    // Every tree that forks carries a goal; one that has never been aimed
    // falls back to the catalogue's recommended route.
    if (_goalId == null && goalBranchesOf(widget.category).isNotEmpty) {
      _goalId = widget.category.defaultTrainingPathId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final branches = goalBranchesOf(category);
    final foundation = category.pathFor('main');
    final viz = TreeVizModel.fromCategory(
      category: category,
      progressMap: widget.progressMap,
      activeBranchId: _goalId ?? category.defaultTrainingPathId,
    );
    final goal = branches.where((b) => b.id == _goalId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TreesHeader(
              title: category.title,
              action: widget.locked
                  ? null
                  : _ActionPill(
                      label: _active ? 'Remove' : 'Add to active',
                      danger: _active,
                      onTap: _confirmActive,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SkillTreeMap(
                viz: viz,
                maxHeight: 210,
                selectedRouteId: _goalId,
                // Matches the tree map on the Progress tab, so branch names
                // read at the same size in both places.
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.14,
                ),
                onBranchTap:
                    branches.isEmpty ? null : (branch) => _pickGoal(branch.id),
                onFoundationTap: () => _scrollTo(_foundationKey),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Text(
                branches.isEmpty
                    ? 'This tree runs a single route — no goal to pick.'
                    : goal == null
                        ? 'Tap a branch to set it as your goal'
                        : 'Goal · ${goal.label} — tap another branch to switch',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ),
            Expanded(
              // Every route is built up front so picking a branch can scroll
              // to a section that is still below the fold.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      key: _keyFor(_foundationKey),
                      title: 'Foundation',
                      sub: 'Master to unlock more advanced exercises',
                    ),
                    _steps(foundation),
                    for (final branch in branches) ...[
                      _SectionTitle(
                        key: _keyFor(branch.id),
                        title: branch.label,
                        sub: branch.id == _goalId
                            ? 'Set as goal'
                            : 'Master the foundation to unlock',
                        subColor: branch.id == _goalId
                            ? AppColors.accentPrimary
                            : AppColors.textSecondary,
                      ),
                      _steps(
                        category.pathFor(branch.id).sublist(foundation.length),
                      ),
                    ],
                    _ActiveNote(active: _active, locked: widget.locked),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _steps(List<String> exerciseIds) {
    final states = skillTreeNodeStates(
      category: widget.category,
      progressMap: widget.progressMap,
      goalBranchId: _goalId,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (var i = 0; i < exerciseIds.length; i++)
            _StepRow(
              name: ExerciseCatalog.findById(exerciseIds[i])?.name ??
                  exerciseIds[i],
              state: states[exerciseIds[i]] ?? TreeNodeState.locked,
              last: i == exerciseIds.length - 1,
            ),
        ],
      ),
    );
  }

  static const _foundationKey = '__foundation__';

  GlobalKey _keyFor(String routeId) =>
      _sectionKeys.putIfAbsent(routeId, GlobalKey.new);

  void _scrollTo(String routeId) {
    final context = _sectionKeys[routeId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickGoal(String branchId) async {
    _scrollTo(branchId);
    if (branchId == _goalId) return;
    setState(() => _goalId = branchId);
    await widget.onSetGoal(branchId);
  }

  Future<void> _confirmActive() async {
    if (widget.locked) return;
    final next = !_active;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _ConfirmActiveSheet(
        treeName: widget.category.title,
        removing: _active,
        impact: widget.describeImpact(next),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _active = next);
    await widget.onSetActive(next);
  }
}

// ── Pieces ──────────────────────────────────────────────────

class _TreesHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _TreesHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pressable(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12, bottom: 4),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 26,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.19,
              height: 1.02,
            ),
          ),
        ],
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  final String label;

  const _Kicker(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 2.2,
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  final String name;
  final String detail;
  final Color detailColor;
  final VoidCallback onTap;

  const _TreeRow({
    required this.name,
    required this.detail,
    required this.detailColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 20, bottom: 22),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.55,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: detailColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String sub;
  final Color subColor;

  const _SectionTitle({
    super.key,
    required this.title,
    required this.sub,
    this.subColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.63,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(fontSize: 14.5, color: subColor, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String name;
  final TreeNodeState state;
  final bool last;

  const _StepRow({
    required this.name,
    required this.state,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      TreeNodeState.done => ('Mastered', AppColors.green),
      TreeNodeState.cur => ('Active', AppColors.accentPrimary),
      TreeNodeState.unlocked => ('Unlocked', AppColors.accentPrimary),
      TreeNodeState.locked => ('Locked', AppColors.textMuted),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 12, child: _Rail(state: state, last: last)),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: state == TreeNodeState.locked
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.robotoMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final TreeNodeState state;
  final bool last;

  const _Rail({required this.state, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 22, width: 1.5, color: AppColors.divider),
        switch (state) {
          TreeNodeState.done => Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
          TreeNodeState.cur => Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.25),
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          TreeNodeState.unlocked => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentPrimary, width: 2),
              ),
            ),
          TreeNodeState.locked => Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.surface3,
                shape: BoxShape.circle,
              ),
            ),
        },
        if (!last)
          Expanded(
            child: Container(
              width: 1.5,
              constraints: const BoxConstraints(minHeight: 12),
              color: state == TreeNodeState.done
                  ? AppColors.green.withValues(alpha: 0.4)
                  : AppColors.divider,
            ),
          ),
      ],
    );
  }
}

class _ActiveNote extends StatelessWidget {
  final bool active;
  final bool locked;

  const _ActiveNote({required this.active, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Text(
        locked
            ? 'Finish the tree this one grows out of before adding it.'
            : active
                ? 'Removing pauses the tree — cleared steps are kept and its '
                    'slot in your sessions frees up.'
                : 'Adding puts its next step into your sessions from the next '
                    'training day.',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          height: 1.55,
        ),
      ),
    );
  }
}

/// Outlined pill in the header — the one control that changes membership.
class _ActionPill extends StatelessWidget {
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.danger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _dangerRed : AppColors.accentPrimary;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.22,
          ),
        ),
      ),
    );
  }
}

const _dangerRed = Color(0xFFFF6B57);

/// Spells out what joining or leaving the program does — which sessions
/// change, and where it leaves the weekly balance — before committing.
class _ConfirmActiveSheet extends StatelessWidget {
  final String treeName;
  final bool removing;
  final SkillTrackImpact? impact;

  const _ConfirmActiveSheet({
    required this.treeName,
    required this.removing,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    final color = removing ? _dangerRed : AppColors.accentPrimary;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.cardHighlight)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        MediaQuery.of(context).padding.bottom + 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            removing
                ? 'Remove $treeName from your program?'
                : 'Add $treeName to your program?',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.7,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          ..._lines(color),
          const SizedBox(height: 26),
          PillButton(
            label: removing ? 'Remove $treeName' : 'Add $treeName',
            color: color,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          PillButton(
            label: 'Cancel',
            tonal: true,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  List<Widget> _lines(Color color) {
    final impact = this.impact;
    if (impact == null) {
      return [
        Text(
          removing
              ? 'The $treeName progression will be removed from your workouts '
                  'from the next training day. Your progress will stay saved.'
              : 'The $treeName progression will be added to your workouts '
                  'from the next training day.',
          style: _body,
        ),
      ];
    }

    final copy = skillTrackImpactCopy(
      impact: impact,
      treeName: treeName,
      removing: removing,
    );

    return [
      Text(copy.change, style: _body),
      const SizedBox(height: 14),
      Text(copy.balance, style: _body),
    ];
  }

  static const _body = TextStyle(
    fontSize: 14.5,
    color: AppColors.textSecondary,
    height: 1.55,
  );
}
