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

  int get _categoryUnlockedCount {
    return _exercises
        .where(
          (exercise) =>
              (_localProgress[exercise.id] ?? ExerciseStatus.inactive) !=
              ExerciseStatus.inactive,
        )
        .length;
  }

  double get _categoryProgress {
    if (_exercises.isEmpty) return 0;
    return _categoryUnlockedCount / _exercises.length;
  }

  int get _overviewPathCount =>
      _hasFoundationPath ? _realPathIds.length + 1 : _pathIds.length;

  bool _pathHasActive(String pathId) {
    return _exercisesForPath(pathId).any(
        (exercise) => _localProgress[exercise.id] == ExerciseStatus.active);
  }

  Exercise? _currentExerciseForPath(String pathId) {
    for (final exercise in _exercisesForPath(pathId)) {
      if (_localProgress[exercise.id] == ExerciseStatus.active) {
        return exercise;
      }
    }
    return null;
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
            accentColor: _pathAccent(_selectedPathId),
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
    final selectedPathCurrent = _currentExerciseForPath(_selectedPathId);
    final topCount = _showBranchOverview || !hasBranchOverview
        ? _categoryUnlockedCount
        : _pathUnlockedCount(_selectedPathId);
    final topTotal = _showBranchOverview || !hasBranchOverview
        ? _exercises.length
        : pathExercises.length;
    final backLabel = _showBranchOverview || !hasBranchOverview
        ? 'Skills'
        : _skillCategory.title;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _BackCapsuleButton(
                    label: backLabel,
                    onTap: () {
                      if (hasBranchOverview && !_showBranchOverview) {
                        setState(() => _showBranchOverview = true);
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  Text(
                    '$topCount/$topTotal',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: AppColors.accentBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _TrackHeroHeader(
                title: _skillCategory.title,
                metaLabel:
                    '${_overviewPathCount == 1 ? '1 path' : '$_overviewPathCount branches'} · ${_exercises.length} skills',
                progress: _categoryProgress,
                unlocked: _categoryUnlockedCount,
                total: _exercises.length,
              ),
              const SizedBox(height: 18),
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
                const SizedBox(height: 18),
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
                            pathIds:
                                _hasFoundationPath ? _realPathIds : _pathIds,
                            selectedPathId: _selectedPathId,
                            labelBuilder: _pathLabel,
                            badgeBuilder: _pathBadge,
                            accentBuilder: _pathAccent,
                            progressBuilder: _pathProgress,
                            unlockedCountBuilder: _pathUnlockedCount,
                            masteredCountBuilder: _pathMasteredCount,
                            hasActiveBuilder: _pathHasActive,
                            currentExerciseBuilder: _currentExerciseForPath,
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
                              'path-${_skillCategory.id}-$_selectedPathId',
                            ),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (hasBranchOverview)
                                _SelectedPathHeader(
                                  label: _pathLabel(_selectedPathId),
                                  badge: _pathBadge(_selectedPathId),
                                  accentColor: _pathAccent(_selectedPathId),
                                  unlocked: _pathUnlockedCount(_selectedPathId),
                                  total: pathExercises.length,
                                  mastered: _pathMasteredCount(_selectedPathId),
                                  active: selectedPathCurrent != null ? 1 : 0,
                                  currentExerciseName:
                                      selectedPathCurrent?.name,
                                  onViewBranches: () => setState(
                                      () => _showBranchOverview = true),
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
                                title: _pathLabel(_selectedPathId),
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
  final int mastered;
  final int active;
  final String? currentExerciseName;
  final VoidCallback onViewBranches;

  const _SelectedPathHeader({
    required this.label,
    required this.badge,
    required this.accentColor,
    required this.unlocked,
    required this.total,
    required this.mastered,
    required this.active,
    required this.currentExerciseName,
    required this.onViewBranches,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!.toUpperCase(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: accentColor,
                      ),
                    ),
                  ),
                if (badge != null) const SizedBox(height: 12),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.lato(
                    fontSize: 32,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentExerciseName != null
                      ? 'Working now: $currentExerciseName'
                      : '$unlocked of $total skills unlocked',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}',
                      style: GoogleFonts.lato(
                        fontSize: 36,
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: accentColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        '%',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatChip(label: 'Mastered', value: '$mastered'),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Skills', value: '$unlocked/$total'),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Active', value: '$active'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          TextButton.icon(
            onPressed: onViewBranches,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: accentColor.withValues(alpha: 0.24)),
              ),
            ),
            icon: const Icon(Icons.account_tree_outlined, size: 18),
            label: Text(
              'Branches',
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
                  'FOUNDATION FIRST',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
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
  final bool Function(String pathId) hasActiveBuilder;
  final Exercise? Function(String pathId) currentExerciseBuilder;
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
    required this.hasActiveBuilder,
    required this.currentExerciseBuilder,
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
          hasFoundation ? 'Branches' : 'Path',
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasFoundation ? 'Choose your route.' : 'Choose your next route.',
          style: GoogleFonts.lato(
            fontSize: 30,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: _TrackConstellationPanel(
            overviewPaths: overviewPaths,
            foundationPathId: foundationPathId,
            selectedPathId: selectedPathId,
            labelBuilder: labelBuilder,
            badgeBuilder: badgeBuilder,
            accentBuilder: accentBuilder,
            unlockedCountBuilder: unlockedCountBuilder,
            totalCountBuilder: totalCountBuilder,
            exercisesForPathBuilder: exercisesForPathBuilder,
            progressMap: progressMap,
            onOpenPath: onOpenPath,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'All branches',
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        for (final pathId in overviewPaths) ...[
          _BranchOverviewRow(
            label: labelBuilder(pathId),
            badge: badgeBuilder(pathId),
            accentColor: accentBuilder(pathId),
            isSelected: pathId == selectedPathId,
            isFoundation: hasFoundation && pathId == foundationPathId,
            progress: progressBuilder(pathId),
            unlocked: unlockedCountBuilder(pathId),
            total: totalCountBuilder(pathId),
            hasActive: hasActiveBuilder(pathId),
            isMastered:
                masteredCountBuilder(pathId) == totalCountBuilder(pathId) &&
                    totalCountBuilder(pathId) > 0,
            currentExerciseName: currentExerciseBuilder(pathId)?.name,
            onTap: () => onOpenPath(pathId),
          ),
          if (pathId != overviewPaths.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TrackConstellationPanel extends StatelessWidget {
  final List<String> overviewPaths;
  final String? foundationPathId;
  final String selectedPathId;
  final String Function(String pathId) labelBuilder;
  final String? Function(String pathId) badgeBuilder;
  final Color Function(String pathId) accentBuilder;
  final int Function(String pathId) unlockedCountBuilder;
  final int Function(String pathId) totalCountBuilder;
  final List<Exercise> Function(String pathId) exercisesForPathBuilder;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(String pathId) onOpenPath;

  const _TrackConstellationPanel({
    required this.overviewPaths,
    required this.foundationPathId,
    required this.selectedPathId,
    required this.labelBuilder,
    required this.badgeBuilder,
    required this.accentBuilder,
    required this.unlockedCountBuilder,
    required this.totalCountBuilder,
    required this.exercisesForPathBuilder,
    required this.progressMap,
    required this.onOpenPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasFoundation = foundationPathId != null;
    final branchCount =
        hasFoundation ? overviewPaths.length - 1 : overviewPaths.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = hasFoundation
            ? (branchCount >= 3 ? 470.0 : 410.0)
            : (branchCount >= 3 ? 400.0 : 320.0);
        final forkY = hasFoundation ? 188.0 : 84.0;
        final centerX = width / 2;
        final tipOffsets = _branchTipOffsets(
          width: width,
          height: height,
          branchCount: branchCount,
          hasFoundation: hasFoundation,
        );

        final pathLayouts = <_ConstellationPathLayout>[];
        var branchIndex = 0;
        for (final pathId in overviewPaths) {
          final exercises = exercisesForPathBuilder(pathId);
          if (hasFoundation && pathId == foundationPathId) {
            pathLayouts.add(
              _ConstellationPathLayout(
                id: pathId,
                nodes: _buildLinearNodeOffsets(
                  start: Offset(centerX, 38),
                  end: Offset(centerX, forkY - 26),
                  count: exercises.length,
                ),
                tip: Offset(centerX, 18),
                accentColor: accentBuilder(pathId),
                isFoundation: true,
                exercises: exercises,
              ),
            );
          } else {
            final tip = tipOffsets[branchIndex++];
            pathLayouts.add(
              _ConstellationPathLayout(
                id: pathId,
                nodes: _buildLinearNodeOffsets(
                  start: Offset(centerX, forkY + 22),
                  end: tip,
                  count: exercises.length,
                ),
                tip: tip,
                accentColor: accentBuilder(pathId),
                isFoundation: false,
                exercises: exercises,
              ),
            );
          }
        }

        final foundationLayout = hasFoundation
            ? pathLayouts.firstWhere((layout) => layout.id == foundationPathId)
            : null;
        final foundationComplete = foundationLayout != null &&
            foundationLayout.exercises.isNotEmpty &&
            foundationLayout.exercises.every(
              (exercise) =>
                  (progressMap[exercise.id] ?? ExerciseStatus.inactive) !=
                  ExerciseStatus.inactive,
            );

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _TrackConstellationPainter(
                  pathLayouts: pathLayouts,
                  foundationPathId: foundationPathId,
                  selectedPathId: selectedPathId,
                  progressMap: progressMap,
                  forkOffset: Offset(centerX, forkY),
                ),
              ),
              if (hasFoundation)
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onOpenPath(foundationPathId!),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FOUNDATION',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: selectedPathId == foundationPathId
                                  ? accentBuilder(foundationPathId!)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (hasFoundation)
                Positioned(
                  left: 0,
                  top: forkY - 18,
                  child: Text(
                    foundationComplete
                        ? 'FOUNDATION COMPLETE'
                        : 'FOUNDATION IN PROGRESS',
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                      color: foundationComplete
                          ? accentBuilder(foundationPathId!)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              if (hasFoundation)
                Positioned(
                  right: 0,
                  top: forkY + 6,
                  child: Text(
                    'BRANCHES',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              for (final layout in pathLayouts)
                if (!(hasFoundation && layout.id == foundationPathId))
                  _ConstellationTipLabel(
                    tip: layout.tip,
                    width: width,
                    label: labelBuilder(layout.id),
                    badge: badgeBuilder(layout.id),
                    accentColor: layout.accentColor,
                    selected: layout.id == selectedPathId,
                    opacity: _constellationPathOpacity(
                      layout.id,
                      selectedPathId,
                      foundationPathId,
                    ),
                    unlocked: unlockedCountBuilder(layout.id),
                    total: totalCountBuilder(layout.id),
                    onTap: () => onOpenPath(layout.id),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ConstellationPathLayout {
  final String id;
  final List<Offset> nodes;
  final Offset tip;
  final Color accentColor;
  final bool isFoundation;
  final List<Exercise> exercises;

  const _ConstellationPathLayout({
    required this.id,
    required this.nodes,
    required this.tip,
    required this.accentColor,
    required this.isFoundation,
    required this.exercises,
  });
}

class _ConstellationTipLabel extends StatelessWidget {
  final Offset tip;
  final double width;
  final String label;
  final String? badge;
  final Color accentColor;
  final bool selected;
  final double opacity;
  final int unlocked;
  final int total;
  final VoidCallback onTap;

  const _ConstellationTipLabel({
    required this.tip,
    required this.width,
    required this.label,
    required this.badge,
    required this.accentColor,
    required this.selected,
    required this.opacity,
    required this.unlocked,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labelWidth = 128.0;
    final left =
        math.max(0.0, math.min(width - labelWidth, tip.dx - (labelWidth / 2)));
    final align = tip.dx < width * 0.33
        ? TextAlign.left
        : tip.dx > width * 0.67
            ? TextAlign.right
            : TextAlign.center;

    return Positioned(
      left: left,
      top: tip.dy + 10,
      width: labelWidth,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: align == TextAlign.left
                ? CrossAxisAlignment.start
                : align == TextAlign.right
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                textAlign: align,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  height: 0.98,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: -0.35,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${unlocked.toString().padLeft(2, '0')}/${total.toString().padLeft(2, '0')}'
                '${badge != null ? ' · ${badge!.toUpperCase()}' : ''}',
                textAlign: align,
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: selected ? accentColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackConstellationPainter extends CustomPainter {
  final List<_ConstellationPathLayout> pathLayouts;
  final String? foundationPathId;
  final String selectedPathId;
  final Map<String, ExerciseStatus> progressMap;
  final Offset forkOffset;

  const _TrackConstellationPainter({
    required this.pathLayouts,
    required this.foundationPathId,
    required this.selectedPathId,
    required this.progressMap,
    required this.forkOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (foundationPathId != null) {
      final gatePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1;
      _drawDashedLine(
        canvas,
        Offset(0, forkOffset.dy),
        Offset(size.width, forkOffset.dy),
        gatePaint,
      );
    }

    for (final layout in pathLayouts) {
      final pathOpacity = _constellationPathOpacity(
        layout.id,
        selectedPathId,
        foundationPathId,
      );

      if (layout.isFoundation) {
        for (var i = 0; i < layout.nodes.length - 1; i++) {
          _drawSegment(
            canvas: canvas,
            a: layout.nodes[i],
            b: layout.nodes[i + 1],
            statusA:
                progressMap[layout.exercises[i].id] ?? ExerciseStatus.inactive,
            statusB: progressMap[layout.exercises[i + 1].id] ??
                ExerciseStatus.inactive,
            accentColor: layout.accentColor,
            opacity: pathOpacity,
            width: 2.2,
          );
        }
        if (layout.nodes.isNotEmpty) {
          final lastStatus =
              progressMap[layout.exercises.last.id] ?? ExerciseStatus.inactive;
          _drawSegment(
            canvas: canvas,
            a: layout.nodes.last,
            b: forkOffset,
            statusA: lastStatus,
            statusB: lastStatus,
            accentColor: layout.accentColor,
            opacity: pathOpacity,
            width: 2.2,
          );
        }
      } else {
        if (layout.nodes.isNotEmpty) {
          final firstStatus =
              progressMap[layout.exercises.first.id] ?? ExerciseStatus.inactive;
          _drawSegment(
            canvas: canvas,
            a: forkOffset,
            b: layout.nodes.first,
            statusA: firstStatus,
            statusB: firstStatus,
            accentColor: layout.accentColor,
            opacity: pathOpacity,
            width: 1.8,
          );
        }
        for (var i = 0; i < layout.nodes.length - 1; i++) {
          _drawSegment(
            canvas: canvas,
            a: layout.nodes[i],
            b: layout.nodes[i + 1],
            statusA:
                progressMap[layout.exercises[i].id] ?? ExerciseStatus.inactive,
            statusB: progressMap[layout.exercises[i + 1].id] ??
                ExerciseStatus.inactive,
            accentColor: layout.accentColor,
            opacity: pathOpacity,
            width: 1.8,
          );
        }
      }
    }

    for (final layout in pathLayouts) {
      final pathOpacity = _constellationPathOpacity(
        layout.id,
        selectedPathId,
        foundationPathId,
      );
      for (var i = 0; i < layout.nodes.length; i++) {
        _drawNode(
          canvas: canvas,
          center: layout.nodes[i],
          status:
              progressMap[layout.exercises[i].id] ?? ExerciseStatus.inactive,
          accentColor: layout.accentColor,
          opacity: pathOpacity,
          radius: layout.isFoundation ? 4.5 : 4.0,
        );
      }
    }

    if (foundationPathId != null) {
      final foundation = pathLayouts.firstWhere(
        (layout) => layout.id == foundationPathId,
      );
      final forkStatus = foundation.exercises.isNotEmpty
          ? progressMap[foundation.exercises.last.id] ?? ExerciseStatus.inactive
          : ExerciseStatus.inactive;
      _drawNode(
        canvas: canvas,
        center: forkOffset,
        status: forkStatus,
        accentColor: foundation.accentColor,
        opacity: _constellationPathOpacity(
          foundation.id,
          selectedPathId,
          foundationPathId,
        ),
        radius: 5.5,
        doubleRing: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackConstellationPainter oldDelegate) {
    return oldDelegate.pathLayouts != pathLayouts ||
        oldDelegate.selectedPathId != selectedPathId ||
        oldDelegate.progressMap != progressMap ||
        oldDelegate.forkOffset != forkOffset;
  }
}

List<Offset> _branchTipOffsets({
  required double width,
  required double height,
  required int branchCount,
  required bool hasFoundation,
}) {
  List<Offset> normalized;
  if (hasFoundation) {
    switch (branchCount) {
      case 1:
        normalized = const [Offset(0.5, 0.78)];
      case 2:
        normalized = const [Offset(0.24, 0.72), Offset(0.76, 0.72)];
      case 3:
        normalized = const [
          Offset(0.2, 0.66),
          Offset(0.8, 0.66),
          Offset(0.5, 0.86),
        ];
      default:
        normalized = const [
          Offset(0.18, 0.62),
          Offset(0.82, 0.62),
          Offset(0.3, 0.88),
          Offset(0.7, 0.88),
        ];
    }
  } else {
    switch (branchCount) {
      case 1:
        normalized = const [Offset(0.5, 0.72)];
      case 2:
        normalized = const [Offset(0.24, 0.76), Offset(0.76, 0.76)];
      case 3:
        normalized = const [
          Offset(0.22, 0.66),
          Offset(0.78, 0.66),
          Offset(0.5, 0.88),
        ];
      default:
        normalized = const [
          Offset(0.18, 0.64),
          Offset(0.82, 0.64),
          Offset(0.3, 0.9),
          Offset(0.7, 0.9),
        ];
    }
  }

  return normalized
      .map((offset) => Offset(offset.dx * width, offset.dy * height))
      .toList();
}

List<Offset> _buildLinearNodeOffsets({
  required Offset start,
  required Offset end,
  required int count,
}) {
  if (count <= 0) return const [];
  if (count == 1) {
    return [Offset.lerp(start, end, 0.5)!];
  }

  return [
    for (var i = 0; i < count; i++) Offset.lerp(start, end, i / (count - 1))!,
  ];
}

double _constellationPathOpacity(
  String pathId,
  String selectedPathId,
  String? foundationPathId,
) {
  if (pathId == selectedPathId) return 1;
  if (foundationPathId != null &&
      pathId == foundationPathId &&
      selectedPathId != foundationPathId) {
    return 0.62;
  }
  return 0.22;
}

void _drawSegment({
  required Canvas canvas,
  required Offset a,
  required Offset b,
  required ExerciseStatus statusA,
  required ExerciseStatus statusB,
  required Color accentColor,
  required double opacity,
  required double width,
}) {
  final lit =
      statusA != ExerciseStatus.inactive || statusB != ExerciseStatus.inactive;
  final color = statusB == ExerciseStatus.active
      ? accentColor
      : lit
          ? accentColor.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.1);
  final paint = Paint()
    ..color = color.withValues(
      alpha: (statusB == ExerciseStatus.active
              ? 0.88
              : lit
                  ? 0.62
                  : 0.12) *
          opacity,
    )
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(a, b, paint);
}

void _drawNode({
  required Canvas canvas,
  required Offset center,
  required ExerciseStatus status,
  required Color accentColor,
  required double opacity,
  required double radius,
  bool doubleRing = false,
}) {
  final color = switch (status) {
    ExerciseStatus.inactive => AppColors.textMuted.withValues(alpha: 0.75),
    ExerciseStatus.active => accentColor,
    ExerciseStatus.mastered => _masteredColor,
  };

  if (status != ExerciseStatus.inactive) {
    canvas.drawCircle(
      center,
      radius * 2.3,
      Paint()..color = color.withValues(alpha: 0.16 * opacity),
    );
  }
  canvas.drawCircle(
    center,
    radius * 1.65,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = doubleRing ? 1.2 : 0.8
      ..color = color.withValues(
        alpha:
            status == ExerciseStatus.inactive ? 0.18 * opacity : 0.35 * opacity,
      ),
  );
  if (doubleRing) {
    canvas.drawCircle(
      center,
      radius * 2.45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = color.withValues(alpha: 0.25 * opacity),
    );
  }
  canvas.drawCircle(
    center,
    radius,
    Paint()..color = color.withValues(alpha: opacity),
  );
}

void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
  const dash = 5.0;
  const gap = 5.0;
  final total = (b - a).distance;
  final direction = (b - a) / total;
  var distance = 0.0;
  while (distance < total) {
    final start = a + direction * distance;
    final end = a + direction * math.min(distance + dash, total);
    canvas.drawLine(start, end, paint);
    distance += dash + gap;
  }
}

class _BranchOverviewRow extends StatelessWidget {
  final String label;
  final String? badge;
  final Color accentColor;
  final bool isSelected;
  final bool isFoundation;
  final double progress;
  final int unlocked;
  final int total;
  final bool hasActive;
  final bool isMastered;
  final String? currentExerciseName;
  final VoidCallback onTap;

  const _BranchOverviewRow({
    required this.label,
    required this.badge,
    required this.accentColor,
    required this.isSelected,
    required this.isFoundation,
    required this.progress,
    required this.unlocked,
    required this.total,
    required this.hasActive,
    required this.isMastered,
    required this.currentExerciseName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eyebrow = isFoundation
        ? 'FOUNDATION'
        : hasActive
            ? 'ACTIVE'
            : isMastered
                ? 'MASTERED'
                : unlocked == 0
                    ? 'LOCKED'
                    : 'BRANCH';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.4)
                  : AppColors.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          eyebrow,
                          style: GoogleFonts.robotoMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.7,
                            color: hasActive || isFoundation
                                ? accentColor
                                : AppColors.textMuted,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            badge!.toUpperCase(),
                            style: GoogleFonts.robotoMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentExerciseName != null
                          ? 'Working: $currentExerciseName'
                          : unlocked == 0
                              ? 'Unlock this route through the previous steps.'
                              : '$unlocked of $total skills unlocked',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: '${(progress * 100).round()}',
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: '%',
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$unlocked/$total',
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathTimeline extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<Exercise> exercises;
  final Map<String, ExerciseStatus> progressMap;
  final void Function(Exercise exercise) onExerciseTap;

  const _PathTimeline({
    required this.title,
    required this.accentColor,
    required this.exercises,
    required this.progressMap,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progression',
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.lato(
            fontSize: 30,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${exercises.length} skill${exercises.length == 1 ? '' : 's'} in this route',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < exercises.length; i++) ...[
          _PathExerciseRow(
            index: i,
            exercise: exercises[i],
            accentColor: accentColor,
            status: progressMap[exercises[i].id] ?? ExerciseStatus.inactive,
            isLast: i == exercises.length - 1,
            onTap: () => onExerciseTap(exercises[i]),
          ),
        ],
      ],
    );
  }
}

class _PathExerciseRow extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final Color accentColor;
  final ExerciseStatus status;
  final bool isLast;
  final VoidCallback onTap;

  const _PathExerciseRow({
    required this.index,
    required this.exercise,
    required this.accentColor,
    required this.status,
    required this.isLast,
    required this.onTap,
  });

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

  String get _statusLabel {
    switch (status) {
      case ExerciseStatus.inactive:
        return 'LOCKED';
      case ExerciseStatus.active:
        return 'ACTIVE NOW';
      case ExerciseStatus.mastered:
        return 'MASTERED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = status == ExerciseStatus.inactive
        ? Colors.white.withValues(alpha: 0.12)
        : _statusColor.withValues(alpha: 0.45);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              const SizedBox(height: 18),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (status != ExerciseStatus.inactive)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor.withValues(alpha: 0.18),
                      ),
                    ),
                  Container(
                    width: status == ExerciseStatus.inactive ? 6 : 10,
                    height: status == ExerciseStatus.inactive ? 6 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 86,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: status == ExerciseStatus.inactive
                        ? Colors.white.withValues(alpha: 0.08)
                        : lineColor,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: status == ExerciseStatus.inactive
                        ? Colors.transparent
                        : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: status == ExerciseStatus.inactive
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(index + 1).toString().padLeft(2, '0')} · $_statusLabel',
                              style: GoogleFonts.robotoMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: status == ExerciseStatus.active
                                    ? accentColor
                                    : status == ExerciseStatus.mastered
                                        ? _masteredColor
                                        : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.25,
                                color: status == ExerciseStatus.inactive
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              exercise.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _DifficultyBars(
                            difficulty: exercise.difficulty,
                            color: status == ExerciseStatus.active
                                ? accentColor
                                : status == ExerciseStatus.mastered
                                    ? _masteredColor
                                    : Colors.white.withValues(alpha: 0.18),
                          ),
                          const SizedBox(height: 14),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackCapsuleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BackCapsuleButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.robotoMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _TrackHeroHeader extends StatelessWidget {
  final String title;
  final String metaLabel;
  final double progress;
  final int unlocked;
  final int total;

  const _TrackHeroHeader({
    required this.title,
    required this.metaLabel,
    required this.progress,
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metaLabel.toUpperCase(),
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.lato(
            fontSize: 44,
            height: 0.9,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(progress * 100).round()}',
              style: GoogleFonts.lato(
                fontSize: 40,
                height: 0.9,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: AppColors.accentBright,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '%',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBright,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$unlocked/$total unlocked',
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DifficultyBars extends StatelessWidget {
  final int difficulty;
  final Color color;

  const _DifficultyBars({
    required this.difficulty,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: 3,
              height: 5 + (i * 2.0),
              margin: EdgeInsets.only(right: i == 4 ? 0 : 2),
              decoration: BoxDecoration(
                color: i < difficulty
                    ? color
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
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
