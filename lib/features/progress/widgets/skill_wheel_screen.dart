import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../home/home_dashboard_metrics.dart';
import 'skill_wheel.dart';
import 'skill_wheel_panels.dart';

/// The whole Progress-tab wheel screen: header, the radial wheel, and the
/// panel below it — MY PERFORMANCE on the overview (draggable up to cover
/// the wheel), the focused exercise card otherwise.
///
/// Opened from the Program tab it also manages progressions: [editable]
/// adds the STOP TRAINING pill on an active tree and the "Train this
/// exercise" CTA under the focused node's card.
class SkillWheelScreen extends StatefulWidget {
  final List<WheelFamily> families;
  final Map<String, JourneySkillProgressData> journeyByCategory;
  final void Function(WheelNode node) onOpenExercise;

  /// Categories with a progression running — their sectors carry the blue
  /// rim arc on the wheel.
  final Set<String> activeCategoryIds;

  /// Whether this screen can change progressions (Program-tab entry). The
  /// Progress tab keeps the wheel read-only.
  final bool editable;

  /// Makes the focused node the trained exercise of its tree — starting the
  /// tree's progression when it isn't running. Required when [editable].
  final Future<void> Function(WheelFamily family, WheelNode node)? onTrainNode;

  /// Stops the focused tree's progression. Required when [editable].
  final Future<void> Function(WheelFamily family)? onStopTraining;

  /// Back affordance on the overview header (the wheel view itself), for
  /// hosts that push this screen as its own route.
  final VoidCallback? onBack;

  /// Fly into this category's tree on first build.
  final String? initialCategoryId;

  const SkillWheelScreen({
    super.key,
    required this.families,
    this.journeyByCategory = const {},
    required this.onOpenExercise,
    this.activeCategoryIds = const {},
    this.editable = false,
    this.onTrainNode,
    this.onStopTraining,
    this.onBack,
    this.initialCategoryId,
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

  @override
  void didUpdateWidget(covariant SkillWheelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sel != null && _sel! >= widget.families.length) {
      _sel = null;
      _focus = 0;
    }
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

  @override
  Widget build(BuildContext context) {
    final family = _sel == null ? null : widget.families[_sel!];
    final bottomInset = MediaQuery.of(context).padding.bottom + 78;
    final familyActive = family != null &&
        widget.activeCategoryIds.contains(family.categoryId);

    // The editable footer under the focused card: caption + CTA for a node
    // that can become the trained exercise.
    Widget? footer;
    if (widget.editable && family != null) {
      final flat = family.flat;
      final node = flat[_focus.clamp(0, flat.length - 1)];
      if (node.state != WheelNodeState.active) {
        footer = _TrainFooter(
          caption: familyActive
              ? 'This will replace your current '
                  '${family.title} exercise.'
              : 'This starts the ${family.title} progression — the exercise '
                  'joins your workouts.',
          label: familyActive ? 'Train this exercise' : 'Start here',
          busy: _acting,
          onTap: () => _act(() => widget.onTrainNode!(family, node)),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Where the performance sheet rests: just under the wheel band. The
        // header height mirrors the compact header row below; the band
        // height is the wheel's overview framing scaled to width.
        const headerHeight = 51.0;
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
                  padding:
                      EdgeInsets.fromLTRB(22, 10, 22, _sel == null ? 6 : 18),
                  child: SizedBox(
                    height: 35,
                    child: Row(
                      children: [
                        if (_sel != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _wheelController.back,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 22,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else if (widget.onBack != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onBack,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 22,
                                color: AppColors.textSecondary,
                              ),
                            ),
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
                        if (widget.editable && familyActive) ...[
                          const SizedBox(width: 10),
                          _StopTrainingPill(
                            onTap: _acting
                                ? null
                                : () => _act(
                                      () => widget.onStopTraining!(family),
                                    ),
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
                    onChanged: (sel, focus) => setState(() {
                      _sel = sel;
                      _focus = focus;
                    }),
                  ),
                ),
                Expanded(
                  child: family == null
                      ? (widget.editable
                          ? _ProgressionsPanel(
                              families: widget.families,
                              activeCategoryIds: widget.activeCategoryIds,
                              bottomInset: bottomInset,
                              onOpenFamily: (index) => _wheelController.goTo(
                                index,
                                widget.families[index].activeFlatIndex,
                              ),
                            )
                          : const SizedBox.shrink())
                      : DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: WheelExerciseCard(
                            family: family,
                            focus: _focus,
                            journey:
                                widget.journeyByCategory[family.categoryId],
                            // The CTA bar floats over the list's tail, so
                            // the list needs the extra room to scroll clear
                            // of it.
                            bottomInset:
                                bottomInset + (footer == null ? 0 : 96),
                            onOpenExercise: widget.onOpenExercise,
                            onPickStep: (flatIndex) =>
                                _wheelController.goTo(_sel!, flatIndex),
                            onDismiss: _wheelController.back,
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
                    if (_edgeDragDx > 50) _wheelController.back();
                  },
                ),
              ),
            if (footer != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: footer,
              ),
            // MY PERFORMANCE rides in a sheet: resting just under the wheel,
            // draggable up to snap over it at the top of the page, and back
            // down to the resting view.
            if (family == null && !widget.editable)
              DraggableScrollableSheet(
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
                    controller: scrollController,
                    bottomInset: bottomInset,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The overview panel of the editable wheel: every progression running in
/// the program, one row each — current exercise, its tree, and a tap that
/// flies into the tree.
class _ProgressionsPanel extends StatelessWidget {
  final List<WheelFamily> families;
  final Set<String> activeCategoryIds;
  final double bottomInset;
  final void Function(int familyIndex) onOpenFamily;

  const _ProgressionsPanel({
    required this.families,
    required this.activeCategoryIds,
    required this.bottomInset,
    required this.onOpenFamily,
  });

  @override
  Widget build(BuildContext context) {
    final running = <(int, WheelFamily)>[
      for (var i = 0; i < families.length; i++)
        if (activeCategoryIds.contains(families[i].categoryId))
          (i, families[i]),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(22, 14, 22, bottomInset),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'YOUR PROGRESSIONS',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: const Color(0xFF8A8B93),
                  ),
                ),
              ),
              Text(
                '${running.length} RUNNING',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF4A4B52),
                ),
              ),
            ],
          ),
          if (running.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No progression is running yet. Tap a tree, pick an '
                'exercise, and start there — your workouts follow.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final (index, family) in running)
              Pressable(
                onTap: () => onOpenFamily(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentBright,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          family.flat[family.activeFlatIndex].name,
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
                        family.title.toUpperCase(),
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textMuted,
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

/// The mono red pill that stops the focused tree's progression.
class _StopTrainingPill extends StatelessWidget {
  final VoidCallback? onTap;

  const _StopTrainingPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.red.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          'STOP TRAINING',
          style: GoogleFonts.robotoMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}

/// Caption + CTA fixed to the bottom edge while a non-active node is
/// focused: what the tap will do, then the button that does it.
class _TrainFooter extends StatelessWidget {
  final String caption;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _TrainFooter({
    required this.caption,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 14;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: busy ? 'Saving…' : label,
            onTap: busy ? null : onTap,
          ),
        ],
      ),
    );
  }
}
