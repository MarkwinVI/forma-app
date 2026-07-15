import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../home/home_dashboard_metrics.dart';

/// "Exercise performance" card on the Progress tab — one row per exercise in
/// the current program: name, last session total, sparkline of the last 4
/// sessions, and a session-over-session delta pill.
class ExercisePerformanceCard extends StatelessWidget {
  final List<HomeExercisePerformance> rows;

  const ExercisePerformanceCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final hasAnyData = rows.any((row) => row.history.isNotEmpty);

    if (rows.isEmpty || !hasAnyData) {
      return const SurfaceCard(
        padding: EdgeInsets.all(18),
        child: Text(
          'Finish your first workout to start tracking your reps and '
          'holds session over session.',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      );
    }

    return SurfaceCard(
      clip: true,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            _PerformanceRow(perf: rows[index], showDivider: index > 0),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final HomeExercisePerformance perf;
  final bool showDivider;

  const _PerformanceRow({required this.perf, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final delta = perf.sessionDelta;
    final tone = delta == null
        ? AppColors.textMuted
        : delta > 0
            ? AppColors.green
            : delta < 0
                ? AppColors.amber
                : AppColors.textSecondary;
    final unit = perf.isTimed ? 's' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: showDivider
              ? const BorderSide(color: AppColors.divider)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perf.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: 'last ',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                    children: [
                      TextSpan(
                        text: perf.history.isEmpty
                            ? '—'
                            : '${perf.history.last}'
                                '${perf.isTimed ? 's' : ' reps'}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (perf.history.length >= 2) ...[
            const SizedBox(width: 12),
            CustomPaint(
              size: const Size(72, 24),
              painter: _SparklinePainter(values: perf.history, color: tone),
            ),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: delta == null || delta == 0
                      ? AppColors.divider
                      : delta > 0
                          ? AppColors.greenSoft
                          : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  delta == null
                      ? '—'
                      : delta > 0
                          ? '+$delta$unit'
                          : '$delta$unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tone,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final span = (max - min) == 0 ? 1.0 : (max - min).toDouble();

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = 3 + (index / (values.length - 1)) * (size.width - 6);
      final y =
          size.height - 4 - ((values[index] - min) / span) * (size.height - 8);
      points.add(Offset(x, y));
    }

    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(Path()..addPolygon(points, false), line);
    canvas.drawCircle(points.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
