import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/skill_category_model.dart';

class CategoryProgressCard extends StatelessWidget {
  final SkillCategory category;
  final bool isLocked;
  final Map<String, ExerciseStatus> progressMap;
  final VoidCallback onTap;

  const CategoryProgressCard({
    super.key,
    required this.category,
    required this.isLocked,
    required this.progressMap,
    required this.onTap,
  });

  String? get _eyebrow => isLocked ? 'LOCKED' : null;

  @override
  Widget build(BuildContext context) {
    final isLongTitle = category.title.length >= 16;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 14),
                spreadRadius: -12,
              ),
            ],
          ),
          child: SizedBox(
            height: 156,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_eyebrow != null)
                          Text(
                            _eyebrow!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppColors.textMuted,
                            ),
                          ),
                        if (_eyebrow != null) const SizedBox(height: 8),
                        Text(
                          category.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: isLongTitle ? 24 : 28,
                            height: isLongTitle ? 0.98 : 0.94,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          category.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 162,
                  height: double.infinity,
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(24),
                    ),
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          child: _CategoryConstellationPreview(
                            category: category,
                            progressMap: progressMap,
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

class _CategoryConstellationPreview extends StatelessWidget {
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;

  const _CategoryConstellationPreview({
    required this.category,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackTreePreviewPainter(
        category: category,
        progressMap: progressMap,
      ),
    );
  }
}

class _TrackTreePreviewPainter extends CustomPainter {
  final SkillCategory category;
  final Map<String, ExerciseStatus> progressMap;

  const _TrackTreePreviewPainter({
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
    if (category.trainingPaths.isEmpty) {
      return ExerciseCatalog.forSkillCategory(category.id);
    }

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
  void paint(Canvas canvas, Size size) {
    final overviewPaths =
        _hasFoundation ? ['__foundation__', ..._realPathIds] : _realPathIds;
    final branchCount =
        _hasFoundation ? overviewPaths.length - 1 : overviewPaths.length;
    final fork = Offset(
      size.width / 2,
      _hasFoundation ? size.height * 0.38 : size.height * 0.18,
    );
    final tips = _previewTips(
      size: size,
      branchCount: branchCount,
      hasFoundation: _hasFoundation,
    );

    final pathLayouts = <_PreviewPathLayout>[];
    var branchIndex = 0;
    for (final pathId in overviewPaths) {
      final exercises = _exercisesForPath(pathId);
      if (_hasFoundation && pathId == '__foundation__') {
        pathLayouts.add(
          _PreviewPathLayout(
            id: pathId,
            exercises: exercises,
            nodes: _linearOffsets(
              start: Offset(size.width / 2, size.height * 0.04),
              end: fork,
              count: exercises.length,
            ),
            isFoundation: true,
          ),
        );
      } else {
        pathLayouts.add(
          _PreviewPathLayout(
            id: pathId,
            exercises: exercises,
            nodes: _branchLinearOffsets(
              start: fork,
              end: tips[branchIndex++],
              count: exercises.length,
            ),
            isFoundation: false,
          ),
        );
      }
    }

    for (final layout in pathLayouts) {
      if (layout.nodes.isEmpty) continue;
      if (layout.isFoundation) {
        for (var i = 0; i < layout.nodes.length - 1; i++) {
          _drawPreviewSegment(
            canvas,
            layout.nodes[i],
            layout.nodes[i + 1],
            progressMap[layout.exercises[i].id] ?? ExerciseStatus.inactive,
            progressMap[layout.exercises[i + 1].id] ?? ExerciseStatus.inactive,
          );
        }
      } else {
        _drawPreviewSegment(
          canvas,
          fork,
          layout.nodes.first,
          progressMap[layout.exercises.first.id] ?? ExerciseStatus.inactive,
          progressMap[layout.exercises.first.id] ?? ExerciseStatus.inactive,
        );
        for (var i = 0; i < layout.nodes.length - 1; i++) {
          _drawPreviewSegment(
            canvas,
            layout.nodes[i],
            layout.nodes[i + 1],
            progressMap[layout.exercises[i].id] ?? ExerciseStatus.inactive,
            progressMap[layout.exercises[i + 1].id] ?? ExerciseStatus.inactive,
          );
        }
      }
    }

    for (final layout in pathLayouts) {
      final nodeCount =
          layout.isFoundation ? layout.nodes.length - 1 : layout.nodes.length;
      for (var i = 0; i < nodeCount; i++) {
        _drawPreviewNode(
          canvas,
          layout.nodes[i],
          progressMap[layout.exercises[i].id] ?? ExerciseStatus.inactive,
          radius: layout.isFoundation ? 2.15 : 1.95,
        );
      }
    }

    if (_hasFoundation) {
      final foundation = pathLayouts.firstWhere(
        (layout) => layout.id == '__foundation__',
      );
      if (foundation.exercises.isNotEmpty) {
        _drawPreviewNode(
          canvas,
          fork,
          progressMap[foundation.exercises.last.id] ?? ExerciseStatus.inactive,
          radius: 2.4,
          doubleRing: true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrackTreePreviewPainter oldDelegate) {
    return oldDelegate.progressMap != progressMap ||
        oldDelegate.category != category;
  }
}

class _PreviewPathLayout {
  final String id;
  final List<Exercise> exercises;
  final List<Offset> nodes;
  final bool isFoundation;

  const _PreviewPathLayout({
    required this.id,
    required this.exercises,
    required this.nodes,
    required this.isFoundation,
  });
}

List<Offset> _previewTips({
  required Size size,
  required int branchCount,
  required bool hasFoundation,
}) {
  List<Offset> normalized;
  if (hasFoundation) {
    switch (branchCount) {
      case 1:
        normalized = const [Offset(0.5, 0.88)];
      case 2:
        normalized = const [Offset(0.18, 0.86), Offset(0.82, 0.86)];
      case 3:
        normalized = const [
          Offset(0.16, 0.78),
          Offset(0.84, 0.78),
          Offset(0.5, 0.96),
        ];
      default:
        normalized = const [
          Offset(0.14, 0.74),
          Offset(0.86, 0.74),
          Offset(0.28, 0.97),
          Offset(0.72, 0.97),
        ];
    }
  } else {
    switch (branchCount) {
      case 1:
        normalized = const [Offset(0.5, 0.9)];
      case 2:
        normalized = const [Offset(0.18, 0.88), Offset(0.82, 0.88)];
      case 3:
        normalized = const [
          Offset(0.16, 0.8),
          Offset(0.84, 0.8),
          Offset(0.5, 0.98),
        ];
      default:
        normalized = const [
          Offset(0.14, 0.76),
          Offset(0.86, 0.76),
          Offset(0.28, 0.98),
          Offset(0.72, 0.98),
        ];
    }
  }

  return normalized
      .map((offset) => Offset(offset.dx * size.width, offset.dy * size.height))
      .toList();
}

List<Offset> _linearOffsets({
  required Offset start,
  required Offset end,
  required int count,
}) {
  if (count <= 0) return const [];
  if (count == 1) return [Offset.lerp(start, end, 0.5)!];
  return [
    for (var i = 0; i < count; i++) Offset.lerp(start, end, i / (count - 1))!,
  ];
}

List<Offset> _branchLinearOffsets({
  required Offset start,
  required Offset end,
  required int count,
}) {
  if (count <= 0) return const [];
  return [
    for (var i = 0; i < count; i++) Offset.lerp(start, end, (i + 1) / count)!,
  ];
}

const _kMastered = Color(0xFF4CAF50);

void _drawPreviewSegment(
  Canvas canvas,
  Offset a,
  Offset b,
  ExerciseStatus statusA,
  ExerciseStatus statusB,
) {
  final isCurrent = statusB == ExerciseStatus.active;
  final isLit =
      statusA == ExerciseStatus.mastered && statusB == ExerciseStatus.mastered;

  final Color color;
  final double opacity;
  final double strokeWidth;

  if (isCurrent) {
    color = AppColors.accentBright;
    opacity = 0.5;
    strokeWidth = 1.1;
  } else if (isLit) {
    color = _kMastered;
    opacity = 0.75;
    strokeWidth = 1.35;
  } else {
    color = Colors.white;
    opacity = 0.10;
    strokeWidth = 0.8;
  }

  final paint = Paint()
    ..color = color.withValues(alpha: opacity)
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = false;

  if (isCurrent) {
    _drawDashedLine(canvas, _snapOffset(a), _snapOffset(b), paint, 4.0, 5.0);
  } else {
    canvas.drawLine(_snapOffset(a), _snapOffset(b), paint);
  }
}

void _drawDashedLine(
  Canvas canvas,
  Offset a,
  Offset b,
  Paint paint,
  double dashLen,
  double gapLen,
) {
  final delta = b - a;
  final total = delta.distance;
  if (total == 0) return;
  final dir = delta / total;
  var pos = 0.0;
  while (pos < total) {
    final end = (pos + dashLen).clamp(0.0, total);
    canvas.drawLine(a + dir * pos, a + dir * end, paint);
    pos += dashLen + gapLen;
  }
}

void _drawPreviewNode(
  Canvas canvas,
  Offset center,
  ExerciseStatus status, {
  required double radius,
  bool doubleRing = false,
}) {
  final color = switch (status) {
    ExerciseStatus.inactive => AppColors.textMuted,
    ExerciseStatus.active => AppColors.accentBright,
    ExerciseStatus.mastered => _kMastered,
  };
  final snappedCenter = _snapOffset(center);

  // Outer ring.
  canvas.drawCircle(
    snappedCenter,
    radius * 1.65,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = false
      ..color = color.withValues(
        alpha: status == ExerciseStatus.inactive ? 0.18 : 0.35,
      ),
  );

  // Second ring on fork checkpoint node.
  if (doubleRing) {
    canvas.drawCircle(
      snappedCenter,
      radius * 2.45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..isAntiAlias = false
        ..color = color.withValues(alpha: 0.25),
    );
  }

  // Solid dot.
  canvas.drawCircle(
    snappedCenter,
    radius,
    Paint()
      ..color = color
      ..isAntiAlias = false,
  );
}

Offset _snapOffset(Offset offset) {
  double snap(double value) => value.roundToDouble() + 0.5;
  return Offset(snap(offset.dx), snap(offset.dy));
}
