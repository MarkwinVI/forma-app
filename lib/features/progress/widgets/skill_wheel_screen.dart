import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/tab_reset.dart';
import '../../../data/services/analytics_service.dart';
import '../performance_overview.dart';
import 'skill_tree_confirm.dart';
import 'skill_wheel.dart';
import 'skill_wheel_panels.dart';

/// The whole Progress-tab wheel screen: header, the radial wheel, and the
/// panel below it — MY PERFORMANCE on the overview (draggable up to cover
/// the wheel), the focused tree's step list otherwise, where the focused
/// step opens in place.
///
/// Editing is a mode of the same screen, not another page: the header's
/// Edit pill turns into Done, the overview's panel becomes the list of
/// progressions, and a focused tree's open row gains the one action that
/// applies to its step. The Program tab opens the screen already in that
/// mode, and its Done leaves the screen.
class SkillWheelScreen extends StatefulWidget {
  final List<WheelFamily> families;

  /// The open row's meter numbers, by exercise id. A step without an entry
  /// shows its status alone.
  final Map<String, WheelStepStats> stepStats;
  final void Function(WheelNode node) onOpenExercise;

  /// Categories with a progression running — their curved names read blue
  /// on the wheel.
  final Set<String> activeCategoryIds;

  /// Trees behind an unmet prerequisite, with what unlocks them. They carry
  /// a padlock on the wheel and a lock note while focused.
  final Map<String, WheelTreeLock> treeLocks;

  /// MY PERFORMANCE data for the sheet under the wheel. The sheet only
  /// mounts when this is set (Progress tab), and slides away in edit mode.
  final PerformanceOverview? performance;

  /// Whether this screen can change progressions: the header carries the
  /// Edit pill, and edit mode is reachable. Off, the wheel is a plain view.
  final bool editable;

  /// Open in edit mode — the Program tab's entry, where editing is the
  /// whole point of the visit.
  final bool startEditing;

  /// Whether the screen is on the tab the user is looking at. Leaving the
  /// tab ends edit mode: the wheel is met as a view on the way back, never
  /// as an edit left half-done.
  final bool isActive;

  /// What Done does for a host that pushed this screen as a route: leave
  /// it. Without this, Done just ends edit mode in place.
  final VoidCallback? onDone;

  /// Makes the focused node the trained exercise of its tree — starting the
  /// tree's progression when it isn't running. Required when [editable].
  final Future<void> Function(WheelFamily family, WheelNode node)? onTrainNode;

  /// Stops the focused tree's progression. Required when [editable].
  final Future<void> Function(WheelFamily family)? onStopTraining;

  /// Back affordance on the overview header (the wheel view itself), for
  /// hosts that push this screen as its own route.
  final VoidCallback? onBack;

  /// Where the screen is shown, for analytics: the Progress tab, or the
  /// Program tab and the surfaces that open the wheel from it.
  final String source;

  /// Fly into this category's tree on first build.
  final String? initialCategoryId;

  /// Backing out of a focused tree normally pulls out to the wheel overview.
  /// Hosts that open straight into one tree (a workout's Edit progression)
  /// set this so back leaves the screen entirely via [onBack] instead — the
  /// wheel overview would be a detour on the way back to where they came
  /// from.
  final bool exitOnTreeBack;

  const SkillWheelScreen({
    super.key,
    required this.families,
    this.stepStats = const {},
    required this.onOpenExercise,
    this.activeCategoryIds = const {},
    this.treeLocks = const {},
    this.performance,
    this.editable = false,
    this.startEditing = false,
    this.isActive = true,
    this.onDone,
    this.onTrainNode,
    this.onStopTraining,
    this.onBack,
    this.source = 'progress_tab',
    this.initialCategoryId,
    this.exitOnTreeBack = false,
  });

  @override
  State<SkillWheelScreen> createState() => _SkillWheelScreenState();
}

class _SkillWheelScreenState extends State<SkillWheelScreen> {
  final _wheelController = SkillWheelController();

  int? _sel;
  int _focus = 0;
  double _edgeDragDx = 0;
  bool _acting = false;

  /// Edit mode — on from the first frame for hosts that open into it.
  late bool _editing = widget.editable && widget.startEditing;

  /// Whether the focused step's row is open. A tap on the open row closes
  /// it; the selector landing on a step opens that one.
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initialCategoryId;
    if (initialId != null) {
      final index = widget.families
          .indexWhere((family) => family.categoryId == initialId);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _wheelController.goTo(
            index,
            widget.families[index].activeFlatIndex,
          );
        });
      }
    }
  }

  /// The shell's re-tap signal for the tab this screen is the index page
  /// of. A focused tree counts as "deeper" even though it is not a route,
  /// so a re-tap pulls out to the wheel overview instead of scrolling.
  TabResetNotifier? _tabReset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabReset = TabReset.maybeOf(context);
    if (tabReset == _tabReset) return;
    _tabReset?.removeListener(_onTabReset);
    _tabReset = tabReset?..addListener(_onTabReset);
  }

  @override
  void dispose() {
    _tabReset?.removeListener(_onTabReset);
    super.dispose();
  }

  /// The re-tap unwinds one layer at a time: a focused tree pulls out to
  /// the overview, and the overview in edit mode ends the edit.
  void _onTabReset() {
    if (_sel != null) {
      _tabReset?.markHandled();
      _treeBack();
    } else if (_editing) {
      _tabReset?.markHandled();
      _finishEditing();
    }
  }

  /// Edit: the same screen, in edit mode — the pill becomes Done, the
  /// panels swap. From a focused tree it edits that tree, right there.
  void _startEditing() {
    if (_editing) return;
    final family = _sel == null ? null : widget.families[_sel!];
    AnalyticsService.capture('skill_trees_edit_opened', properties: {
      'source': widget.source,
      if (family != null) 'skill_tree_id': family.categoryId,
    });
    setState(() => _editing = true);
  }

  /// Done: leave edit mode where the user stands — a host that pushed the
  /// screen as a route leaves the screen instead.
  void _finishEditing() {
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
      return;
    }
    setState(() => _editing = false);
  }

  @override
  void didUpdateWidget(covariant SkillWheelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sel != null && _sel! >= widget.families.length) {
      _sel = null;
      _focus = 0;
    }
    // Switching tabs ends the edit; the focused tree, if any, stays.
    if (oldWidget.isActive && !widget.isActive) _editing = false;
  }

  /// What backing out of a focused tree does — pull out to the wheel, or
  /// leave the screen when the host opened straight into the tree.
  VoidCallback get _treeBack => widget.exitOnTreeBack && widget.onBack != null
      ? widget.onBack!
      : _wheelController.back;

  /// One event each time a tree comes into focus — the wheel overview is
  /// the tab's resting state, so a focused tree is what "explored" means.
  void _reportTreeOpened(int index) {
    if (index < 0 || index >= widget.families.length) return;
    final family = widget.families[index];
    AnalyticsService.capture('skill_tree_opened', properties: {
      'skill_tree_id': family.categoryId,
      'source': widget.source,
      'editing': _editing,
      'is_active': widget.activeCategoryIds.contains(family.categoryId),
      'is_locked': widget.treeLocks.containsKey(family.categoryId),
    });
    // Also a screen view: a focused tree is a page in its own right, it just
    // never goes through a route.
    AnalyticsService.screen('skill_tree_${family.categoryId}', properties: {
      'source': widget.source,
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  /// Nodes after [node] along every route through it — the rest of its own
  /// branch, or, for a trunk step, the rest of the trunk plus every branch
  /// (they all pass through it).
  List<WheelNode> _nodesAfter(WheelFamily family, WheelNode node) {
    final trunkIndex =
        family.trunk.indexWhere((step) => step.exerciseId == node.exerciseId);
    if (trunkIndex >= 0) {
      return [
        ...family.trunk.sublist(trunkIndex + 1),
        for (final branch in family.branches) ...branch.steps,
      ];
    }
    for (final branch in family.branches) {
      final index =
          branch.steps.indexWhere((step) => step.exerciseId == node.exerciseId);
      if (index >= 0) return branch.steps.sublist(index + 1);
    }
    return const [];
  }

  /// Whether picking [node] moves the progression backward — the node is
  /// already cleared, or something past it has been reached.
  bool _isBackward(WheelFamily family, WheelNode node) {
    if (node.state.isCleared) return true;
    return _nodesAfter(family, node).any(
      (step) => step.state.isCleared || step.state == WheelNodeState.active,
    );
  }

  /// Confirms stopping the tree's progression, then stops it.
  Future<void> _stopWithConfirm(WheelFamily family, WheelNode node) async {
    final confirmed = await showSkillTreeConfirm(
      context,
      icon: Icons.stop_circle_rounded,
      caution: false,
      title: 'Stop training ${node.name}?',
      body: [
        const TextSpan(text: 'This will remove '),
        skillTreeConfirmBold(node.name),
        const TextSpan(text: ' from your workouts and make '),
        skillTreeConfirmBold('${family.title} progression'),
        const TextSpan(text: ' inactive. Your progress stays saved.'),
      ],
      confirmLabel: 'Stop training',
    );
    if (!confirmed || !mounted) return;
    await _act(() => widget.onStopTraining!(family));
  }

  /// Asks the question that fits what picking [node] would do — start,
  /// switch, jump ahead, go back, or unlock a whole tree early — and only
  /// then makes it the trained exercise.
  Future<void> _trainWithConfirm(
    WheelFamily family,
    WheelNode node, {
    required bool familyActive,
    required WheelTreeLock? lock,
  }) async {
    final tree = '${family.title} progression';
    final current =
        familyActive ? family.flat[family.activeFlatIndex].name : null;

    final IconData icon;
    var caution = false;
    final String title;
    final String confirmLabel;
    final List<InlineSpan> body;

    if (lock != null) {
      // 7C — a node inside a tree whose prerequisite is not met.
      icon = Icons.lock_open_rounded;
      caution = true;
      title = 'Start ${node.name} early?';
      confirmLabel = 'Start anyway';
      body = [
        const TextSpan(text: "You haven't completed the prerequisite for "),
        skillTreeConfirmBold(tree),
        const TextSpan(
          text: " yet. Only start this progression if you feel confident "
              "you're ready for ",
        ),
        skillTreeConfirmBold(node.name),
        const TextSpan(text: '.\n\nThis will unlock '),
        skillTreeConfirmBold(tree),
        const TextSpan(text: ' early and add '),
        skillTreeConfirmBold(node.name),
        const TextSpan(text: ' to your workouts.'),
      ];
    } else if (node.state == WheelNodeState.locked) {
      // 7 — a step ahead of the current progression. The earlier steps stay
      // locked until this one is mastered, which then masters them too.
      icon = Icons.move_up;
      caution = true;
      title = 'Start ${node.name}?';
      confirmLabel = 'Start exercise';
      body = [
        const TextSpan(
          text: 'This exercise is ahead of your current progression. Only '
              'continue if you’re confident you can perform it with '
              'good form.\n\nOnce you master it, the earlier exercises in '
              'this path will also be marked as mastered.',
        ),
        if (familyActive) ...[
          const TextSpan(text: '\n\nThis will replace '),
          skillTreeConfirmBold(current!),
          const TextSpan(text: ' in your workouts.'),
        ],
      ];
    } else if (_isBackward(family, node)) {
      if (familyActive) {
        // 8A — an earlier step of a running tree: later steps re-lock.
        icon = Icons.undo_rounded;
        title = 'Go back to ${node.name}?';
        confirmLabel = 'Go back';
        body = [
          const TextSpan(text: 'This will replace '),
          skillTreeConfirmBold(current!),
          const TextSpan(text: ' in your workouts with '),
          skillTreeConfirmBold(node.name),
          const TextSpan(text: '. Exercises after '),
          skillTreeConfirmBold(node.name),
          const TextSpan(
            text: ' will be locked again until you progress through them.',
          ),
        ];
      } else {
        // 8B — a new, earlier starting point in an idle tree.
        icon = Icons.restart_alt_rounded;
        title = 'Start again from ${node.name}?';
        confirmLabel = 'Start exercise';
        body = [
          const TextSpan(text: 'This will add '),
          skillTreeConfirmBold(node.name),
          const TextSpan(text: ' to your workouts and activate '),
          skillTreeConfirmBold(tree),
          const TextSpan(text: '. Exercises after '),
          skillTreeConfirmBold(node.name),
          const TextSpan(
            text: ' will be locked again until you progress through them.',
          ),
        ];
      }
    } else if (familyActive) {
      // 6 — another reachable exercise at the same point: a plain swap.
      icon = Icons.swap_horiz_rounded;
      title = 'Switch to ${node.name}?';
      confirmLabel = 'Switch exercise';
      body = [
        const TextSpan(text: 'This will replace '),
        skillTreeConfirmBold(current!),
        const TextSpan(text: ' in your workouts with '),
        skillTreeConfirmBold(node.name),
        const TextSpan(text: '.'),
      ];
    } else {
      // 5 — start an idle tree at its available step.
      icon = Icons.play_arrow_rounded;
      title = 'Start training ${node.name}?';
      confirmLabel = 'Start training';
      body = [
        const TextSpan(text: 'This will add '),
        skillTreeConfirmBold(node.name),
        const TextSpan(text: ' to your workouts and activate '),
        skillTreeConfirmBold(tree),
        const TextSpan(
          text: ". Once you master it, you'll automatically progress to "
              'the next exercise.',
        ),
      ];
    }

    final confirmed = await showSkillTreeConfirm(
      context,
      icon: icon,
      caution: caution,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
    );
    if (!confirmed || !mounted) return;
    await _act(() => widget.onTrainNode!(family, node));
  }

  @override
  Widget build(BuildContext context) {
    final family = _sel == null ? null : widget.families[_sel!];
    final bottomInset = MediaQuery.of(context).padding.bottom + 78;
    final familyActive =
        family != null && widget.activeCategoryIds.contains(family.categoryId);
    final lock = family == null || familyActive
        ? null
        : widget.treeLocks[family.categoryId];

    // The focused step's row opens in place: the exercise's preview (thumb,
    // status, best-workout meter) in both modes, and in edit mode one
    // button under it. A node drawn as active is the current step of a
    // running tree (a paused tree's step reads as available), so the
    // node's state alone decides the verb: Stop training on it, Start
    // training on every other node. What the start means — switch, jump
    // ahead, go back, start a tree — is the confirm sheet's to say.
    Widget? detail;
    var detailHeight = 0.0;
    if (family != null && _expanded) {
      final flat = family.flat;
      final node = flat[_focus.clamp(0, flat.length - 1)];
      final isCurrent = node.state == WheelNodeState.active;
      Widget? action;
      if (_editing) {
        action = isCurrent
            ? _WheelCta(
                label: _acting ? 'Saving…' : 'Stop training',
                color: AppColors.red,
                onTap: _acting || widget.onStopTraining == null
                    ? null
                    : () => _stopWithConfirm(family, node),
              )
            : _WheelCta(
                label: _acting ? 'Saving…' : 'Start training',
                color: AppColors.accentPrimary,
                filled: true,
                onTap: _acting || widget.onTrainNode == null
                    ? null
                    : () => _trainWithConfirm(
                          family,
                          node,
                          familyActive: familyActive,
                          lock: lock,
                        ),
              );
      }
      detail = WheelStepDetail(
        node: node,
        stats: widget.stepStats[node.exerciseId],
        onOpen: () => widget.onOpenExercise(node),
        action: action,
      );
      detailHeight = WheelStepDetail.heightFor(withAction: action != null);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Where the performance sheet rests: just under the wheel band. The
        // header height mirrors the compact header row below; the band
        // height is the wheel's overview framing scaled to width.
        const headerHeight = 54.0;
        final bandHeight =
            SkillWheel.overviewBandHeight * constraints.maxWidth / 400;
        final minFraction =
            (1 - (headerHeight + bandHeight) / constraints.maxHeight)
                .clamp(0.15, 0.9);

        return Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact header: one row pinned at the very top, so the
                // wheel below gets the vertical room. The focused view takes
                // extra breathing room under the title.
                Padding(
                  // With a back arrow the row starts 12pt earlier: the
                  // arrow's 44pt box centres its glyph where the bare 22pt
                  // glyph used to sit, and the title keeps its old left edge.
                  padding: EdgeInsets.fromLTRB(
                    _sel != null || widget.onBack != null ? 10 : 22,
                    7,
                    22,
                    _sel == null ? 3 : 15,
                  ),
                  child: SizedBox(
                    // Tall enough for the 30px title's full line box — a
                    // shorter row makes the paragraph overflow its height
                    // constraint, which turns ellipsis clipping on and chops
                    // descenders (the g of "Hinge") flat — and for the
                    // 44pt hit areas of the icons beside it.
                    height: 44,
                    child: Row(
                      children: [
                        if (_sel != null)
                          _HeaderIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            semanticLabel: 'Back',
                            onTap: _treeBack,
                          )
                        else if (widget.onBack != null)
                          _HeaderIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            semanticLabel: 'Back',
                            onTap: widget.onBack,
                          ),
                        Expanded(
                          child: Text(
                            family?.title ?? 'Skill Trees',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.9,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.editable) ...[
                          const SizedBox(width: 12),
                          _EditPill(
                            editing: _editing,
                            onTap: _editing ? _finishEditing : _startEditing,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Natural height where there is room, shrunk to fit where
                // there is not — the panel below always keeps a share.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.62,
                  ),
                  child: SkillWheel(
                    families: widget.families,
                    controller: _wheelController,
                    activeCategoryIds: widget.activeCategoryIds,
                    lockedCategoryIds: widget.treeLocks.keys.toSet(),
                    onChanged: (sel, focus) => setState(() {
                      if (sel != null && sel != _sel) _reportTreeOpened(sel);
                      _sel = sel;
                      _focus = focus;
                      // The selector landing on a step opens its row.
                      _expanded = true;
                    }),
                  ),
                ),
                Expanded(
                  child: family == null
                      // Edit and Done cross-fade the overview's panel: the
                      // list of progressions in, the performance sheet
                      // (below, in the stack) sliding away.
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _editing
                              ? _ProgressionsPanel(
                                  key: const ValueKey('progressions'),
                                  families: widget.families,
                                  activeCategoryIds: widget.activeCategoryIds,
                                  lockedCategoryIds:
                                      widget.treeLocks.keys.toSet(),
                                  bottomInset: bottomInset,
                                  onOpenFamily: (index) =>
                                      _wheelController.goTo(
                                    index,
                                    widget.families[index].activeFlatIndex,
                                  ),
                                )
                              : widget.performance == null
                                  // Viewing with nothing else under the
                                  // wheel: the same guidance the editing
                                  // overview gives, in one line.
                                  ? _ReadOnlyOverviewNote(
                                      key: const ValueKey('note'),
                                      hasEdit: widget.editable,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('sheet-room'),
                                    ),
                        )
                      : DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // The lock note is pinned above the list — it
                              // must stay in view while the steps scroll
                              // under it.
                              if (lock != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(22, 12, 22, 0),
                                  child: _TreeLockBanner(lock: lock),
                                ),
                              Expanded(
                                child: WheelExerciseCard(
                                  family: family,
                                  focus: _focus,
                                  bottomInset: bottomInset,
                                  detail: detail,
                                  detailHeight: detailHeight,
                                  // Tapping the open row closes it (and a
                                  // closed one opens); tapping any other
                                  // row moves the selector there, which
                                  // opens that row.
                                  onPickStep: (flatIndex) {
                                    final focused = _focus.clamp(
                                      0,
                                      family.flat.length - 1,
                                    );
                                    if (flatIndex == focused) {
                                      setState(() => _expanded = !_expanded);
                                    } else {
                                      _wheelController.goTo(_sel!, flatIndex);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            // The system-style back swipe: a rightward drag starting at the
            // screen's left edge pulls out of the focused tree. Taps pass
            // through, so the back arrow underneath keeps working.
            if (family != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _edgeDragDx = 0,
                  onHorizontalDragUpdate: (d) => _edgeDragDx += d.delta.dx,
                  onHorizontalDragEnd: (_) {
                    if (_edgeDragDx > 50) _treeBack();
                  },
                ),
              ),
            // MY PERFORMANCE rides in a sheet: resting just under the wheel,
            // draggable up to snap over it at the top of the page, and back
            // down to the resting view. Edit slides it off the bottom and
            // Done brings it back; while it is away it takes no touches.
            if (family == null && widget.performance != null)
              IgnorePointer(
                ignoring: _editing,
                child: AnimatedSlide(
                  offset: _editing ? const Offset(0, 1) : Offset.zero,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: DraggableScrollableSheet(
                    initialChildSize: minFraction,
                    minChildSize: minFraction,
                    maxChildSize: 1.0,
                    snap: true,
                    builder: (context, scrollController) => DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: PerformancePanel(
                        overview: widget.performance!,
                        controller: scrollController,
                        bottomInset: bottomInset,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The open row's button, in the reference design's two styles: a soft
/// tinted pill whose tint carries the action — red = stop — or, [filled],
/// the solid blue button that commits a step.
class _WheelCta extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _WheelCta({
    required this.label,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // Disabled: the pill drains as well as the text, so the state reads at
    // a glance and not only by the label's colour.
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: filled
              ? color.withValues(alpha: enabled ? 1 : 0.3)
              : color.withValues(alpha: enabled ? 0.08 : 0.04),
          border: filled
              ? null
              : Border.all(
                  color: color.withValues(alpha: enabled ? 0.45 : 0.16),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
            color: filled
                ? Colors.white
                : enabled
                    ? color
                    : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// The header's mode pill: a soft gray Edit beside the title, which fills
/// blue and reads Done for as long as edit mode is on.
class _EditPill extends StatelessWidget {
  final bool editing;
  final VoidCallback onTap;

  const _EditPill({required this.editing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: editing ? 'Done editing' : 'Edit skill trees',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: editing
              ? AppColors.accentPrimary
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: editing
                ? AppColors.accentPrimary
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          editing ? 'Done' : 'Edit',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// A header icon with a full 44pt hit area around a 22–28pt glyph.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}

/// The amber note under the wheel while a locked tree is focused: what
/// unlocks it.
class _TreeLockBanner extends StatelessWidget {
  final WheelTreeLock lock;

  const _TreeLockBanner({required this.lock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.lock_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Locked tree. ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: 'Unlocks when you master '),
                  TextSpan(
                    text: lock.prereqExerciseName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' in the ${lock.prereqTreeTitle} tree.'),
                ],
              ),
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Under the read-only wheel when no performance sheet takes the space:
/// what the wheel is for and where a progression gets started.
class _ReadOnlyOverviewNote extends StatelessWidget {
  /// Whether the header carries the Edit pill — the note then points there
  /// rather than at the Program tab.
  final bool hasEdit;

  const _ReadOnlyOverviewNote({super.key, required this.hasEdit});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
        child: Text(
          hasEdit
              ? 'Tap a tree to see its steps. Edit starts or changes a '
                  'progression.'
              : 'Tap a tree to see its steps. Start or change a progression '
                  'from the Program tab.',
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// The overview panel of the editable wheel: every progression running in
/// the program, one row each — current exercise, its tree, and a tap that
/// flies into the tree.
class _ProgressionsPanel extends StatelessWidget {
  final List<WheelFamily> families;
  final Set<String> activeCategoryIds;
  final Set<String> lockedCategoryIds;
  final double bottomInset;
  final void Function(int familyIndex) onOpenFamily;

  const _ProgressionsPanel({
    super.key,
    required this.families,
    required this.activeCategoryIds,
    required this.lockedCategoryIds,
    required this.bottomInset,
    required this.onOpenFamily,
  });

  Widget _sectionLabel(String label, {bool first = false}) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 26),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.65,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _treeRow(
    int index,
    WheelFamily family, {
    required bool active,
    required bool last,
  }) {
    // The running marker is the wheel's blue dot; an inactive tree wears a
    // hollow ring instead, or the padlock while its prerequisite is unmet.
    final Widget marker;
    if (active) {
      marker = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.accentBright,
          shape: BoxShape.circle,
        ),
      );
    } else if (lockedCategoryIds.contains(family.categoryId)) {
      marker = const Icon(
        Icons.lock_rounded,
        size: 13,
        color: AppColors.textMuted,
      );
    } else {
      marker = Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.6,
          ),
        ),
      );
    }

    return Pressable(
      onTap: () => onOpenFamily(index),
      child: Container(
        padding: const EdgeInsets.only(top: 17, bottom: 19),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            SizedBox(width: 14, child: Center(child: marker)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                family.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                  color:
                      active ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final running = <(int, WheelFamily)>[];
    final idle = <(int, WheelFamily)>[];
    for (var i = 0; i < families.length; i++) {
      final family = families[i];
      (activeCategoryIds.contains(family.categoryId) ? running : idle)
          .add((i, family));
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(22, 14, 22, bottomInset),
        children: [
          _sectionLabel('ACTIVE SKILL TREES', first: true),
          if (running.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No progression is running yet. Tap a tree below, pick an '
                'exercise, and start there — your workouts follow.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final (i, (index, family)) in running.indexed)
              _treeRow(
                index,
                family,
                active: true,
                last: i == running.length - 1,
              ),
          if (idle.isNotEmpty) ...[
            _sectionLabel('INACTIVE SKILL TREES'),
            for (final (i, (index, family)) in idle.indexed)
              _treeRow(
                index,
                family,
                active: false,
                last: i == idle.length - 1,
              ),
          ],
        ],
      ),
    );
  }
}
