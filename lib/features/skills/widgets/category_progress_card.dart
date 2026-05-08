import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/skill_category_model.dart';

const _badgeBg = Color(0x14FFFFFF);
const _badgeBorder = Color(0x1FFFFFFF);

class CategoryProgressCard extends StatelessWidget {
  final SkillCategory category;
  final int mastered;
  final int total;
  final Map<String, ExerciseStatus> progressMap;
  final bool isFocused;
  final VoidCallback onTap;

  const CategoryProgressCard({
    super.key,
    required this.category,
    required this.mastered,
    required this.total,
    required this.progressMap,
    required this.isFocused,
    required this.onTap,
  });

  IconData get _icon {
    switch (category.track) {
      case ExerciseCategory.verticalPull:
        return Icons.sports_gymnastics_rounded;
      case ExerciseCategory.verticalPush:
        return Icons.front_hand_outlined;
      case ExerciseCategory.horizontalPull:
        return Icons.arrow_back;
      case ExerciseCategory.horizontalPush:
        return Icons.arrow_forward;
      case ExerciseCategory.squat:
        return Icons.accessibility_new;
      case ExerciseCategory.hinge:
        return Icons.keyboard_double_arrow_down;
      case ExerciseCategory.core:
        return Icons.radio_button_checked;
      case ExerciseCategory.skill:
        return Icons.fitness_center_rounded;
    }
  }

  List<Color> get _gradient {
    switch (category.track) {
      case ExerciseCategory.verticalPull:
        return const [Color(0xFF16384A), Color(0xFF0F1D2A)];
      case ExerciseCategory.verticalPush:
        return const [Color(0xFF3B2C1D), Color(0xFF201611)];
      case ExerciseCategory.horizontalPull:
        return const [Color(0xFF1E3446), Color(0xFF131F2E)];
      case ExerciseCategory.horizontalPush:
        return const [Color(0xFF3E241B), Color(0xFF211412)];
      case ExerciseCategory.squat:
        return const [Color(0xFF263D21), Color(0xFF162317)];
      case ExerciseCategory.hinge:
        return const [Color(0xFF3B3320), Color(0xFF201D14)];
      case ExerciseCategory.core:
        return const [Color(0xFF203746), Color(0xFF121E2B)];
      case ExerciseCategory.skill:
        return const [Color(0xFF3A233C), Color(0xFF1D1220)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? mastered / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isFocused ? 1 : 0.96,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradient,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isFocused
                      ? AppColors.accentBright.withValues(alpha: 0.28)
                      : AppColors.borderPrimary,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x22000000),
                    blurRadius: isFocused ? 30 : 20,
                    offset: const Offset(0, 14),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              AppColors.accentPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppColors.accentPrimary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          _icon,
                          color: AppColors.accentBright,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _badgeBorder),
                          ),
                          child: Text(
                            category.subtitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.82),
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 96,
                    child: _CategoryConstellationPreview(
                      category: category,
                      progressMap: progressMap,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$mastered / $total mastered',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentBright,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryConstellationPreview extends StatelessWidget {
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;

  const _CategoryConstellationPreview({
    required this.category,
    required this.progressMap,
  });

  List<String> get _realPathIds {
    if (category.trainingPaths.isNotEmpty) {
      return category.trainingPaths.keys.toList();
    }
    return const ['main'];
  }

  List<String> get _sharedFoundationExerciseIds {
    if (_realPathIds.length < 2) return const [];
    final lists = _realPathIds
        .map((pathId) => category.trainingPaths[pathId] ?? const <String>[])
        .toList();
    if (lists.any((list) => list.isEmpty)) return const [];

    final shared = <String>[];
    final shortest =
        lists.map((list) => list.length).reduce((a, b) => a < b ? a : b);
    for (var i = 0; i < shortest; i++) {
      final candidate = lists.first[i];
      if (lists.every((list) => list[i] == candidate)) {
        shared.add(candidate);
      } else {
        break;
      }
    }
    return shared;
  }

  bool get _hasFoundation => _sharedFoundationExerciseIds.isNotEmpty;

  List<Exercise> _exercisesForPath(String pathId) {
    if (pathId == '__foundation__') {
      return _sharedFoundationExerciseIds
          .map(ExerciseCatalog.findById)
          .whereType<Exercise>()
          .toList();
    }

    final ids = category.trainingPaths[pathId] ?? const <String>[];
    final visibleIds =
        _hasFoundation ? ids.skip(_sharedFoundationExerciseIds.length) : ids;
    return visibleIds
        .map(ExerciseCatalog.findById)
        .whereType<Exercise>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final overviewPaths =
        _hasFoundation ? ['__foundation__', ..._realPathIds] : _realPathIds;

    return CustomPaint(
      painter: _CategoryConstellationPainter(
        overviewPaths: overviewPaths,
        exercisesForPath: _exercisesForPath,
        progressMap: progressMap,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CategoryConstellationPainter extends CustomPainter {
  final List<String> overviewPaths;
  final List<Exercise> Function(String pathId) exercisesForPath;
  final Map<String, ExerciseStatus> progressMap;

  const _CategoryConstellationPainter({
    required this.overviewPaths,
    required this.exercisesForPath,
    required this.progressMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stars = <Offset>[
      Offset(size.width * 0.08, size.height * 0.18),
      Offset(size.width * 0.28, size.height * 0.08),
      Offset(size.width * 0.52, size.height * 0.16),
      Offset(size.width * 0.81, size.height * 0.1),
      Offset(size.width * 0.18, size.height * 0.74),
      Offset(size.width * 0.7, size.height * 0.7),
    ];
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (final star in stars) {
      canvas.drawCircle(star, 1.8, starPaint);
    }

    final positions = _previewOverviewPositions(overviewPaths.length)
        .map(
            (offset) => Offset(offset.dx * size.width, offset.dy * size.height))
        .toList();

    if (positions.length > 1) {
      final basePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      final splitY = positions.first.dy + size.height * 0.18;
      canvas.drawLine(
          positions.first, Offset(positions.first.dx, splitY), basePaint);
      final minX =
          positions.skip(1).map((e) => e.dx).reduce((a, b) => a < b ? a : b);
      final maxX =
          positions.skip(1).map((e) => e.dx).reduce((a, b) => a > b ? a : b);
      canvas.drawLine(Offset(minX, splitY), Offset(maxX, splitY), basePaint);
      for (final target in positions.skip(1)) {
        canvas.drawLine(
          Offset(target.dx, splitY),
          Offset(target.dx, target.dy - size.height * 0.08),
          basePaint,
        );
      }
    }

    for (var i = 0; i < overviewPaths.length; i++) {
      final exercises = exercisesForPath(overviewPaths[i]);
      final pathCenter = positions[i];
      final pathPoints = <Offset>[];
      for (var j = 0; j < exercises.length; j++) {
        final t = exercises.length == 1 ? 0.5 : j / (exercises.length - 1);
        final x = pathCenter.dx;
        final y = pathCenter.dy +
            size.height * 0.07 -
            t * size.height * (i == 0 ? 0.22 : 0.17);
        pathPoints.add(Offset(x, y));
      }

      for (var j = 0; j < pathPoints.length - 1; j++) {
        final current = progressMap[exercises[j].id] ?? ExerciseStatus.inactive;
        final next =
            progressMap[exercises[j + 1].id] ?? ExerciseStatus.inactive;
        final lit = current != ExerciseStatus.inactive ||
            next != ExerciseStatus.inactive;
        final paint = Paint()
          ..color = lit
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = i == 0 ? 2.2 : 1.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(pathPoints[j], pathPoints[j + 1], paint);
      }

      for (var j = 0; j < pathPoints.length; j++) {
        final status = progressMap[exercises[j].id] ?? ExerciseStatus.inactive;
        final point = pathPoints[j];
        switch (status) {
          case ExerciseStatus.mastered:
            canvas.drawCircle(
              point,
              i == 0 ? 5.4 : 4.4,
              Paint()..color = Colors.white.withValues(alpha: 0.25),
            );
            canvas.drawCircle(
                point, i == 0 ? 2.8 : 2.4, Paint()..color = Colors.white);
          case ExerciseStatus.active:
            canvas.drawCircle(
              point,
              i == 0 ? 4.8 : 4,
              Paint()..color = AppColors.accentBright.withValues(alpha: 0.22),
            );
            canvas.drawCircle(
              point,
              i == 0 ? 2.5 : 2.1,
              Paint()..color = AppColors.accentBright,
            );
          case ExerciseStatus.inactive:
            canvas.drawCircle(
              point,
              i == 0 ? 2.4 : 2,
              Paint()..color = Colors.white.withValues(alpha: 0.3),
            );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryConstellationPainter oldDelegate) {
    return oldDelegate.overviewPaths != overviewPaths ||
        oldDelegate.progressMap != progressMap;
  }
}

List<Offset> _previewOverviewPositions(int count) {
  switch (count) {
    case 1:
      return const [Offset(0.5, 0.68)];
    case 2:
      return const [Offset(0.5, 0.44), Offset(0.5, 0.8)];
    case 3:
      return const [Offset(0.5, 0.34), Offset(0.28, 0.82), Offset(0.72, 0.82)];
    case 4:
      return const [
        Offset(0.5, 0.3),
        Offset(0.18, 0.82),
        Offset(0.5, 0.82),
        Offset(0.82, 0.82),
      ];
    default:
      return const [
        Offset(0.5, 0.26),
        Offset(0.1, 0.82),
        Offset(0.36, 0.82),
        Offset(0.64, 0.82),
        Offset(0.9, 0.82),
      ];
  }
}
