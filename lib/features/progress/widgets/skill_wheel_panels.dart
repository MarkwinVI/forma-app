import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/catalog/exercise_coaching_catalog.dart';
import '../../home/home_dashboard_metrics.dart';
import '../performance_overview.dart';
import 'skill_wheel.dart';

// ── MY PERFORMANCE ────────────────────────────────────────────────────

/// Look of one trend section: label, tint, and the trailing trend icon
/// (none for NEW — there is nothing to compare yet).
class _PerfGroupStyle {
  final String label;
  final Color color;
  final IconData? icon;

  const _PerfGroupStyle(this.label, this.color, this.icon);
}

const _perfGroupStyles = {
  PerformanceTrend.improving: _PerfGroupStyle(
    'IMPROVING',
    AppColors.green,
    Icons.trending_up_rounded,
  ),
  PerformanceTrend.noChange: _PerfGroupStyle(
    'NO CHANGE',
    AppColors.textSecondary,
    Icons.trending_flat_rounded,
  ),
  PerformanceTrend.needsAttention: _PerfGroupStyle(
    'NEEDS ATTENTION',
    AppColors.amber,
    Icons.trending_down_rounded,
  ),
  PerformanceTrend.fresh: _PerfGroupStyle(
    'NEW',
    AppColors.accentBright,
    null,
  ),
};

/// The wheel-overview panel: every exercise in the workout lists, grouped by
/// how its best set moved — the last 14 days against the 14 before.
/// Lives in a draggable sheet — [controller] is the sheet's scroll
/// controller, so dragging the panel raises the sheet over the wheel.
class PerformancePanel extends StatelessWidget {
  final PerformanceOverview overview;
  final double bottomInset;
  final ScrollController? controller;

  const PerformancePanel({
    super.key,
    required this.overview,
    required this.bottomInset,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(22, 8, 22, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller != null)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          const Text(
            'MY PERFORMANCE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            overview.comparesRecentSessions
                ? 'LATEST SESSION VS PREV. SESSIONS'
                : 'LAST 14 DAYS VS PREV. 14 DAYS',
            style: GoogleFonts.robotoMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          if (!overview.hasComparisons) ...[
            const SizedBox(height: 14),
            const Text(
              'Once you\'ve trained a bit, you\'ll start seeing how '
              'you\'re progressing in each exercise.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          for (final trend in PerformanceTrend.values)
            ..._group(trend, overview.rowsFor(trend)),
        ],
      ),
    );
  }

  List<Widget> _group(PerformanceTrend trend, List<PerformanceRowData> rows) {
    if (rows.isEmpty) return const [];
    final style = _perfGroupStyles[trend]!;
    return [
      const SizedBox(height: 20),
      Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            style.label,
            style: GoogleFonts.robotoMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
              color: style.color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      for (final row in rows)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  row.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Best set:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _bestLabel(row),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              // Fixed-width trailing box so the best-set values line up
              // across groups; NEW rows leave it blank.
              SizedBox(
                width: 52,
                child: row.delta == null || style.icon == null
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(style.icon, size: 15, color: style.color),
                          const SizedBox(width: 2),
                          Text(
                            _deltaLabel(row.delta!),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: style.color,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
    ];
  }

  static String _bestLabel(PerformanceRowData row) {
    if (row.bestValue <= 0) return '—';
    if (row.isTimed) return '${row.bestValue}s';
    return row.bestValue == 1 ? '1 rep' : '${row.bestValue} reps';
  }

  /// Signed delta, with the typographic minus the design reads best with.
  static String _deltaLabel(int delta) {
    if (delta > 0) return '+$delta';
    if (delta < 0) return '−${-delta}';
    return '0';
  }
}

// ── Focused exercise: shared status metadata ──────────────────────────

/// The lighter "training now" blue the reference design reads captions in.
const kWheelTrainingBlue = Color(0xFF7FA9F2);

// ── Bottom exercise preview ───────────────────────────────────────────

/// The panel that grows at the bottom while a node is selected: the
/// exercise's demo as a square thumbnail, its name and status, what it is,
/// and its progress bar. Tapping it opens the exercise's own page.
class WheelExercisePreview extends StatelessWidget {
  final WheelNode node;
  final JourneySkillProgressData? journey;
  final VoidCallback onOpen;

  const WheelExercisePreview({
    super.key,
    required this.node,
    required this.journey,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final state = node.state;
    final done = state.isCleared;

    final double barPct;
    final Color barColor;
    if (done) {
      barPct = 1;
      barColor = AppColors.green;
    } else if (state == WheelNodeState.active) {
      barPct = (journey?.progressPercent ?? 0).clamp(0.0, 1.0);
      barColor = AppColors.accentBright;
    } else {
      barPct = 0;
      barColor = AppColors.accentBright;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _thumb(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.28,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      height: 6,
                      color: Colors.white.withValues(alpha: 0.08),
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        widthFactor: barPct,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  _statusLine(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One status line under the bar — the design's single meta line, no
  /// separate state tag.
  Widget _statusLine() {
    final String text;
    final Color color;
    switch (node.state) {
      case WheelNodeState.mastered:
        text = 'Mastered';
        color = AppColors.green;
      case WheelNodeState.skipped:
        text = 'Skipped';
        color = AppColors.green;
      case WheelNodeState.active:
        final data = journey;
        if (data == null) {
          text = 'Training';
        } else {
          final unit = data.isTimed ? 'sec' : 'reps';
          text = 'Last ${data.lastSessionVolume} of '
              '${data.targetVolume} $unit (total)';
        }
        color = kWheelTrainingBlue;
      case WheelNodeState.available:
        text = 'Unlocked';
        color = AppColors.textSecondary;
      case WheelNodeState.locked:
        text = 'Locked';
        color = AppColors.textMuted;
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  /// The demo as a square thumbnail — the clip's poster frame when there is
  /// footage, the exercise's still otherwise, a play badge always.
  Widget _thumb() {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    final coaching =
        exercise == null ? null : ExerciseCoachingCatalog.forExercise(exercise);
    final videoId = coaching?.videoId;
    final imageUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : ((coaching?.imageUrl.isNotEmpty ?? false)
            ? coaching!.imageUrl
            : exercise?.imageUrl);

    const badge = Center(child: _PlayBadge(size: 38, iconSize: 18));

    return Container(
      width: 88,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: imageUrl == null
          ? badge
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                badge,
              ],
            ),
    );
  }
}

// ── Focused tree: the step list ───────────────────────────────────────

/// The whole tree as a scrollable list grouped by branch. Tapping a row
/// moves the selector; moving the selector (swipe or node tap) scrolls the
/// list to the step it landed on. The selected step's detail lives in the
/// bottom preview panel, not here.
class WheelExerciseCard extends StatefulWidget {
  final WheelFamily family;
  final int focus;
  final double bottomInset;
  final void Function(int flatIndex) onPickStep;

  /// Called when the list is pulled down past its top — the gesture that
  /// dismisses the tree back to the wheel.
  final VoidCallback? onDismiss;

  const WheelExerciseCard({
    super.key,
    required this.family,
    required this.focus,
    required this.bottomInset,
    required this.onPickStep,
    this.onDismiss,
  });

  @override
  State<WheelExerciseCard> createState() => _WheelExerciseCardState();
}

class _WheelExerciseCardState extends State<WheelExerciseCard> {
  static const double _rowHeight = 42;
  static const double _groupHeaderHeight = 33;

  final _scrollController = ScrollController();

  /// Scroll offset of every flat step's row, rebuilt with the list — group
  /// headers make row positions non-uniform.
  List<double> _rowOffsets = const [];

  /// One dismiss per drag: re-armed when the scroll settles.
  bool _dismissArmed = true;

  @override
  void initState() {
    super.initState();
    _scrollToFocus(jump: true);
  }

  @override
  void didUpdateWidget(covariant WheelExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus ||
        oldWidget.family.categoryId != widget.family.categoryId) {
      _scrollToFocus(jump: oldWidget.family.categoryId !=
          widget.family.categoryId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Keeps the selector's step in view: the row lands just under the top of
  /// the list, same as the reference's scrollTo.
  void _scrollToFocus({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final rowTop = widget.focus < _rowOffsets.length
          ? _rowOffsets[widget.focus]
          : widget.focus * _rowHeight;
      final target = (rowTop - 8)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flat = widget.family.flat;
    final index = widget.focus.clamp(0, flat.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: _groupedList(flat, index),
    );
  }

  /// The whole tree as a scrollable list grouped by branch: a section rule
  /// with the branch's name and cleared count, then its steps with the same
  /// node dots the tree uses. Rails reset at every section. The focused step
  /// is highlighted; tapping any row moves the selector to it.
  Widget _groupedList(List<WheelNode> flat, int index) {
    final sections = widget.family.flatSections;
    final groups = <(String, int, int)>[]; // name, start, end
    for (var i = 0; i < flat.length; i++) {
      if (groups.isEmpty || groups.last.$1 != sections[i]) {
        groups.add((sections[i], i, i));
      } else {
        final last = groups.last;
        groups[groups.length - 1] = (last.$1, last.$2, i);
      }
    }

    final children = <Widget>[];
    final offsets = List<double>.filled(flat.length, 0);
    var y = 0.0;
    for (final (name, start, end) in groups) {
      children.add(_groupHeader(name));
      y += _groupHeaderHeight;
      for (var i = start; i <= end; i++) {
        offsets[i] = y;
        children.add(_stepRow(flat, i, index));
        y += _rowHeight;
      }
    }
    _rowOffsets = offsets;

    // Pulling the list down past its top reads as "let go of this tree" —
    // it hands back to the wheel, like the background tap and pinch-out.
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (_dismissArmed &&
              notification.dragDetails != null &&
              notification.metrics.pixels < -60 &&
              widget.onDismiss != null) {
            _dismissArmed = false;
            widget.onDismiss!();
          }
        } else if (notification is ScrollEndNotification) {
          _dismissArmed = true;
        }
        return false;
      },
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        children: children,
      ),
    );
  }

  Widget _groupHeader(String name) {
    return SizedBox(
      height: _groupHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.77,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  /// The quiet leading glyph that carries the step's state — check for
  /// mastered, skip arrow, padlock, the halo dot for training now, and a
  /// plain white ring for a step available to start.
  Widget _lead(WheelNodeState state) {
    final Widget glyph;
    switch (state) {
      case WheelNodeState.active:
        glyph = Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            color: AppColors.accentBright,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x383D7BFF), spreadRadius: 3.5)],
          ),
        );
      case WheelNodeState.mastered:
        glyph = const Icon(
          Icons.check_rounded,
          size: 16,
          color: AppColors.green,
        );
      case WheelNodeState.skipped:
        glyph = Icon(
          Icons.arrow_outward_rounded,
          size: 14,
          color: AppColors.green.withValues(alpha: 0.6),
        );
      case WheelNodeState.available:
        // The same solid white the node wears on the wheel.
        glyph = Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
        );
      case WheelNodeState.locked:
        glyph = const Icon(
          Icons.lock_rounded,
          size: 13,
          color: Color(0xFF4A4B52),
        );
    }
    return SizedBox(width: 20, child: Center(child: glyph));
  }

  Widget _stepRow(List<WheelNode> flat, int i, int index) {
    final node = flat[i];
    final focused = i == index;
    final state = node.state;
    final isActive = state == WheelNodeState.active;

    final titleColor = switch (state) {
      WheelNodeState.active => AppColors.accentBright,
      WheelNodeState.locked => AppColors.textMuted,
      WheelNodeState.mastered ||
      WheelNodeState.skipped =>
        const Color(0xFF9A9BA1),
      WheelNodeState.available => AppColors.textPrimary,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focused ? null : () => widget.onPickStep(i),
      child: Container(
        height: _rowHeight,
        // The ring is drawn inside the box, so the focused row gives its
        // border width back — the text must not shift when the ring lands.
        padding: EdgeInsets.symmetric(horizontal: focused ? 8.5 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? AppColors.accentPrimary.withValues(alpha: 0.10)
              : focused
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
          border: focused
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            _lead(state),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: -0.15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small circular play affordance on a video thumbnail.
class _PlayBadge extends StatelessWidget {
  final double size;
  final double iconSize;

  const _PlayBadge({this.size = 28, this.iconSize = 17});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        size: iconSize,
        color: AppColors.textPrimary,
      ),
    );
  }
}
