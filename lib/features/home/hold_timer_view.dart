import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';

/// Full-screen stopwatch for a timed set. Opened from the set's row in the
/// live workout when nothing has been logged for it yet: the hold starts
/// the moment the page appears — no count-in — and the big count runs up
/// against the goal on a ring. Pause exposes ±1s / ±5s fine adjustment for
/// the seconds the stopwatch caught late or ran past. Log hands the seconds
/// back to the workout, which records and ticks the set.
///
/// Returns the logged seconds. Closing while paused counts as logging —
/// the hold is over and the seconds are what they are — so that returns
/// them too; only closing mid-hold, or at zero, returns null.
class HoldTimerView extends StatefulWidget {
  final String exerciseName;
  final int setNumber;
  final int totalSets;

  /// The prescribed seconds; the ring fills against it and the count reads
  /// green once it is reached.
  final int goalSeconds;

  const HoldTimerView({
    super.key,
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.goalSeconds,
  });

  @override
  State<HoldTimerView> createState() => _HoldTimerViewState();
}

class _HoldTimerViewState extends State<HoldTimerView>
    with SingleTickerProviderStateMixin {
  /// The hold is measured against the wall clock, not by counting ticks:
  /// a phone that locks mid-hold still comes back with the right seconds.
  /// [_runningSince] is set while holding; [_bankedMs] is what earlier
  /// stretches added up to.
  DateTime? _runningSince;
  int _bankedMs = 0;

  /// Seconds added or removed with the fine-adjust pills while paused, on
  /// top of what the clock has counted.
  int _adjustmentSeconds = 0;

  /// Redraws every frame while holding, so the ring and count move
  /// smoothly; stopped while paused, when nothing changes on its own.
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _runningSince = clock.now();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _running => _runningSince != null;

  int get _countedMs {
    final since = _runningSince;
    return _bankedMs +
        (since == null ? 0 : clock.now().difference(since).inMilliseconds);
  }

  double get _elapsedSeconds =>
      math.max(0, _countedMs / 1000 + _adjustmentSeconds);

  int get _seconds => _elapsedSeconds.floor();

  bool get _goalHit => widget.goalSeconds > 0 && _seconds >= widget.goalSeconds;

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      final since = _runningSince;
      if (since != null) {
        _bankedMs += clock.now().difference(since).inMilliseconds;
        _runningSince = null;
        _ticker.stop();
      } else {
        _runningSince = clock.now();
        _ticker.start();
      }
    });
  }

  /// Leaving the timer. A paused hold is a finished hold, so its seconds
  /// are logged on the way out; a hold still running is abandoned.
  void _close() {
    final result = !_running && _seconds > 0 ? _seconds : null;
    Navigator.of(context).pop(result);
  }

  void _adjust(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      // Never below zero: an adjustment can take back seconds the stopwatch
      // counted, but not more than it counted.
      final floor = -(_countedMs ~/ 1000);
      _adjustmentSeconds = math.max(floor, _adjustmentSeconds + delta);
    });
  }

  void _log() {
    if (_seconds <= 0) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(_seconds);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _seconds;
    final goalHit = _goalHit;
    final ringColor = goalHit ? AppColors.green : AppColors.accentPrimary;
    final progress = widget.goalSeconds <= 0
        ? 0.0
        : math.min(1.0, _elapsedSeconds / widget.goalSeconds);
    final status = goalHit
        ? 'Goal reached'
        : _running
            ? 'Holding…'
            : 'Paused';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        // A tap anywhere that is not a control pauses the hold, and another
        // resumes it — hands come off the bar and reach for the phone, and
        // the nearest thing to hit should be the right one. The controls sit
        // above and take their own taps first.
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePause,
          child: SafeArea(
            child: Column(
              children: [
                // Header: what is being held, and the way out.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.exerciseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set ${widget.setNumber} of ${widget.totalSets}'
                              '${widget.goalSeconds > 0 ? ' · Goal ${widget.goalSeconds}s' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Pressable(
                        onTap: _close,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Ring and count.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 288,
                        height: 288,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _HoldRingPainter(
                                progress: progress,
                                color: ringColor,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Scaled down only if a count ever outgrows
                                // the ring; four digits fit at full size.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$seconds',
                                        style: const TextStyle(
                                          fontSize: 104,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -4,
                                          height: 1,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        's',
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          status,
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.27,
                                            color: goalHit
                                                ? AppColors.green
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      // Fine adjustment, only while paused: the seconds the
                      // stopwatch caught late or ran past.
                      IgnorePointer(
                        ignoring: _running,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _running ? 0 : 1,
                          child: SizedBox(
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final delta in const [-5, -1, 1, 5]) ...[
                                  if (delta != -5) const SizedBox(width: 10),
                                  _AdjustPill(
                                    label:
                                        delta > 0 ? '+${delta}s' : '${delta}s',
                                    onTap: () => _adjust(delta),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls: pause/resume, and log.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  child: Row(
                    children: [
                      Pressable(
                        onTap: _togglePause,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 26,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Pressable(
                          onTap: seconds > 0 ? _log : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 58,
                            decoration: BoxDecoration(
                              color: seconds > 0
                                  ? AppColors.accentPrimary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: seconds > 0 ? 1 : 0.5,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    seconds > 0
                                        ? 'Log set · ${seconds}s'
                                        : 'Log set',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdjustPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdjustPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// The goal ring: a faint full track with the elapsed share drawn over it
/// from twelve o'clock, round-capped.
class _HoldRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _HoldRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_HoldRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
