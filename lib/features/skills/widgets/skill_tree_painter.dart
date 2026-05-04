import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';
import 'exercise_node.dart';

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

        final prereqStatus = progressMap[prereqId] ?? ExerciseStatus.inactive;
        final color = prereqStatus == ExerciseStatus.mastered
            ? _masteredColor.withValues(alpha: 0.6)
            : prereqStatus == ExerciseStatus.active
                ? AppColors.accentBright.withValues(alpha: 0.4)
                : AppColors.borderPrimary.withValues(alpha: 0.6);

        final paint = Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        final p0 = Offset(from.dx, from.dy + kNodeHeight / 2);
        final p3 = Offset(to.dx, to.dy - kNodeHeight / 2);
        final midY = p0.dy + (p3.dy - p0.dy) * 0.5;

        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p0.dx, midY)
          ..lineTo(p3.dx, midY)
          ..lineTo(p3.dx, p3.dy);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SkillTreePainter old) =>
      old.progressMap != progressMap || old.nodePositions != nodePositions;
}
