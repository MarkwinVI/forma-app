import 'dart:math' as math;

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

// ── Focused tree: the step list ───────────────────────────────────────

/// The quiet glyph that carries a step's state, shared by the step list's
/// status lines and the preview sheet: the halo dot for training now, a
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

/// The step's state in a word, with its tint — the preview sheet's status
/// line. The rows say the same in fewer letters (see the list).
(String, Color) wheelStepStatus(WheelNode node) => node.skipped
    ? ('Skipped', AppColors.textMuted)
    : switch (node.state) {
        WheelNodeState.active => ('Training', AppColors.accentBright),
        WheelNodeState.mastered => ('Mastered', AppColors.green),
        WheelNodeState.available => (
            'Unlocked · not training',
            AppColors.textPrimary,
          ),
        WheelNodeState.locked => ('Locked', AppColors.textMuted),
      };

/// The demo frame for a step: the clip's poster when there is footage, the
/// exercise's still otherwise. Null when the catalog knows neither.
String? wheelStepImageUrl(WheelNode node) {
  final exercise = ExerciseCatalog.findById(node.exerciseId);
  final coaching =
      exercise == null ? null : ExerciseCoachingCatalog.forExercise(exercise);
  final videoId = coaching?.videoId;
  if (videoId != null) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
  if (coaching?.imageUrl.isNotEmpty ?? false) return coaching!.imageUrl;
  final still = exercise?.imageUrl;
  return still == null || still.isEmpty ? null : still;
}

/// Whether [url] is a YouTube poster frame (`img.youtube.com/vi/…`).
bool isYouTubePoster(String url) => url.contains('img.youtube.com/vi/');

/// A YouTube poster, cropped to the picture. YouTube's `hqdefault.jpg` is a
/// 4:3 frame with a widescreen clip letterboxed into it — black bars an
/// eighth of the height above and below — so a plain cover crop of it shows
/// a black strip wherever the crop is off-centre or the frame is narrower
/// than 16:9. This sizes the 4:3 image so its 16:9 band covers the frame,
/// centred, and lets the frame clip the bars away.
class YouTubePoster extends StatelessWidget {
  final String url;

  const YouTubePoster({super.key, required this.url});

  static const double _picture = 16 / 9;
  static const double _image = 4 / 3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameW = constraints.maxWidth;
        final frameH = constraints.maxHeight;
        // The 16:9 picture, just covering the frame…
        final pictureW =
            frameW / frameH >= _picture ? frameW : frameH * _picture;
        // …and the whole 4:3 image around it.
        final imageW = pictureW;
        final imageH = imageW / _image;
        return ClipRect(
          child: OverflowBox(
            minWidth: imageW,
            maxWidth: imageW,
            minHeight: imageH,
            maxHeight: imageH,
            child: Image.network(
              url,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// The demo as a framed thumbnail — in every row, small and quiet; in the
/// preview sheet, wide, with the play badge, and a tap into the exercise.
class _StepThumb extends StatelessWidget {
  final WheelNode node;
  final double? width;
  final double? height;
  final double radius;
  final bool play;
  final VoidCallback? onTap;

  const _StepThumb({
    required this.node,
    this.width,
    this.height,
    required this.radius,
    this.play = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = wheelStepImageUrl(node);
    final frame = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF17171B),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            if (isYouTubePoster(imageUrl))
              YouTubePoster(url: imageUrl)
            else
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                // The still's subject sits high in the frame.
                alignment: const Alignment(0, -0.4),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
          if (play) const Center(child: _PlayBadge(size: 36, iconSize: 20)),
        ],
      ),
    );
    if (onTap == null) return frame;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Open ${node.name}',
      child: frame,
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

/// Edit mode's radio at the end of every row: filled on the step being
/// trained, an empty ring on the rest — the list reads as the one choice
/// it is.
class WheelStepRadio extends StatelessWidget {
  final bool on;

  const WheelStepRadio({super.key, required this.on});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: on
              ? AppColors.accentBright
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Center(
        child: AnimatedScale(
          scale: on ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentBright,
            ),
          ),
        ),
      ),
    );
  }
}

/// The whole tree as a scrollable list grouped by branch: one media row per
/// step — thumbnail, name, status — with the same glyphs the tree uses.
/// Tapping a row is the screen's to answer ([onPickStep]); moving the
/// selector (swipe or node tap) brings the step it landed on into view and
/// rests a quiet highlight on it. In edit mode every row ends in a radio.
class WheelExerciseCard extends StatefulWidget {
  final WheelFamily family;
  final int focus;
  final double bottomInset;

  /// Each step's best-workout numbers, by exercise id — a mastered row says
  /// what it was mastered with.
  final Map<String, WheelStepStats> stepStats;

  /// Edit mode: the rows wear radios, filled on the step being trained.
  final bool editing;

  /// A tap on a row, by flat index.
  final void Function(int flatIndex) onPickStep;

  const WheelExerciseCard({
    super.key,
    required this.family,
    required this.focus,
    required this.bottomInset,
    required this.onPickStep,
    this.stepStats = const {},
    this.editing = false,
  });

  @override
  State<WheelExerciseCard> createState() => _WheelExerciseCardState();
}

class _WheelExerciseCardState extends State<WheelExerciseCard> {
  /// A row: the 40pt thumbnail with 8pt above and below.
  static const double _rowHeight = 56;
  static const double _groupHeaderHeight = 40;

  final _scrollController = ScrollController();

  /// Scroll offset of every flat step's row, rebuilt with the list — group
  /// headers make row positions non-uniform.
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
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Keeps the selector's step in view. A row already wholly inside the
  /// viewport stays where it is. Otherwise the row lands just under the top
  /// of the list — except the first step of a branch, which brings its
  /// branch header with it; scrolling that step to the top alone left the
  /// header cut off under the list's edge.
  void _scrollToFocus({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final rowTop = widget.focus < _rowOffsets.length
          ? _rowOffsets[widget.focus]
          : widget.focus * _rowHeight;
      final rowBottom = rowTop + _rowHeight;
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

    // Rows sit 10pt in from the edge, their content 22pt — the highlight on
    // the focused row reaches out past the content column.
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: _groupedList(flat, index),
    );
  }

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

  /// One step: thumbnail, name, and a status line in the state's tint —
  /// "Training", "Mastered · 27 reps", "Unlocked", "Locked", or "Skipped"
  /// for a locked step a jump ahead left behind. The step being trained
  /// reads bold and blue; a locked step sits back a little.
  Widget _stepRow(List<WheelNode> flat, int i, int index) {
    final node = flat[i];
    final state = node.state;
    final training = state == WheelNodeState.active;
    final focused = i == index;
    final stats = widget.stepStats[node.exerciseId];

    final (status, statusColor) = switch (state) {
      WheelNodeState.active => ('Training', AppColors.accentBright),
      WheelNodeState.mastered => (
          stats != null && stats.bestVolume > 0
              ? 'Mastered · ${stats.bestVolume} ${stats.unit}'
              : 'Mastered',
          AppColors.green,
        ),
      WheelNodeState.available => ('Unlocked', AppColors.textMuted),
      WheelNodeState.locked => (
          node.skipped ? 'Skipped' : 'Locked',
          AppColors.textMuted,
        ),
    };
    final nameColor = training
        ? AppColors.accentBright
        : state == WheelNodeState.locked
            ? AppColors.textMuted
            : AppColors.textPrimary;

    return Pressable(
      onTap: () => widget.onPickStep(i),
      selected: widget.editing ? training : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: _rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: focused
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Opacity(
          opacity: state == WheelNodeState.locked ? 0.75 : 1,
          child: Row(
            children: [
              _StepThumb(node: node, width: 64, height: 40, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight:
                            training ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.15,
                        height: 1.2,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Center(
                            child: WheelStepGlyph(state: state, size: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.2,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.editing) ...[
                const SizedBox(width: 12),
                WheelStepRadio(on: training),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Focused tree: the preview sheet ───────────────────────────────────

/// Opens a step's preview as a bottom sheet over the wheel: the demo, its
/// name and status, the best-workout bar, and Full details into
/// the exercise's page. Preview only — changing the step lives behind Edit.
Future<void> showWheelStepPreview(
  BuildContext context, {
  required WheelNode node,
  required WheelStepStats? stats,
  required VoidCallback onOpenExercise,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Container(
        constraints: BoxConstraints(
          maxHeight: media.size.height - media.padding.top - 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x80000000),
              offset: Offset(0, -20),
              blurRadius: 60,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            10,
            22,
            math.max(30, media.padding.bottom + 16),
          ),
          child: WheelStepPreview(
            node: node,
            stats: stats,
            // Full details closes the preview on its way to the page.
            onOpenExercise: () {
              Navigator.of(sheetContext).pop();
              onOpenExercise();
            },
          ),
        ),
      );
    },
  );
}

/// The preview sheet's body. Every state shares one layout: the bar is
/// blue while training, green and full once mastered, dim otherwise; a
/// step with no numbers shows its status alone.
class WheelStepPreview extends StatelessWidget {
  final WheelNode node;

  /// The bar's numbers; without them the status stands alone.
  final WheelStepStats? stats;

  /// Opens the exercise's own page — the thumbnail's tap and Full details.
  final VoidCallback onOpenExercise;

  const WheelStepPreview({
    super.key,
    required this.node,
    required this.stats,
    required this.onOpenExercise,
  });

  static const _kicker = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final (status, statusColor) = wheelStepStatus(node);
    final stats = this.stats;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _StepThumb(
            node: node,
            radius: 16,
            play: true,
            onTap: onOpenExercise,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          node.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.55,
            height: 1.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 16,
              child: Center(child: WheelStepGlyph(state: node.state, size: 15)),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        if (stats != null) ...[
          const SizedBox(height: 16),
          _meter(stats),
        ],
        const SizedBox(height: 20),
        Pressable(
          onTap: onOpenExercise,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Full details',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// BEST WORKOUT over the bar: the most volume the movement logged in one
  /// workout against what masters the step, and what the bar counts toward.
  Widget _meter(WheelStepStats stats) {
    final state = node.state;
    final mastered = state.isCleared;
    final target = stats.targetVolume;
    final best = stats.bestVolume;
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
    final caption = mastered
        ? 'Mastered. This step is complete.'
        : '$target ${stats.unit} in a single workout masters this step.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('BEST WORKOUT', style: _kicker),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$best',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' / $target ${stats.unit}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              // A Container, not a bare DecoratedBox: with no child a
              // DecoratedBox takes the smallest size it is offered — zero
              // high — and the fill vanishes.
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          caption,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
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
