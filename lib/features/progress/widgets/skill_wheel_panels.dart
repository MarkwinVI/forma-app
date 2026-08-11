import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/catalog/exercise_coaching_catalog.dart';
import '../../home/home_dashboard_metrics.dart';
import 'skill_wheel.dart';

// ── MY PERFORMANCE (hardcoded for now; data layer comes later) ────────

class _PerfRow {
  final String name;
  final String best;
  final String delta;

  const _PerfRow(this.name, this.best, this.delta);
}

class _PerfGroup {
  final String label;
  final Color color;
  final IconData icon;
  final List<_PerfRow> rows;

  const _PerfGroup(this.label, this.color, this.icon, this.rows);
}

/// The wheel-overview panel: how the last 14 days compare to the 14 before.
/// Lives in a draggable sheet — [controller] is the sheet's scroll
/// controller, so dragging the panel raises the sheet over the wheel.
class PerformancePanel extends StatelessWidget {
  final double bottomInset;
  final ScrollController? controller;

  const PerformancePanel({
    super.key,
    required this.bottomInset,
    this.controller,
  });

  static const _groups = [
    _PerfGroup('IMPROVING', AppColors.green, Icons.trending_up_rounded, [
      _PerfRow('Assisted Pull-up', '21 reps', '+7'),
      _PerfRow('B.W. Push-ups', '21 reps', '+7'),
      _PerfRow('Barbell Squats', '300kg', '+7'),
    ]),
    _PerfGroup(
        'NEEDS ATTENTION', AppColors.amber, Icons.trending_down_rounded, [
      _PerfRow('Ring Rows', '9 reps', '−2'),
      _PerfRow('Tuck Planche', '12s', '−4'),
    ]),
  ];

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
            'LAST 14 DAYS VS PREV. 14 DAYS',
            style: GoogleFonts.robotoMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
              color: AppColors.textMuted,
            ),
          ),
          for (final group in _groups) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: group.color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.label,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.35,
                    color: group.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final row in group.rows)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        row.name,
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
                      row.best,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(group.icon, size: 15, color: group.color),
                          const SizedBox(width: 2),
                          Text(
                            row.delta,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: group.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Focused exercise: shared status metadata ──────────────────────────

const _statusLabels = {
  WheelNodeState.active: 'NOW',
  WheelNodeState.mastered: 'MASTERED',
  WheelNodeState.skipped: 'SKIPPED',
  WheelNodeState.locked: 'LOCKED',
};

const _statusColors = {
  WheelNodeState.active: AppColors.accentBright,
  WheelNodeState.mastered: AppColors.green,
  WheelNodeState.skipped: AppColors.green,
  WheelNodeState.locked: AppColors.textMuted,
};

const _stateLines = {
  WheelNodeState.mastered: 'Cleared. Kept in rotation as a warm-up.',
  WheelNodeState.skipped:
      'Marked as skipped — you can come back to it any time.',
  WheelNodeState.locked: 'Opens once the step before it is cleared.',
};

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

    final double barPct;
    final Color barColor;
    if (state == WheelNodeState.active) {
      barPct = (journey?.progressPercent ?? 0).clamp(0.0, 1.0);
      barColor = AppColors.accentBright;
    } else if (state == WheelNodeState.locked) {
      barPct = 0;
      barColor = Colors.white.withValues(alpha: 0.08);
    } else {
      barPct = 1;
      barColor = AppColors.green;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumb(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          node.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabels[state]!,
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _statusColors[state],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _description(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF8A8B93),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      height: 4,
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
                  const SizedBox(height: 6),
                  _progressCaption(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the exercise is — its own description when the catalog has one,
  /// the status line otherwise.
  String _description() {
    final exercise = ExerciseCatalog.findById(node.exerciseId);
    final description = exercise?.description.trim() ?? '';
    if (description.isNotEmpty) return description;
    return _stateLines[node.state] ?? '';
  }

  Widget _progressCaption() {
    const body =
        TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF8A8B93));
    const figure = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    if (node.state == WheelNodeState.active) {
      final data = journey;
      if (data == null) {
        return const Text(
          'Train this step to log progress toward the next unlock.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body,
        );
      }
      final unit = data.isTimed ? 's' : ' reps';
      return Text.rich(
        TextSpan(
          text: 'Last ',
          style: body,
          children: [
            TextSpan(text: '${data.lastSessionVolume}', style: figure),
            const TextSpan(text: ' of '),
            TextSpan(text: '${data.targetVolume}$unit', style: figure),
            const TextSpan(
              text: ' (total)',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      _stateLines[node.state] ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: body,
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

    const badge = Center(child: _PlayBadge());

    return Container(
      width: 74,
      height: 74,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0E),
        borderRadius: BorderRadius.circular(12),
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
  static const double _rowHeight = 38;
  static const double _groupHeaderHeight = 40;

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
        children.add(
          _stepRow(flat, i, index, first: i == start, last: i == end),
        );
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
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            Text(
              name,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(height: 1, color: AppColors.divider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepRow(
    List<WheelNode> flat,
    int i,
    int index, {
    required bool first,
    required bool last,
  }) {
    final node = flat[i];
    final focused = i == index;
    final state = node.state;
    final prev = first ? null : flat[i - 1];

    final Color dotColor;
    final double dotSize;
    switch (state) {
      case WheelNodeState.active:
        dotColor = AppColors.accentBright;
        dotSize = 10;
      case WheelNodeState.mastered:
      case WheelNodeState.skipped:
        dotColor = AppColors.green;
        dotSize = 8;
      case WheelNodeState.locked:
        dotColor = AppColors.surface3;
        dotSize = 6.5;
    }

    final railOn = Colors.white.withValues(alpha: 0.09);
    const railGreen = Color(0x803FD07E);
    final railTop = prev == null
        ? Colors.transparent
        : (prev.state.isCleared &&
                (state.isCleared || state == WheelNodeState.active))
            ? railGreen
            : railOn;
    final railBottom = last
        ? Colors.transparent
        : (state.isCleared ? railGreen : railOn);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focused ? null : () => widget.onPickStep(i),
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          children: [
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  Container(width: 1.5, height: 8, color: railTop),
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: focused
                          ? const [
                              BoxShadow(
                                color: Color(0x383D7BFF),
                                spreadRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Container(width: 1.5, color: railBottom),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  letterSpacing: -0.15,
                  fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
                  color: !focused && state == WheelNodeState.locked
                      ? const Color(0xFF8A8B93)
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              _statusLabels[state]!,
              style: GoogleFonts.robotoMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.17,
                color: focused
                    ? _statusColors[state]
                    : const Color(0xFF4A4B52),
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
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 17,
        color: AppColors.textPrimary,
      ),
    );
  }
}
