import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/catalog/exercise_coaching_catalog.dart';
import '../../../data/services/weight_unit_service.dart';
import '../../home/home_dashboard_metrics.dart';
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
          // The trend groups are empty pre-baseline, so the panel is just
          // the BUILDING BASELINE group with its counters.
          for (final trend in _perfGroupStyles.keys)
            ..._group(trend, overview.rowsFor(trend)),
          ..._baselineGroup(
            overview.rowsFor(PerformanceTrend.buildingBaseline),
            withFooter: overview.hasComparisons,
          ),
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
                'Best session:',
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
    ];
  }

  /// The quiet trailing group: exercises still short of the two separate
  /// trained days a trend needs, each with its day counter. [withFooter]
  /// appends the how-trends-start line — off when that line already leads
  /// the panel.
  List<Widget> _baselineGroup(
    List<PerformanceRowData> rows, {
    required bool withFooter,
  }) {
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 20),
      Row(
        children: [
          const CustomPaint(
            size: Size(7, 7),
            painter: _DashedRingPainter(),
          ),
          const SizedBox(width: 8),
          Text(
            'BUILDING BASELINE',
            style: GoogleFonts.robotoMono(
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
                style: GoogleFonts.robotoMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.95,
                  color: const Color(0xFF4A4B52),
                ),
              ),
            ],
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
                        // A Container, not a bare DecoratedBox: with no child
                        // a DecoratedBox takes the smallest size it is
                        // offered — zero high — and the fill vanishes.
                        child: Container(
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
      case WheelNodeState.active:
        final data = journey;
        if (data == null) {
          text = 'Training';
        } else {
          // "18 of 24 reps (total reps)": where the last session landed
          // against the target, counted across the whole session.
          final unit = data.isTimed ? 'sec' : 'reps';
          text = 'Training · ${data.lastSessionVolume} of '
              '${data.targetVolume} $unit (total $unit)';
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

  /// Reports whether the focused step's row is inside the list's viewport —
  /// the host slides the detail sheet away while it is not.
  final ValueChanged<bool>? onFocusVisible;

  const WheelExerciseCard({
    super.key,
    required this.family,
    required this.focus,
    required this.bottomInset,
    required this.onPickStep,
    this.onDismiss,
    this.onFocusVisible,
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

  /// Last visibility reported for the focused row, so the host only hears
  /// about changes.
  bool _focusReportedVisible = true;

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
      _reportFocusVisibility();
    });
  }

  /// Whether the focused row is inside the viewport right now. Measured
  /// against the whole viewport — not the band the detail sheet covers — so
  /// the sheet hiding and showing cannot feed back into the measurement.
  void _reportFocusVisibility() {
    if (!_scrollController.hasClients) return;
    final rowTop = widget.focus < _rowOffsets.length
        ? _rowOffsets[widget.focus]
        : widget.focus * _rowHeight;
    final position = _scrollController.position;
    final top = position.pixels;
    final bottom = top + position.viewportDimension;
    // At least half the row must show to count as in view.
    final visible =
        rowTop + _rowHeight / 2 > top && rowTop + _rowHeight / 2 < bottom;
    if (visible != _focusReportedVisible) {
      _focusReportedVisible = visible;
      widget.onFocusVisible?.call(visible);
    }
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
          _reportFocusVisibility();
        } else if (notification is ScrollEndNotification) {
          _dismissArmed = true;
          _reportFocusVisibility();
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
      WheelNodeState.mastered => const Color(0xFF9A9BA1),
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
