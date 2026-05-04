import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import 'widgets/exercise_node.dart';
import 'widgets/skill_tree_painter.dart';

const _masteredColor = Color(0xFF4CAF50);

class SkillTreeView extends StatefulWidget {
  final String skillCategoryId;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(String exerciseId, ExerciseStatus status)
      onProgressChanged;

  const SkillTreeView({
    super.key,
    required this.skillCategoryId,
    required this.progressMap,
    required this.onProgressChanged,
  });

  @override
  State<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends State<SkillTreeView> {
  final _progressService = ProgressService();
  final _horizontalScrollController = ScrollController();
  late SkillCategory _skillCategory;
  late Map<String, ExerciseStatus> _localProgress;
  late List<Exercise> _exercises;
  bool _didAlignInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _skillCategory = SkillCategoryCatalog.findById(widget.skillCategoryId) ??
        SkillCategoryCatalog.defaultForTrack(ExerciseCategory.verticalPull);
    _exercises = ExerciseCatalog.forSkillCategory(_skillCategory.id);
    _localProgress = Map.from(widget.progressMap);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Pre-compute grid positions for every exercise node.
  Map<String, Offset> _computePositions(double availableWidth) {
    final positions = <String, Offset>{};
    const vSpacing = 44.0;
    const vPadding = 24.0;
    final laneMap = {
      for (final branch in _skillCategory.branches) branch.id: branch.lane,
    };
    final lanes = laneMap.values.toSet().toList()..sort();
    const hPadding = kNodeWidth / 2 + 24;
    final usable = availableWidth - hPadding * 2;
    final laneToX = <int, double>{};

    for (int i = 0; i < lanes.length; i++) {
      final x = lanes.length == 1
          ? availableWidth / 2
          : hPadding + (usable / (lanes.length - 1)) * i;
      laneToX[lanes[i]] = x;
    }

    for (final exercise in _exercises) {
      final lane = laneMap[exercise.branchId] ?? 0;
      final x = laneToX[lane] ?? availableWidth / 2;
      final y = vPadding +
          exercise.treeOrder * (kNodeHeight + vSpacing) +
          kNodeHeight / 2;
      positions[exercise.id] = Offset(x, y);
    }

    return positions;
  }

  double _treeWidth(double availableWidth) {
    final laneCount =
        _skillCategory.branches.map((branch) => branch.lane).toSet().length;
    final minWidth = laneCount * kNodeWidth + (laneCount - 1) * 56 + 96;
    return minWidth > availableWidth ? minWidth : availableWidth;
  }

  void _ensureInitialHorizontalAlignment({
    required double viewportWidth,
    required Map<String, Offset> positions,
  }) {
    if (_didAlignInitialScroll || !_horizontalScrollController.hasClients) {
      return;
    }

    final mainExercise = _exercises.firstWhere(
      (exercise) => exercise.branchId == 'main',
      orElse: () => _exercises.first,
    );
    final mainPosition = positions[mainExercise.id];
    if (mainPosition == null) return;

    final targetOffset = (mainPosition.dx - viewportWidth / 2).clamp(
      0.0,
      _horizontalScrollController.position.maxScrollExtent,
    );
    _horizontalScrollController.jumpTo(targetOffset);
    _didAlignInitialScroll = true;
  }

  double _totalHeight() {
    final levels = <int>{};
    for (final e in _exercises) {
      levels.add(e.treeOrder);
    }
    if (levels.isEmpty) return 300;
    const vSpacing = 44.0;
    const vPadding = 24.0;
    return vPadding * 2 +
        levels.length * kNodeHeight +
        (levels.length - 1) * vSpacing;
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
    final unlockRequirement = _skillCategory.unlockRequirement;
    final isLocked = unlockRequirement != null &&
        (_localProgress[unlockRequirement.exerciseId] ??
                ExerciseStatus.inactive) ==
            ExerciseStatus.inactive;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          _skillCategory.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final treeWidth = _treeWidth(viewportWidth);
          final positions = _computePositions(treeWidth);
          final height = _totalHeight();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _ensureInitialHorizontalAlignment(
              viewportWidth: viewportWidth,
              positions: positions,
            );
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryHero(
                  category: _skillCategory,
                  mastered: _exercises
                      .where(
                        (exercise) =>
                            _localProgress[exercise.id] ==
                            ExerciseStatus.mastered,
                      )
                      .length,
                  total: _exercises.length,
                  isLocked: isLocked,
                  lockMessage: unlockRequirement?.message,
                  onOpenRequiredTree: unlockRequirement == null
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SkillTreeView(
                                skillCategoryId:
                                    unlockRequirement.targetSkillCategoryId,
                                progressMap: _localProgress,
                                onProgressChanged: (id, status) {
                                  setState(() => _localProgress[id] = status);
                                  widget.onProgressChanged(id, status);
                                },
                              ),
                            ),
                          );
                        },
                  lockCtaLabel: unlockRequirement?.ctaLabel,
                ),
                const SizedBox(height: 20),
                AbsorbPointer(
                  absorbing: isLocked,
                  child: Opacity(
                    opacity: isLocked ? 0.45 : 1,
                    child: ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        scrollbars: true,
                      ),
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: treeWidth,
                          height: height,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(treeWidth, height),
                                painter: SkillTreePainter(
                                  exercises: _exercises,
                                  nodePositions: positions,
                                  progressMap: _localProgress,
                                ),
                              ),
                              for (final exercise in _exercises)
                                if (positions.containsKey(exercise.id))
                                  Positioned(
                                    left: positions[exercise.id]!.dx -
                                        kNodeWidth / 2,
                                    top: positions[exercise.id]!.dy -
                                        kNodeHeight / 2,
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryHero extends StatelessWidget {
  final SkillCategory category;
  final int mastered;
  final int total;
  final bool isLocked;
  final String? lockMessage;
  final String? lockCtaLabel;
  final VoidCallback? onOpenRequiredTree;

  const _CategoryHero({
    required this.category,
    required this.mastered,
    required this.total,
    this.isLocked = false,
    this.lockMessage,
    this.lockCtaLabel,
    this.onOpenRequiredTree,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category.title} · ${category.subtitle}',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (isLocked) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x14FF8904),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Locked',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentBright,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lockMessage ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onOpenRequiredTree,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentBright,
                      side: BorderSide(
                        color: AppColors.accentPrimary.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      lockCtaLabel ?? 'Open Required Tree',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '$mastered / $total mastered',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
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
      case ExerciseStatus.inactive:
        return 'Inactive';
      case ExerciseStatus.active:
        return 'Active';
      case ExerciseStatus.mastered:
        return 'Mastered';
    }
  }

  Color get _color {
    switch (status) {
      case ExerciseStatus.inactive:
        return AppColors.textMuted;
      case ExerciseStatus.active:
        return AppColors.accentBright;
      case ExerciseStatus.mastered:
        return _masteredColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? _color.withValues(alpha: 0.15) : Colors.transparent,
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
