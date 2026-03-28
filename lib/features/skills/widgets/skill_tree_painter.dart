import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';

const _masteredColor = Color(0xFF4CAF50);

class SkillTreePainter extends CustomPainter {
  final List<Exercise> exercises;
  final Map<String, Offset> nodePositions;
  final Map<String, ExerciseStatus> progressMap;

  const SkillTreePainter({
    required this.exercises,
    required this.nodePositions,
    required this.progressMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final exercise in exercises) {
      for (final prereqId in exercise.prerequisiteIds) {
        final from = nodePositions[prereqId];
        final to = nodePositions[exercise.id];
        if (from == null || to == null) continue;

        final prereqStatus =
            progressMap[prereqId] ?? ExerciseStatus.inactive;
        final color = prereqStatus == ExerciseStatus.mastered
            ? _masteredColor.withValues(alpha: 0.6)
            : prereqStatus == ExerciseStatus.active
                ? AppColors.accentBright.withValues(alpha: 0.4)
                : AppColors.borderPrimary.withValues(alpha: 0.6);

        final paint = Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        const halfNode = 40.0; // kNodeSize / 2
        final p0 = Offset(from.dx, from.dy + halfNode);
        final p3 = Offset(to.dx, to.dy - halfNode);
        final midY = (p3.dy - p0.dy) * 0.5;
        final p1 = Offset(p0.dx, p0.dy + midY);
        final p2 = Offset(p3.dx, p3.dy - midY);

        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SkillTreePainter old) =>
      old.progressMap != progressMap ||
      old.nodePositions != nodePositions;
}
