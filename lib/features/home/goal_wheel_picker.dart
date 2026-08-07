import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../progress/skill_wheel_data.dart';
import '../progress/widgets/skill_wheel.dart';

/// One goal option placed on the wheel: the option itself, the tip it marks,
/// and the family that tip belongs to.
class _PlacedGoal {
  final String id;
  final String label;
  final String tipKey;
  final int familyIndex;

  const _PlacedGoal({
    required this.id,
    required this.label,
    required this.tipKey,
    required this.familyIndex,
  });
}

/// Program setup's goal step, drawn on the Progress tab's wheel: every tree
/// radiating from one hub, each branch ending in a skill you can aim at.
///
/// Tap a tree to fly in, then add a goal from the list or by tapping the
/// dashed marker on its tip — the route from the start of that tree lights
/// amber. Picks stay visible from the wheel as amber markers and collect in
/// the list below it.
///
/// The wheel is [SkillWheel] itself rather than a copy, in its picker mode,
/// so it keeps whatever the Progress tab's wheel learns.
class GoalWheelPicker extends StatefulWidget {
  /// Goal option ids currently picked — the wizard's own list.
  final List<String> picked;

  /// Goals still behind an unlock, id → the note naming what opens them.
  final Map<String, String> lockedNotes;

  /// The user's statuses from the strength step, so the trees show where
  /// they are starting from rather than a blank slate.
  final Map<String, ExerciseStatus> progressMap;

  final ValueChanged<String> onToggleSkill;

  /// Every goal the wizard offers, id and label, in its own order.
  final List<({String id, String label})> options;

  const GoalWheelPicker({
    super.key,
    required this.picked,
    required this.lockedNotes,
    required this.progressMap,
    required this.onToggleSkill,
    required this.options,
  });

  @override
  State<GoalWheelPicker> createState() => _GoalWheelPickerState();
}

class _GoalWheelPickerState extends State<GoalWheelPicker> {
  final _wheelController = SkillWheelController();

  late List<WheelFamily> _families;
  late List<_PlacedGoal> _goals;

  int? _sel;

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(covariant GoalWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressMap != widget.progressMap) _build();
  }

  void _build() {
    // No tracks yet — the program does not exist — so every tree shows its
    // default branch as the one being aimed at.
    _families = buildWheelFamilies(
      progressMap: widget.progressMap,
      skillTracks: const [],
    );
    _goals = [
      for (final option in widget.options)
        if (goalTipKey(option.id, _families) case final key?)
          _PlacedGoal(
            id: option.id,
            label: option.label,
            tipKey: key,
            familyIndex: _families.indexWhere(
              (f) => f.categoryId == key.split(':').first,
            ),
          ),
    ];
  }

  /// Goals a tip stands for. Usually one; the pushups planche branch trains
  /// two (the push-up and the hold), and both live on it.
  List<_PlacedGoal> _goalsAt(String tipKey) =>
      [for (final goal in _goals) if (goal.tipKey == tipKey) goal];

  bool _isLocked(_PlacedGoal goal) => widget.lockedNotes.containsKey(goal.id);

  /// Tips worth a marker: those standing for a goal that can still be picked.
  Set<String> get _pickableTips => {
        for (final goal in _goals)
          if (!_isLocked(goal)) goal.tipKey,
      };

  Set<String> get _pickedTips => {
        for (final goal in _goals)
          if (widget.picked.contains(goal.id)) goal.tipKey,
      };

  void _toggleTip(String tipKey) {
    final at = _goalsAt(tipKey).where((g) => !_isLocked(g)).toList();
    if (at.isEmpty) return;
    // A tip with one goal toggles it. A tip with several is ambiguous on the
    // canvas, so tapping it clears them when any are on and otherwise leaves
    // the choice to the list, where the goals are named apart.
    if (at.length == 1) {
      widget.onToggleSkill(at.first.id);
      return;
    }
    final on = at.where((g) => widget.picked.contains(g.id)).toList();
    if (on.isEmpty) return;
    for (final goal in on) {
      widget.onToggleSkill(goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_families.length < 2) return const SizedBox.shrink();
    final sel = _sel;
    final family = sel == null ? null : _families[sel];

    return LayoutBuilder(
      builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            height: 34,
            child: Row(
              children: [
                if (sel != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _wheelController.back,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    family?.title ?? 'Pick your goals',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.picked.isNotEmpty)
                  Text(
                    '${widget.picked.length} SELECTED',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.26,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The wheel keeps its natural height where there is room and shrinks
        // to fit where there is not, so the list below always has a share.
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.55),
          child: SkillWheel(
            families: _families,
            controller: _wheelController,
            pickedGoals: _pickedTips,
            pickableGoals: _pickableTips,
            onToggleGoal: _toggleTip,
            onChanged: (selected, _) => setState(() => _sel = selected),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: sel == null ? _pickedPanel() : _familyPanel(sel),
          ),
        ),
        ],
      ),
    );
  }

  /// The wheel's panel: what has been picked so far, each removable.
  Widget _pickedPanel() {
    final picked = [
      for (final goal in _goals)
        if (widget.picked.contains(goal.id)) goal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(
            'YOUR GOALS',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.amber,
            ),
          ),
        ),
        Expanded(
          child: picked.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    'Tap a tree to see what it can unlock, then add the '
                    'skills you want this program to build toward. Nothing '
                    'calling to you yet? Skip — Forma builds a balanced '
                    'program either way.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: picked.length,
                  itemBuilder: (context, index) {
                    final goal = picked[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goal.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _familyTitle(goal).toUpperCase(),
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.08,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onToggleSkill(goal.id),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _familyTitle(_PlacedGoal goal) =>
      goal.familyIndex < 0 ? '' : _families[goal.familyIndex].title;

  /// A focused tree's panel: every goal it can lead to, and how far off it is.
  Widget _familyPanel(int sel) {
    final family = _families[sel];
    final goals = [
      for (final goal in _goals)
        if (goal.familyIndex == sel) goal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(
            'GOALS IN ${family.title.toUpperCase()}',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.amber,
            ),
          ),
        ),
        Expanded(
          child: goals.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    'This tree has no goal to aim at yet — Forma trains it to '
                    'keep you balanced whichever goals you pick.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: goals.length,
                  itemBuilder: (context, index) =>
                      _goalRow(goals[index], family),
                ),
        ),
      ],
    );
  }

  Widget _goalRow(_PlacedGoal goal, WheelFamily family) {
    final on = widget.picked.contains(goal.id);
    final lockedNote = widget.lockedNotes[goal.id];
    final locked = lockedNote != null;
    final away = _stepsAway(goal, family);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: locked ? null : () => widget.onToggleSkill(goal.id),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: on ? AppColors.amber : Colors.transparent,
                  shape: BoxShape.circle,
                  border: on
                      ? null
                      : Border.all(
                          color: locked
                              ? AppColors.textMuted
                              : AppColors.amber.withValues(alpha: 0.55),
                          width: 1.4,
                        ),
                ),
                child: on
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                        color: on
                            ? AppColors.textPrimary
                            : const Color(0xFFD5D6DB),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      locked
                          ? lockedNote.toUpperCase()
                          : '$away STEP${away == 1 ? '' : 'S'} AWAY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.08,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (locked)
                const Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                )
              else
                Text(
                  on ? 'ADDED' : '+ ADD',
                  style: GoogleFonts.robotoMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.17,
                    color: on ? AppColors.amber : const Color(0xFF4A4B52),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Steps still to clear on the route to a goal: the trunk plus the branch
  /// it ends, minus whatever the strength step already put behind the user.
  int _stepsAway(_PlacedGoal goal, WheelFamily family) {
    final branchId = goal.tipKey.split(':').last;
    final steps = [
      ...family.trunk,
      if (branchId != '*')
        for (final branch in family.branches)
          if (branch.id == branchId) ...branch.steps,
    ];
    final left = steps.where((node) => !node.state.isCleared).length;
    return left == 0 ? steps.length : left;
  }
}
