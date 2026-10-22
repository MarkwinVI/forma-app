import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/catalog/exercise_coaching_catalog.dart';
import '../../../data/services/weight_unit_service.dart';
import '../../exercises/exercise_detail_view.dart';
import '../performance_overview.dart';
import 'skill_wheel.dart';

// ── MY PERFORMANCE ────────────────────────────────────────────────────

/// Look of one trend section: label, tint, and the trailing trend icon.
class _PerfGroupStyle {
  final String label;
  final Color color;
  final IconData icon;

  const _PerfGroupStyle(this.label, this.color, this.icon);
}

/// How trends start — leads the panel before anything has a baseline,
/// trails the BUILDING BASELINE group once trends exist.
const _baselineExplainer =
    'Trends appear after an exercise is trained on two separate days.';

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
    'DECLINING',
    AppColors.amber,
    Icons.trending_down_rounded,
  ),
};

/// The wheel-overview panel: every exercise in the workout lists, grouped by
/// how its last session's volume moved against the session before it.
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
          // Before anything has a baseline the how-trends-start line leads
          // the panel; once trends exist it trails the baseline group and
          // the eyebrow names the comparison window instead.
          if (!overview.hasComparisons)
            const Text(
              _baselineExplainer,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            )
          else
            const Text(
              'LAST SESSION VS PREVIOUS SESSION',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.35,
                color: AppColors.textMuted,
              ),
            ),
          // The trend groups are empty pre-baseline, so the panel is just
          // the BUILDING BASELINE group with its counters.
          for (final trend in _perfGroupStyles.keys)
            ..._group(context, trend, overview.rowsFor(trend)),
          ..._baselineGroup(
            context,
            overview.rowsFor(PerformanceTrend.buildingBaseline),
            withFooter: overview.hasComparisons,
          ),
        ],
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    PerformanceTrend trend,
    List<PerformanceRowData> rows,
  ) {
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
            style: TextStyle(
              fontFamily: 'RobotoMono',
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
        _tappable(
          context,
          row,
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
                  'Last session:',
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
                // Fixed-width trailing box so the values line up across
                // groups. A kilogram delta can run to four figures, so the
                // contents scale down to the box rather than spill out of it.
                SizedBox(
                  width: 60,
                  child: row.delta == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(style.icon, size: 15, color: style.color),
                              const SizedBox(width: 2),
                              Text(
                                _deltaLabel(row),
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: style.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  /// The quiet trailing group: exercises still short of the two separate
  /// trained days a trend needs, each with its day counter. [withFooter]
  /// appends the how-trends-start line — off when that line already leads
  /// the panel.
  List<Widget> _baselineGroup(
    BuildContext context,
    List<PerformanceRowData> rows, {
    required bool withFooter,
  }) {
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 20),
      const Row(
        children: [
          CustomPaint(
            size: Size(7, 7),
            painter: _DashedRingPainter(),
          ),
          SizedBox(width: 8),
          Text(
            'BUILDING BASELINE',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      for (final row in rows)
        _tappable(
          context,
          row,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      letterSpacing: -0.15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                for (var day = 0; day < 2; day++) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(left: day == 0 ? 0 : 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: day < row.daysTrained ? 0.4 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Text(
                  '${row.daysTrained} OF 2 DAYS',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.95,
                    color: Color(0xFF4A4B52),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (withFooter) ...[
        const SizedBox(height: 12),
        const Text(
          _baselineExplainer,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ];
  }

  /// A row opens its exercise — the whole row, since a name alone is a thin
  /// target and the numbers beside it are about the same movement.
  static Widget _tappable(
    BuildContext context,
    PerformanceRowData row,
    Widget child,
  ) {
    final exercise = ExerciseCatalog.findById(row.exerciseId);
    if (exercise == null) return child;
    return Pressable(
      onTap: () => openExerciseDetailView<void>(
        context,
        exercise: exercise,
        skillCategoryId:
            exercise.skillCategoryId.isEmpty ? null : exercise.skillCategoryId,
      ),
      child: child,
    );
  }

  /// The session's volume in the exercise's own unit: seconds, kilograms
  /// (or pounds) lifted, or reps. Kilogram totals climb into four figures
  /// quickly, so they read compacted — "2.9k kg".
  static String _bestLabel(PerformanceRowData row) {
    if (row.bestValue <= 0) return '—';
    if (row.isTimed) return '${row.bestValue}s';
    if (row.isWeighted) {
      final shown = WeightUnitService.toDisplay(row.bestValue.toDouble());
      return '${compactNumber(shown)} ${WeightUnitService.unit.suffix}';
    }
    return row.bestValue == 1 ? '1 rep' : '${row.bestValue} reps';
  }

  /// Signed delta, with the typographic minus the design reads best with;
  /// a weighted delta in the display unit, compacted the same way.
  static String _deltaLabel(PerformanceRowData row) {
    final delta = row.delta ?? 0;
    final shown = row.isWeighted
        ? compactNumber(WeightUnitService.toDisplay(delta.abs().toDouble()))
        : '${delta.abs()}';
    if (delta > 0) return '+$shown';
    if (delta < 0) return '−$shown';
    return '0';
  }
}

/// The BUILDING BASELINE group's marker: the same 7px dot the trend groups
/// wear, drawn as a dashed outline — a baseline still being traced.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.25);
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - paint.strokeWidth) / 2;
    // Four dashes around the ring, gaps matching the dashes.
    const dashes = 4;
    const sweep = 3.14159265 * 2 / (dashes * 2);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep * 2,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}

// ── Focused tree: the open row ────────────────────────────────────────

/// The quiet glyph that carries a step's state, shared by the step list's
/// rows and the open row's status line: the halo dot for training now, a
/// check for mastered, a plain white dot for a step available to start, and
/// the padlock.
class WheelStepGlyph extends StatelessWidget {
  final WheelNodeState state;

  /// The padlock's size; the check draws a touch larger, and the dots keep
  /// their own.
  final double size;

  const WheelStepGlyph({super.key, required this.state, this.size = 16});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case WheelNodeState.active:
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: AppColors.accentBright,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBright.withValues(alpha: 0.22),
                spreadRadius: 4,
              ),
            ],
          ),
        );
      case WheelNodeState.mastered:
        return Icon(
          Icons.check_rounded,
          size: size + 3,
          color: AppColors.green,
        );
      case WheelNodeState.available:
        // The same solid white the node wears on the wheel.
        return Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
        );
      case WheelNodeState.locked:
        return Icon(
          Icons.lock_rounded,
          size: size,
          color: const Color(0xFF4A4B52),
        );
    }
  }
}

/// What a tapped row opens in place: the exercise's demo as a thumbnail,
/// its status, the best-workout meter, and — in edit mode — [action], the
/// one button that applies to the step. Every state shares one layout: the
/// bar is blue while training, green and full once mastered, dim otherwise.
class WheelStepDetail extends StatelessWidget {
  final WheelNode node;

  /// The meter's numbers; without them the status stands alone.
  final WheelStepStats? stats;

  /// Opens the exercise's own page — the thumbnail's tap.
  final VoidCallback onOpen;
  final Widget? action;

  const WheelStepDetail({
    super.key,
    required this.node,
    required this.stats,
    required this.onOpen,
    this.action,
  });

  static const double _thumbHeight = 78;
  static const double _meterHeight = 30;
  static const double _actionHeight = 44;

  /// The detail's height, fixed so a host can lay rows out without
  /// measuring: thumbnail, meter and action are all fixed-height.
  static double heightFor({required bool withAction}) =>
      2 +
      _thumbHeight +
      10 +
      _meterHeight +
      12 +
      (withAction ? 12 + _actionHeight : 0);

  @override
  Widget build(BuildContext context) {
    final state = node.state;
    final mastered = state.isCleared;
    final stats = this.stats;
    final target = stats?.targetVolume ?? 0;
    final best = stats?.bestVolume ?? 0;
    // Full once mastered whatever was logged — a step mastered by jumping
    // past it never reached its own target.
    final fill = mastered
        ? 1.0
        : target <= 0
            ? 0.0
            : (best / target).clamp(0.0, 1.0);
    final fillColor = mastered
        ? AppColors.green
        : state == WheelNodeState.active
            ? AppColors.accentBright
            : Colors.white.withValues(alpha: 0.22);
    // What the bar counts toward, said only where it still applies.
    final caption = stats == null || mastered || state == WheelNodeState.locked
        ? ''
        : '$target ${stats.unit} in a single workout masters this step.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _thumbHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WheelStepThumb(node: node, onTap: onOpen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusLine(),
                      if (stats != null) ...[
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Best workout '),
                              TextSpan(
                                text: '$best / $target ${stats.unit}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: _meterHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 6,
                    color: Colors.white.withValues(alpha: 0.08),
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      widthFactor: fill,
                      // A Container, not a bare DecoratedBox: with no child
                      // a DecoratedBox takes the smallest size it is
                      // offered — zero high — and the fill vanishes.
                      child: Container(
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: _actionHeight, child: action),
          ],
        ],
      ),
    );
  }

  /// The step's state in a word, beside the same glyph its row wears.
  Widget _statusLine() {
    final (label, color) = switch (node.state) {
      WheelNodeState.active => ('Training', AppColors.accentBright),
      WheelNodeState.mastered => ('Mastered', AppColors.green),
      WheelNodeState.available => (
          'Unlocked · not training',
          AppColors.textPrimary,
        ),
      WheelNodeState.locked => ('Locked', AppColors.textMuted),
    };
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Center(child: WheelStepGlyph(state: node.state, size: 15)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// The demo as a 16:9 thumbnail — the clip's poster frame when there is
/// footage, the exercise's still otherwise — with a play badge over it.
/// Tapping it opens the exercise's page.
class _WheelStepThumb extends StatelessWidget {
  final WheelNode node;
  final VoidCallback onTap;

  const _WheelStepThumb({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    final coaching =
        exercise == null ? null : ExerciseCoachingCatalog.forExercise(exercise);
    final videoId = coaching?.videoId;
    final imageUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : ((coaching?.imageUrl.isNotEmpty ?? false)
            ? coaching!.imageUrl
            : exercise?.imageUrl);

    return Pressable(
      onTap: onTap,
      semanticLabel: 'Open ${node.name}',
      child: Container(
        width: 136,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF17171B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                // The poster's subject sits high in the frame.
                alignment: const Alignment(0, -0.4),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            const Center(child: _PlayBadge(size: 32, iconSize: 17)),
          ],
        ),
      ),
    );
  }
}

// ── Focused tree: the step list ───────────────────────────────────────

/// The whole tree as a scrollable list grouped by branch. Tapping a row
/// moves the selector; moving the selector (swipe or node tap) brings the
/// step it landed on into view. The focused row opens in place — [detail]
/// renders under its name — and the rest of the list stays where it was.
class WheelExerciseCard extends StatefulWidget {
  final WheelFamily family;
  final int focus;
  final double bottomInset;

  /// What the focused row shows under its name, or null while it is
  /// closed.
  final Widget? detail;

  /// [detail]'s height, so the list can tell whether the whole open row is
  /// in view without measuring it.
  final double detailHeight;

  /// A tap on a row — another step, to move the selector there, or the
  /// focused step itself, to open or close it.
  final void Function(int flatIndex) onPickStep;

  const WheelExerciseCard({
    super.key,
    required this.family,
    required this.focus,
    required this.bottomInset,
    required this.onPickStep,
    this.detail,
    this.detailHeight = 0,
  });

  @override
  State<WheelExerciseCard> createState() => _WheelExerciseCardState();
}

class _WheelExerciseCardState extends State<WheelExerciseCard> {
  /// The name row plus the hairline ring around it, which every row wears
  /// (transparent until selected) so nothing shifts when a row opens.
  static const double _rowHeight = 48;
  static const double _groupHeaderHeight = 40;

  final _scrollController = ScrollController();

  /// Scroll offset of every flat step's row, rebuilt with the list — group
  /// headers make row positions non-uniform. The open row's detail only
  /// pushes the rows after it, which the selector never scrolls to.
  List<double> _rowOffsets = const [];

  /// For the first step of each branch, the top of its header; null for
  /// every other step.
  List<double?> _rowHeaderTops = const [];

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
      _scrollToFocus(
          jump: oldWidget.family.categoryId != widget.family.categoryId);
    } else if (oldWidget.detail == null && widget.detail != null) {
      // Re-opening a row can push its detail under the list's edge.
      _scrollToFocus();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Keeps the selector's step in view. An open row that is wholly inside
  /// the viewport stays where it is — the detail opens next to the name and
  /// the rest of the list holds still. A scroll, and a scroll only ever
  /// happens while the list is not being tapped, lands the row just under
  /// the top of the list so its detail has the room below — except the
  /// first step of a branch, which brings its branch header with it;
  /// scrolling that step to the top alone left the header cut off under
  /// the list's edge.
  void _scrollToFocus({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final rowTop = widget.focus < _rowOffsets.length
          ? _rowOffsets[widget.focus]
          : widget.focus * _rowHeight;
      final rowBottom = rowTop + _rowHeight + widget.detailHeight;
      if (rowTop >= position.pixels &&
          rowBottom <= position.pixels + position.viewportDimension) {
        return;
      }
      final headerTop = widget.focus < _rowHeaderTops.length
          ? _rowHeaderTops[widget.focus]
          : null;
      final target =
          (headerTop ?? (rowTop - 8)).clamp(0.0, position.maxScrollExtent);
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

    // Rows sit 10pt in from the edge, their text 22pt — the ring around an
    // open row reaches out past the text column.
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: _groupedList(flat, index),
    );
  }

  /// The whole tree as a scrollable list grouped by branch: the branch's
  /// name, then its steps with the same glyphs the tree uses. The focused
  /// step is ringed and open; tapping any row moves the selector to it.
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
    final headerTops = List<double?>.filled(flat.length, null);
    var y = 0.0;
    for (final (name, start, end) in groups) {
      children.add(_groupHeader(name));
      // The first step of a branch remembers where its header starts, so
      // scrolling to it brings the header along rather than clipping it.
      headerTops[start] = y;
      y += _groupHeaderHeight;
      for (var i = start; i <= end; i++) {
        offsets[i] = y;
        children.add(_stepRow(flat, i, index));
        y += _rowHeight;
      }
    }
    _rowOffsets = offsets;
    _rowHeaderTops = headerTops;

    // Scrolling only ever scrolls: pulling the list past its top bounces
    // and settles, and leaving the tree stays with the back button, the
    // edge swipe and the pinch.
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.only(bottom: widget.bottomInset),
      children: children,
    );
  }

  Widget _groupHeader(String name) {
    return SizedBox(
      height: _groupHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              height: 16 / 12.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepRow(List<WheelNode> flat, int i, int index) {
    final node = flat[i];
    final state = node.state;
    final selected = i == index && widget.detail != null;
    // The open row of the step being trained reads blue, name and all;
    // closed, the training step is told by its halo dot alone.
    final blue = selected && state == WheelNodeState.active;

    final nameColor = blue
        ? AppColors.accentBright
        : switch (state) {
            WheelNodeState.locked => AppColors.textMuted,
            WheelNodeState.mastered => const Color(0xFFC9CAD0),
            _ => AppColors.textPrimary,
          };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onPickStep(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: !selected
              ? Colors.transparent
              : blue
                  ? AppColors.accentBright.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: !selected
                ? Colors.transparent
                : blue
                    ? AppColors.accentBright.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _rowHeight - 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      child: Center(child: WheelStepGlyph(state: state)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        node.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: -0.16,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: nameColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The detail fades in under the name; a new step's detail fades
            // in afresh, the same step's updates (edit mode's button) do
            // not.
            if (selected)
              TweenAnimationBuilder<double>(
                key: ValueKey(node.exerciseId),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (_, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: widget.detail,
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
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        size: iconSize,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// A number the eye can take in at a glance: whole below a thousand, then
/// thousands to one decimal — 960, 1.5k, 12k. The decimal goes once it would
/// be a trailing zero.
String compactNumber(double value) {
  if (value < 1000) return value.round().toString();
  final thousands = value / 1000;
  final oneDecimal = (thousands * 10).round() / 10;
  if (oneDecimal >= 10 || oneDecimal == oneDecimal.roundToDouble()) {
    return '${oneDecimal.round()}k';
  }
  return '${oneDecimal.toStringAsFixed(1)}k';
}
