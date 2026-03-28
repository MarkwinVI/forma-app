import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import 'widgets/exercise_node.dart';
import 'widgets/skill_tree_painter.dart';

const _masteredColor = Color(0xFF4CAF50);

class SkillTreeView extends StatefulWidget {
  final ExerciseCategory category;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(String exerciseId, ExerciseStatus status) onProgressChanged;

  const SkillTreeView({
    super.key,
    required this.category,
    required this.progressMap,
    required this.onProgressChanged,
  });

  @override
  State<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends State<SkillTreeView> {
  final _progressService = ProgressService();
  late Map<String, ExerciseStatus> _localProgress;
  late List<Exercise> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = ExerciseCatalog.forCategory(widget.category);
    _localProgress = Map.from(widget.progressMap);
  }

  // Pre-compute grid positions for every exercise node.
  Map<String, Offset> _computePositions(double availableWidth) {
    final Map<int, List<Exercise>> levels = {};
    for (final e in _exercises) {
      levels.putIfAbsent(e.treeOrder, () => []).add(e);
    }

    final sortedKeys = levels.keys.toList()..sort();
    final positions = <String, Offset>{};
    const nodeSize  = kNodeSize;
    const vSpacing  = 60.0;
    const vPadding  = 40.0;
    const hPadding  = 24.0;

    for (int li = 0; li < sortedKeys.length; li++) {
      final exs = levels[sortedKeys[li]]!;
      final n   = exs.length;
      final usable = availableWidth - hPadding * 2 - nodeSize;

      for (int i = 0; i < n; i++) {
        final x = n == 1
            ? availableWidth / 2
            : hPadding + nodeSize / 2 + (n > 1 ? usable / (n - 1) * i : 0);
        final y = vPadding + li * (nodeSize + vSpacing) + nodeSize / 2;
        positions[exs[i].id] = Offset(x, y);
      }
    }
    return positions;
  }

  double _totalHeight() {
    final levels = <int>{};
    for (final e in _exercises) levels.add(e.treeOrder);
    if (levels.isEmpty) return 300;
    const nodeSize = kNodeSize;
    const vSpacing = 60.0;
    const vPadding = 40.0;
    return vPadding * 2 + levels.length * nodeSize + (levels.length - 1) * vSpacing;
  }

  Future<void> _updateStatus(Exercise exercise, ExerciseStatus status) async {
    setState(() => _localProgress[exercise.id] = status);
    widget.onProgressChanged(exercise.id, status);
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    await _progressService.upsert(userId, exercise.id, status);
  }

  void _showExerciseSheet(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _ExerciseSheet(
        exercise: exercise,
        status: _localProgress[exercise.id] ?? ExerciseStatus.inactive,
        onStatusChanged: (s) => _updateStatus(exercise, s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          widget.category.label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width     = constraints.maxWidth;
          final positions = _computePositions(width);
          final height    = _totalHeight();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(width, height),
                    painter: SkillTreePainter(
                      exercises: _exercises,
                      nodePositions: positions,
                      progressMap: _localProgress,
                    ),
                  ),
                  for (final exercise in _exercises)
                    if (positions.containsKey(exercise.id))
                      Positioned(
                        left: positions[exercise.id]!.dx - kNodeSize / 2,
                        top:  positions[exercise.id]!.dy - kNodeSize / 2,
                        child: ExerciseNode(
                          exercise: exercise,
                          status: _localProgress[exercise.id] ??
                              ExerciseStatus.inactive,
                          onTap: () => _showExerciseSheet(exercise),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseSheet extends StatelessWidget {
  final Exercise exercise;
  final ExerciseStatus status;
  final void Function(ExerciseStatus) onStatusChanged;

  const _ExerciseSheet({
    required this.exercise,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _DifficultyDots(difficulty: exercise.difficulty),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exercise.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'STATUS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ExerciseStatus.values
                .map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _StatusChip(
                          status: s,
                          isSelected: status == s,
                          onTap: () {
                            onStatusChanged(s);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  final int difficulty;
  const _DifficultyDots({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < difficulty
                ? AppColors.accentPrimary
                : AppColors.borderPrimary,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ExerciseStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (status) {
      case ExerciseStatus.inactive: return 'Inactive';
      case ExerciseStatus.active:   return 'Active';
      case ExerciseStatus.mastered: return 'Mastered';
    }
  }

  Color get _color {
    switch (status) {
      case ExerciseStatus.inactive: return AppColors.textMuted;
      case ExerciseStatus.active:   return AppColors.accentBright;
      case ExerciseStatus.mastered: return _masteredColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _color : AppColors.borderPrimary,
          ),
        ),
        child: Center(
          child: Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? _color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
