import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import '../exercises/exercise_detail_view.dart';

const _masteredColor = Color(0xFF4CAF50);
const _surfaceShadow = Color(0x1A000000);
const _foundationPathId = '__foundation__';

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
  late SkillCategory _skillCategory;
  late Map<String, ExerciseStatus> _localProgress;
  late List<Exercise> _exercises;
  late String _selectedPathId;
  late bool _showBranchOverview;

  @override
  void initState() {
    super.initState();
    _skillCategory = SkillCategoryCatalog.findById(widget.skillCategoryId) ??
        SkillCategoryCatalog.defaultForTrack(ExerciseCategory.verticalPull);
    _exercises = ExerciseCatalog.forSkillCategory(_skillCategory.id);
    _localProgress = Map.from(widget.progressMap);
    final pathIds = _pathIds;
    _selectedPathId = _hasFoundationPath
        ? _foundationPathId
        : pathIds.contains(_skillCategory.defaultTrainingPathId)
            ? _skillCategory.defaultTrainingPathId
            : pathIds.first;
    _showBranchOverview = pathIds.length > 1;
  }

  List<String> get _pathIds {
    if (_skillCategory.trainingPaths.isNotEmpty) {
      final ids = _skillCategory.trainingPaths.keys.toList();
      if (_hasFoundationPath) {
        return [_foundationPathId, ...ids];
      }
      return ids;
    }
    return const ['main'];
  }

  List<String> get _realPathIds {
    if (_skillCategory.trainingPaths.isNotEmpty) {
      return _skillCategory.trainingPaths.keys.toList();
    }
    return const ['main'];
  }

  List<String> get _sharedFoundationExerciseIds {
    if (_realPathIds.length < 2) return const [];
    final lists = _realPathIds
        .map((pathId) =>
            _skillCategory.trainingPaths[pathId] ?? const <String>[])
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

  bool get _hasFoundationPath => _sharedFoundationExerciseIds.isNotEmpty;

  bool _isFoundationPath(String pathId) => pathId == _foundationPathId;

  String _pathLabel(String pathId) {
    if (_isFoundationPath(pathId)) return 'Foundation';
    if (_skillCategory.id == SkillCategoryCatalog.pullupsId &&
        pathId == 'close_grip') {
      return 'High Pull-up';
    }

    for (final branch in _skillCategory.branches) {
      if (branch.id == pathId) return branch.label;
    }

    return pathId
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<Exercise> _exercisesForPath(String pathId) {
    if (_skillCategory.trainingPaths.isEmpty) return _exercises;

    if (_isFoundationPath(pathId)) {
      return _sharedFoundationExerciseIds
          .map(ExerciseCatalog.findById)
          .whereType<Exercise>()
          .toList();
    }

    final raw = _skillCategory.trainingPaths[pathId] ?? const <String>[];
    final visibleIds = _hasFoundationPath
        ? raw.skip(_sharedFoundationExerciseIds.length).toList()
        : raw;

    return visibleIds
        .map(ExerciseCatalog.findById)
        .whereType<Exercise>()
        .toList();
  }

  int _pathUnlockedCount(String pathId) {
    return _exercisesForPath(pathId)
        .where(
          (exercise) =>
              (_localProgress[exercise.id] ?? ExerciseStatus.inactive) !=
              ExerciseStatus.inactive,
        )
        .length;
  }

  int _pathMasteredCount(String pathId) {
    return _exercisesForPath(pathId)
        .where(
          (exercise) =>
              (_localProgress[exercise.id] ?? ExerciseStatus.inactive) ==
              ExerciseStatus.mastered,
        )
        .length;
  }

  double _pathProgress(String pathId) {
    final total = _exercisesForPath(pathId).length;
    if (total == 0) return 0;
    return _pathUnlockedCount(pathId) / total;
  }

  Future<void> _updateStatus(Exercise exercise, ExerciseStatus status) async {
    setState(() => _localProgress[exercise.id] = status);
    widget.onProgressChanged(exercise.id, status);
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    await _progressService.upsert(userId, exercise.id, status);
  }

  void _showExerciseSheet(Exercise exercise) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => _ExercisePreviewSheet(
        exercise: exercise,
        skillCategoryId: _skillCategory.id,
        initialStatus: _localProgress[exercise.id] ?? ExerciseStatus.inactive,
        onStatusChanged: (status) => _updateStatus(exercise, status),
        onLearnMore: () {
          Navigator.of(sheetContext).pop();
          openExerciseDetailView<void>(
            context,
            exercise: exercise,
            skillCategoryId: _skillCategory.id,
          );
        },
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
    final hasBranchOverview = _pathIds.length > 1;
    final pathExercises = _exercisesForPath(_selectedPathId);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        automaticallyImplyLeading:
            hasBranchOverview ? _showBranchOverview : true,
        leading: hasBranchOverview && !_showBranchOverview
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _showBranchOverview = true),
              )
            : null,
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: AppColors.bgSecondary,
        title: Text(
          _showBranchOverview || !hasBranchOverview
              ? '${_skillCategory.title} progression'
              : _pathLabel(_selectedPathId),
          style: GoogleFonts.lato(
            fontSize: _showBranchOverview || !hasBranchOverview ? 24 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLocked) ...[
              _LockNotice(
                message: unlockRequirement.message,
                ctaLabel: unlockRequirement.ctaLabel,
                onOpenRequiredTree: () async {
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
              ),
              const SizedBox(height: 16),
            ],
            AbsorbPointer(
              absorbing: isLocked,
              child: Opacity(
                opacity: isLocked ? 0.45 : 1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _showBranchOverview && hasBranchOverview
                      ? _BranchOverviewPanel(
                          key: ValueKey('overview-${_skillCategory.id}'),
                          skillCategory: _skillCategory,
                          foundationPathId:
                              _hasFoundationPath ? _foundationPathId : null,
                          pathIds: _hasFoundationPath ? _realPathIds : _pathIds,
                          selectedPathId: _selectedPathId,
                          labelBuilder: _pathLabel,
                          badgeBuilder: _pathBadge,
                          accentBuilder: _pathAccent,
                          progressBuilder: _pathProgress,
                          unlockedCountBuilder: _pathUnlockedCount,
                          masteredCountBuilder: _pathMasteredCount,
                          totalCountBuilder: (pathId) =>
                              _exercisesForPath(pathId).length,
                          exercisesForPathBuilder: _exercisesForPath,
                          progressMap: _localProgress,
                          onOpenPath: (pathId) {
                            setState(() {
                              _selectedPathId = pathId;
                              _showBranchOverview = false;
                            });
                          },
                        )
                      : Column(
                          key: ValueKey(
                              'path-${_skillCategory.id}-$_selectedPathId'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (hasBranchOverview)
                              _SelectedPathHeader(
                                label: _pathLabel(_selectedPathId),
                                badge: _pathBadge(_selectedPathId),
                                accentColor: _pathAccent(_selectedPathId),
                                unlocked: _pathUnlockedCount(_selectedPathId),
                                total:
                                    _exercisesForPath(_selectedPathId).length,
                                onViewBranches: () =>
                                    setState(() => _showBranchOverview = true),
                              ),
                            if (hasBranchOverview) const SizedBox(height: 18),
                            if (hasBranchOverview &&
                                _hasFoundationPath &&
                                !_isFoundationPath(_selectedPathId))
                              _FoundationHintCard(
                                accentColor: _pathAccent(_foundationPathId),
                                onOpenFoundation: () {
                                  setState(() {
                                    _selectedPathId = _foundationPathId;
                                  });
                                },
                              ),
                            if (hasBranchOverview &&
                                _hasFoundationPath &&
                                !_isFoundationPath(_selectedPathId))
                              const SizedBox(height: 18),
                            _PathTimeline(
                              accentColor: _pathAccent(_selectedPathId),
                              exercises: pathExercises,
                              progressMap: _localProgress,
                              onExerciseTap: _showExerciseSheet,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _pathBadge(String pathId) {
    if (_isFoundationPath(pathId)) {
      return 'Start Here';
    }
    if (pathId == _skillCategory.defaultTrainingPathId) {
      return 'Default';
    }

    for (final branch in _skillCategory.branches) {
      if (branch.id == pathId && branch.isRecommended) {
        return 'Popular';
      }
    }

    return null;
  }

  Color _pathAccent(String pathId) {
    if (_isFoundationPath(pathId)) {
      return const Color(0xFF2AE68B);
    }
    switch (pathId) {
      case 'weighted':
        return const Color(0xFFE0A11C);
      case 'one_arm':
        return const Color(0xFF6A5AE0);
      case 'close_grip':
        return const Color(0xFF1A9AD6);
      case 'l_sit':
        return const Color(0xFF22B8A2);
      case 'rings':
        return const Color(0xFF3E82F7);
      case 'planche':
        return const Color(0xFFC46D2D);
      case 'front_lever':
        return const Color(0xFFB95D2B);
      case 'pistol':
        return const Color(0xFF2AE68B);
      case 'shrimp':
        return const Color(0xFF82A84E);
      default:
        return const Color(0xFF17A4EB);
    }
  }
}

class _SelectedPathHeader extends StatelessWidget {
  final String label;
  final String? badge;
  final Color accentColor;
  final int unlocked;
  final int total;
  final VoidCallback onViewBranches;

  const _SelectedPathHeader({
    required this.label,
    required this.badge,
    required this.accentColor,
    required this.unlocked,
    required this.total,
    required this.onViewBranches,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: _surfaceShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                if (badge != null) const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unlocked of $total steps unlocked',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onViewBranches,
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: accentColor.withValues(alpha: 0.24)),
              ),
            ),
            icon: const Icon(Icons.account_tree_outlined, size: 18),
            label: Text(
              'All branches',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundationHintCard extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onOpenFoundation;

  const _FoundationHintCard({
    required this.accentColor,
    required this.onOpenFoundation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'After foundation',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This branch comes after the shared foundation progression.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onOpenFoundation,
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: accentColor.withValues(alpha: 0.24)),
              ),
            ),
            child: Text(
              'Open foundation',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchOverviewPanel extends StatelessWidget {
  final SkillCategory skillCategory;
  final String? foundationPathId;
  final List<String> pathIds;
  final String selectedPathId;
  final String Function(String pathId) labelBuilder;
  final String? Function(String pathId) badgeBuilder;
  final Color Function(String pathId) accentBuilder;
  final double Function(String pathId) progressBuilder;
  final int Function(String pathId) unlockedCountBuilder;
  final int Function(String pathId) masteredCountBuilder;
  final int Function(String pathId) totalCountBuilder;
  final List<Exercise> Function(String pathId) exercisesForPathBuilder;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(String pathId) onOpenPath;

  const _BranchOverviewPanel({
    super.key,
    required this.skillCategory,
    required this.foundationPathId,
    required this.pathIds,
    required this.selectedPathId,
    required this.labelBuilder,
    required this.badgeBuilder,
    required this.accentBuilder,
    required this.progressBuilder,
    required this.unlockedCountBuilder,
    required this.masteredCountBuilder,
    required this.totalCountBuilder,
    required this.exercisesForPathBuilder,
    required this.progressMap,
    required this.onOpenPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasFoundation = foundationPathId != null;
    final overviewPaths =
        hasFoundation ? [foundationPathId!, ...pathIds] : pathIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasFoundation ? 'Choose a branch' : 'Choose a path',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasFoundation
              ? 'Begin at the shared foundation, then choose one of the linked specialization branches.'
              : 'Choose the linked path you want to train.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth;
            final layout = _buildBranchOverviewLayout(
              viewportWidth: viewportWidth,
              pathCount: overviewPaths.length,
              hasFoundation: hasFoundation,
            );

            return SizedBox(
              width: viewportWidth,
              height: layout.panelHeight,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(viewportWidth, layout.panelHeight),
                    painter: _ConstellationPainter(
                      hasFoundation: hasFoundation,
                      start: layout.connectorStart,
                      targets: hasFoundation
                          ? layout.cardPoints.skip(1).toList()
                          : layout.cardPoints,
                      targetColors: [
                        for (final pathId in hasFoundation
                            ? overviewPaths.skip(1)
                            : overviewPaths)
                          accentBuilder(pathId),
                      ],
                    ),
                  ),
                  for (var i = 0; i < overviewPaths.length; i++)
                    Positioned(
                      left: layout.cardPoints[i].dx - (_branchNodeWidth / 2),
                      top: layout.cardPoints[i].dy - (_branchNodeHeight / 2),
                      child: _BranchConstellationNode(
                        width: _branchNodeWidth,
                        label: labelBuilder(overviewPaths[i]),
                        badge: badgeBuilder(overviewPaths[i]),
                        accentColor: accentBuilder(overviewPaths[i]),
                        isSelected: overviewPaths[i] == selectedPathId,
                        progress: progressBuilder(overviewPaths[i]),
                        unlocked: unlockedCountBuilder(overviewPaths[i]),
                        total: totalCountBuilder(overviewPaths[i]),
                        exercises: exercisesForPathBuilder(overviewPaths[i]),
                        progressMap: progressMap,
                        isFoundation: i == 0 && hasFoundation,
                        onTap: () => onOpenPath(overviewPaths[i]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

const _branchNodeWidth = 128.0;
const _branchNodeHeight = 216.0;

_BranchOverviewLayout _buildBranchOverviewLayout({
  required double viewportWidth,
  required int pathCount,
  required bool hasFoundation,
}) {
  final branchCount = hasFoundation ? pathCount - 1 : pathCount;
  final cardPoints = <Offset>[];
  final connectorStart = Offset(viewportWidth / 2, hasFoundation ? 112 : 72);
  final twoColumnLeft = viewportWidth * 0.27;
  final twoColumnRight = viewportWidth * 0.73;
  final oneColumnCenter = viewportWidth * 0.5;

  if (hasFoundation) {
    cardPoints.add(Offset(viewportWidth / 2, 112));
  }

  if (branchCount == 1) {
    cardPoints.add(Offset(oneColumnCenter, hasFoundation ? 388 : 160));
  } else if (branchCount == 2) {
    cardPoints.addAll([
      Offset(twoColumnLeft, hasFoundation ? 388 : 160),
      Offset(twoColumnRight, hasFoundation ? 388 : 160),
    ]);
  } else if (branchCount == 3) {
    cardPoints.addAll([
      Offset(twoColumnLeft, hasFoundation ? 388 : 160),
      Offset(twoColumnRight, hasFoundation ? 388 : 160),
      Offset(oneColumnCenter, hasFoundation ? 636 : 412),
    ]);
  } else if (branchCount >= 4) {
    cardPoints.addAll([
      Offset(twoColumnLeft, hasFoundation ? 388 : 160),
      Offset(twoColumnRight, hasFoundation ? 388 : 160),
      Offset(twoColumnLeft, hasFoundation ? 636 : 412),
      Offset(twoColumnRight, hasFoundation ? 636 : 412),
    ]);
  }

  final panelHeight = hasFoundation
      ? (branchCount >= 3 ? 752.0 : 520.0)
      : (branchCount >= 3 ? 548.0 : 296.0);

  return _BranchOverviewLayout(
    connectorStart: connectorStart,
    panelHeight: panelHeight,
    cardPoints: cardPoints,
  );
}

class _BranchOverviewLayout {
  final Offset connectorStart;
  final double panelHeight;
  final List<Offset> cardPoints;

  const _BranchOverviewLayout({
    required this.connectorStart,
    required this.panelHeight,
    required this.cardPoints,
  });
}

class _BranchConstellationNode extends StatelessWidget {
  final double width;
  final String label;
  final String? badge;
  final Color accentColor;
  final bool isSelected;
  final double progress;
  final int unlocked;
  final int total;
  final List<Exercise> exercises;
  final Map<String, ExerciseStatus> progressMap;
  final bool isFoundation;
  final VoidCallback onTap;

  const _BranchConstellationNode({
    required this.width,
    required this.label,
    required this.badge,
    required this.accentColor,
    required this.isSelected,
    required this.progress,
    required this.unlocked,
    required this.total,
    required this.exercises,
    required this.progressMap,
    required this.isFoundation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const orbSize = 34.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: _branchNodeHeight,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSelected ? 0.09 : 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isSelected ? 0.14 : 0.06),
              blurRadius: isSelected ? 26 : 14,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    accentColor,
                    Color.lerp(accentColor, Colors.black, 0.32)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: isSelected ? 0.55 : 0.32,
                    ),
                    blurRadius: isSelected ? 26 : 16,
                    spreadRadius: isSelected ? 4 : 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            if (badge != null) const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 92,
              height: 74,
              child: CustomPaint(
                painter: _MiniConstellationPainter(
                  exercises: exercises,
                  progressMap: progressMap,
                  accentColor: accentColor,
                  isFoundation: true,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$unlocked / $total',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final bool hasFoundation;
  final Offset start;
  final List<Offset> targets;
  final List<Color> targetColors;

  const _ConstellationPainter({
    required this.hasFoundation,
    required this.start,
    required this.targets,
    required this.targetColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    final stars = <Offset>[
      Offset(size.width * 0.08, size.height * 0.12),
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.33, size.height * 0.08),
      Offset(size.width * 0.48, size.height * 0.18),
      Offset(size.width * 0.68, size.height * 0.1),
      Offset(size.width * 0.86, size.height * 0.22),
      Offset(size.width * 0.14, size.height * 0.72),
      Offset(size.width * 0.32, size.height * 0.64),
      Offset(size.width * 0.58, size.height * 0.78),
      Offset(size.width * 0.82, size.height * 0.68),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 1.6, starPaint);
    }

    final basePaint = Paint()
      ..color = AppColors.borderPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final splitY =
        hasFoundation ? start.dy + (_branchNodeHeight / 2) + 20 : start.dy + 48;
    canvas.drawLine(
      Offset(start.dx, hasFoundation ? splitY - 18 : start.dy),
      Offset(start.dx, splitY),
      basePaint,
    );

    if (targets.isEmpty) return;

    final rowYs = targets
        .map((target) => target.dy - (_branchNodeHeight / 2) - 12)
        .toSet()
        .toList()
      ..sort();

    var previousY = splitY;
    for (final rowY in rowYs) {
      canvas.drawLine(
        Offset(start.dx, previousY),
        Offset(start.dx, rowY),
        basePaint,
      );

      final rowTargets = <int>[
        for (var i = 0; i < targets.length; i++)
          if ((targets[i].dy - (_branchNodeHeight / 2) + 12 - rowY).abs() < 0.1)
            i,
      ];

      final minX = rowTargets
          .map((index) => targets[index].dx)
          .reduce((a, b) => a < b ? a : b);
      final maxX = rowTargets
          .map((index) => targets[index].dx)
          .reduce((a, b) => a > b ? a : b);
      final leftX = math.min(minX, start.dx);
      final rightX = math.max(maxX, start.dx);
      canvas.drawLine(Offset(leftX, rowY), Offset(rightX, rowY), basePaint);

      for (final index in rowTargets) {
        canvas.drawCircle(
          Offset(targets[index].dx, rowY),
          4,
          Paint()..color = targetColors[index].withValues(alpha: 0.9),
        );
      }

      previousY = rowY;
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.targets != targets ||
        oldDelegate.targetColors != targetColors;
  }
}

class _MiniConstellationPainter extends CustomPainter {
  final List<Exercise> exercises;
  final Map<String, ExerciseStatus> progressMap;
  final Color accentColor;
  final bool isFoundation;

  const _MiniConstellationPainter({
    required this.exercises,
    required this.progressMap,
    required this.accentColor,
    required this.isFoundation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (exercises.isEmpty) return;

    final points = <Offset>[];
    const topInset = 6.0;
    const bottomInset = 6.0;
    for (var i = 0; i < exercises.length; i++) {
      final t = exercises.length == 1 ? 0.5 : i / (exercises.length - 1);
      final x = size.width * 0.5;
      final y = size.height -
          bottomInset -
          t * (size.height - topInset - bottomInset);
      points.add(Offset(x, y));
    }

    for (var i = 0; i < points.length - 1; i++) {
      final current = progressMap[exercises[i].id] ?? ExerciseStatus.inactive;
      final next = progressMap[exercises[i + 1].id] ?? ExerciseStatus.inactive;
      final isLit =
          current != ExerciseStatus.inactive || next != ExerciseStatus.inactive;
      final linePaint = Paint()
        ..color = (isLit
                ? accentColor.withValues(alpha: 0.65)
                : AppColors.borderPrimary.withValues(alpha: 0.9))
            .withValues(alpha: isLit ? 0.65 : 0.9)
        ..strokeWidth = isFoundation ? 2 : 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      final status = progressMap[exercises[i].id] ?? ExerciseStatus.inactive;
      final point = points[i];

      switch (status) {
        case ExerciseStatus.mastered:
          canvas.drawCircle(
            point,
            isFoundation ? 6 : 5,
            Paint()..color = accentColor.withValues(alpha: 0.22),
          );
          canvas.drawCircle(
            point,
            isFoundation ? 3.4 : 2.8,
            Paint()..color = Colors.white,
          );
        case ExerciseStatus.active:
          canvas.drawCircle(
            point,
            isFoundation ? 5 : 4,
            Paint()..color = accentColor.withValues(alpha: 0.2),
          );
          canvas.drawCircle(
            point,
            isFoundation ? 2.8 : 2.3,
            Paint()..color = accentColor,
          );
        case ExerciseStatus.inactive:
          canvas.drawCircle(
            point,
            isFoundation ? 2.3 : 2,
            Paint()..color = AppColors.textMuted.withValues(alpha: 0.65),
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniConstellationPainter oldDelegate) {
    return oldDelegate.exercises != exercises ||
        oldDelegate.progressMap != progressMap ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isFoundation != isFoundation;
  }
}

class _PathTimeline extends StatelessWidget {
  final Color accentColor;
  final List<Exercise> exercises;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(Exercise exercise) onExerciseTap;

  const _PathTimeline({
    required this.accentColor,
    required this.exercises,
    required this.progressMap,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < exercises.length; i++) ...[
          _PathExerciseCard(
            exercise: exercises[i],
            accentColor: accentColor,
            status: progressMap[exercises[i].id] ?? ExerciseStatus.inactive,
            onTap: () => onExerciseTap(exercises[i]),
          ),
          if (i < exercises.length - 1)
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ],
    );
  }
}

class _PathExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final Color accentColor;
  final ExerciseStatus status;
  final VoidCallback onTap;

  const _PathExerciseCard({
    required this.exercise,
    required this.accentColor,
    required this.status,
    required this.onTap,
  });

  List<Color> get _previewGradient {
    switch (exercise.category) {
      case ExerciseCategory.verticalPull:
        return const [Color(0xFF27465A), Color(0xFF131C25)];
      case ExerciseCategory.verticalPush:
        return const [Color(0xFF67452B), Color(0xFF21150F)];
      case ExerciseCategory.horizontalPull:
        return const [Color(0xFF2A5264), Color(0xFF111A23)];
      case ExerciseCategory.horizontalPush:
        return const [Color(0xFF6A4029), Color(0xFF20110C)];
      case ExerciseCategory.squat:
        return const [Color(0xFF406737), Color(0xFF152018)];
      case ExerciseCategory.hinge:
        return const [Color(0xFF6A5A38), Color(0xFF1E1911)];
      case ExerciseCategory.core:
        return const [Color(0xFF29576D), Color(0xFF121A21)];
      case ExerciseCategory.skill:
        return const [Color(0xFF5A3260), Color(0xFF181119)];
    }
  }

  IconData get _previewIcon {
    switch (exercise.category) {
      case ExerciseCategory.verticalPull:
        return Icons.sports_gymnastics_rounded;
      case ExerciseCategory.verticalPush:
        return Icons.front_hand_outlined;
      case ExerciseCategory.horizontalPull:
        return Icons.swap_horiz_rounded;
      case ExerciseCategory.horizontalPush:
        return Icons.push_pin_outlined;
      case ExerciseCategory.squat:
        return Icons.accessibility_new_rounded;
      case ExerciseCategory.hinge:
        return Icons.keyboard_double_arrow_down_rounded;
      case ExerciseCategory.core:
        return Icons.crop_free_rounded;
      case ExerciseCategory.skill:
        return Icons.bolt_rounded;
    }
  }

  Color get _statusColor {
    switch (status) {
      case ExerciseStatus.inactive:
        return const Color(0xFF8B8B92);
      case ExerciseStatus.active:
        return accentColor;
      case ExerciseStatus.mastered:
        return _masteredColor;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case ExerciseStatus.inactive:
        return Icons.lock_outline_rounded;
      case ExerciseStatus.active:
        return Icons.play_arrow_rounded;
      case ExerciseStatus.mastered:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 182,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _statusColor, width: 1.6),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 98,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _previewGradient,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -6,
                    bottom: -12,
                    child: Icon(
                      _previewIcon,
                      size: 92,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.68),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon, size: 15, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exercise.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _DifficultyStars(difficulty: exercise.difficulty),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _LockNotice extends StatelessWidget {
  final String message;
  final String? ctaLabel;
  final VoidCallback? onOpenRequiredTree;

  const _LockNotice({
    required this.message,
    this.ctaLabel,
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
            message,
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
              ctaLabel ?? 'Open Required Tree',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewSheet extends StatefulWidget {
  final Exercise exercise;
  final String skillCategoryId;
  final ExerciseStatus initialStatus;
  final FutureOr<void> Function(ExerciseStatus status) onStatusChanged;
  final VoidCallback onLearnMore;

  const _ExercisePreviewSheet({
    required this.exercise,
    required this.skillCategoryId,
    required this.initialStatus,
    required this.onStatusChanged,
    required this.onLearnMore,
  });

  @override
  State<_ExercisePreviewSheet> createState() => _ExercisePreviewSheetState();
}

class _ExercisePreviewSheetState extends State<_ExercisePreviewSheet> {
  late ExerciseStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  Future<void> _handleStatusChanged(ExerciseStatus status) async {
    setState(() {
      _selectedStatus = status;
    });
    await widget.onStatusChanged(status);
  }

  List<Color> get _previewGradient {
    switch (widget.exercise.category) {
      case ExerciseCategory.verticalPull:
        return const [Color(0xFF264C62), Color(0xFF101A24)];
      case ExerciseCategory.verticalPush:
        return const [Color(0xFF5C3B24), Color(0xFF1D120E)];
      case ExerciseCategory.horizontalPull:
        return const [Color(0xFF284559), Color(0xFF111A23)];
      case ExerciseCategory.horizontalPush:
        return const [Color(0xFF5A311F), Color(0xFF1D110D)];
      case ExerciseCategory.squat:
        return const [Color(0xFF35552F), Color(0xFF141C15)];
      case ExerciseCategory.hinge:
        return const [Color(0xFF58482B), Color(0xFF1E1811)];
      case ExerciseCategory.core:
        return const [Color(0xFF214658), Color(0xFF10171F)];
      case ExerciseCategory.skill:
        return const [Color(0xFF4A2C4F), Color(0xFF181018)];
    }
  }

  IconData get _previewIcon {
    switch (widget.exercise.category) {
      case ExerciseCategory.verticalPull:
        return Icons.sports_gymnastics_rounded;
      case ExerciseCategory.verticalPush:
        return Icons.front_hand_outlined;
      case ExerciseCategory.horizontalPull:
        return Icons.swap_horiz_rounded;
      case ExerciseCategory.horizontalPush:
        return Icons.push_pin_outlined;
      case ExerciseCategory.squat:
        return Icons.accessibility_new_rounded;
      case ExerciseCategory.hinge:
        return Icons.keyboard_double_arrow_down_rounded;
      case ExerciseCategory.core:
        return Icons.crop_free_rounded;
      case ExerciseCategory.skill:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillCategory = SkillCategoryCatalog.findById(widget.skillCategoryId);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            Text(
              widget.exercise.name,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.65,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  skillCategory?.title ?? widget.exercise.category.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                _DifficultyStars(difficulty: widget.exercise.difficulty),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.exercise.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 255,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _previewGradient,
                ),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -10,
                    bottom: -18,
                    child: Icon(
                      _previewIcon,
                      size: 180,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Text(
                      'Exercise visualization preview',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onLearnMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Learn more',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.425,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
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
                  .map(
                    (status) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _PreviewStatusChip(
                          status: status,
                          isSelected: _selectedStatus == status,
                          onTap: () => _handleStatusChanged(status),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  final int difficulty;
  const _DifficultyStars({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Padding(
          padding: EdgeInsets.only(right: i == 4 ? 0 : 2),
          child: Icon(
            i < difficulty ? Icons.star_rounded : Icons.star_border_rounded,
            size: 10,
            color: i < difficulty
                ? const Color(0xFFFF6900)
                : const Color(0xFF3F3F46),
          ),
        ),
      ),
    );
  }
}

class _PreviewStatusChip extends StatelessWidget {
  final ExerciseStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _PreviewStatusChip({
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
