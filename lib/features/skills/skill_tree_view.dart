import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';

const _masteredColor = Color(0xFF4CAF50);
const _treeBg = Color(0xFFF7F5F1);
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
    final hasBranchOverview = _pathIds.length > 1;
    final isOverview = _showBranchOverview && hasBranchOverview;
    final pathExercises = _exercisesForPath(_selectedPathId);

    return Scaffold(
      backgroundColor: isOverview ? AppColors.bgSecondary : _treeBg,
      appBar: AppBar(
        automaticallyImplyLeading:
            hasBranchOverview ? _showBranchOverview : true,
        leading: hasBranchOverview && !_showBranchOverview
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _showBranchOverview = true),
              )
            : null,
        backgroundColor: isOverview ? AppColors.bgSecondary : Colors.white,
        foregroundColor:
            isOverview ? AppColors.textPrimary : const Color(0xFF4B4B4B),
        elevation: 0,
        surfaceTintColor: isOverview ? AppColors.bgSecondary : Colors.white,
        title: Text(
          _showBranchOverview || !hasBranchOverview
              ? '${_skillCategory.title} progression'
              : _pathLabel(_selectedPathId),
          style: GoogleFonts.lato(
            fontSize: _showBranchOverview || !hasBranchOverview ? 24 : 22,
            fontWeight: FontWeight.w800,
            color: isOverview ? AppColors.textPrimary : const Color(0xFF4B4B4B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    color: const Color(0xFF18181B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unlocked of $total steps unlocked',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6A6A72),
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
        color: Colors.white,
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
                    color: const Color(0xFF5B5B63),
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
    required this.onOpenPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasFoundation = foundationPathId != null;
    final cardCenters = _branchCardCenters(pathIds.length);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgPrimary,
            AppColors.bgSecondary,
            AppColors.bgPrimary,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: _surfaceShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a branch',
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
                ? 'Start from the shared foundation, then choose a specialization branch.'
                : 'Pick the branch you want to train and drill into its progression.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final branchCardWidth = pathIds.length >= 4 ? 72.0 : 104.0;
              final branchCardHeight = pathIds.length >= 4 ? 96.0 : 110.0;
              final mapHeight = hasFoundation ? 318.0 : 360.0;
              final width = constraints.maxWidth;
              final hubCenter = Offset(width / 2, hasFoundation ? 60 : 54);
              final positions = cardCenters
                  .map((center) => Offset(center.dx * width, center.dy))
                  .toList();

              return SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, mapHeight),
                      painter: _BranchOverviewPainter(
                        hubCenter: hubCenter,
                        branchCenters: positions,
                        hasFoundation: hasFoundation,
                        branchColors: [
                          for (final pathId in pathIds) accentBuilder(pathId),
                        ],
                      ),
                    ),
                    Positioned(
                      left: hasFoundation ? width / 2 - 78 : width / 2 - 90,
                      top: 0,
                      child: _OverviewHub(
                        title: hasFoundation
                            ? labelBuilder(foundationPathId!)
                            : skillCategory.title,
                        subtitle: hasFoundation
                            ? '${unlockedCountBuilder(foundationPathId!)} of ${totalCountBuilder(foundationPathId!)} unlocked'
                            : skillCategory.description,
                        accentColor: hasFoundation
                            ? accentBuilder(foundationPathId!)
                            : const Color(0xFF8892A6),
                        badge: hasFoundation
                            ? badgeBuilder(foundationPathId!)
                            : null,
                        onTap: hasFoundation
                            ? () => onOpenPath(foundationPathId!)
                            : null,
                      ),
                    ),
                    for (var i = 0; i < pathIds.length; i++)
                      Positioned(
                        left: positions[i].dx - branchCardWidth / 2,
                        top: positions[i].dy - branchCardHeight / 2,
                        child: _BranchCard(
                          width: branchCardWidth,
                          height: branchCardHeight,
                          label: labelBuilder(pathIds[i]),
                          badge: badgeBuilder(pathIds[i]),
                          accentColor: accentBuilder(pathIds[i]),
                          isSelected: pathIds[i] == selectedPathId,
                          progress: progressBuilder(pathIds[i]),
                          unlocked: unlockedCountBuilder(pathIds[i]),
                          total: totalCountBuilder(pathIds[i]),
                          mastered: masteredCountBuilder(pathIds[i]),
                          onTap: () => onOpenPath(pathIds[i]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<Offset> _branchCardCenters(int count) {
  switch (count) {
    case 2:
      return const [Offset(0.3, 226), Offset(0.7, 226)];
    case 3:
      return const [Offset(0.18, 228), Offset(0.5, 228), Offset(0.82, 228)];
    case 4:
      return const [
        Offset(0.12, 228),
        Offset(0.38, 228),
        Offset(0.62, 228),
        Offset(0.88, 228),
      ];
    default:
      return const [
        Offset(0.18, 228),
        Offset(0.5, 228),
        Offset(0.82, 228),
      ];
  }
}

class _OverviewHub extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? badge;
  final VoidCallback? onTap;

  const _OverviewHub({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          width: badge != null ? 156 : 180,
          height: 108,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(AppColors.bgPrimary, accentColor, 0.18)!,
                AppColors.bgTertiary,
              ],
            ),
            border: Border.all(color: accentColor.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
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
              if (badge != null) const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ));
  }
}

class _BranchCard extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final String? badge;
  final Color accentColor;
  final bool isSelected;
  final double progress;
  final int unlocked;
  final int total;
  final int mastered;
  final VoidCallback onTap;

  const _BranchCard({
    required this.width,
    required this.height,
    required this.label,
    required this.badge,
    required this.accentColor,
    required this.isSelected,
    required this.progress,
    required this.unlocked,
    required this.total,
    required this.mastered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = width < 90;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        height: height,
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.bgTertiary,
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.85)
                : AppColors.borderPrimary,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isSelected ? 0.24 : 0.1),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 8 : 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            if (badge != null) SizedBox(height: compact ? 8 : 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$unlocked / $total unlocked',
              style: GoogleFonts.inter(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: compact ? 5 : 6,
                value: progress,
                color: accentColor,
                backgroundColor: AppColors.borderPrimary,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              '$mastered mastered',
              style: GoogleFonts.inter(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchOverviewPainter extends CustomPainter {
  final Offset hubCenter;
  final List<Offset> branchCenters;
  final List<Color> branchColors;
  final bool hasFoundation;

  const _BranchOverviewPainter({
    required this.hubCenter,
    required this.branchCenters,
    required this.branchColors,
    required this.hasFoundation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trunkPaint = Paint()
      ..color = AppColors.borderPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final splitY = hasFoundation ? hubCenter.dy + 70 : hubCenter.dy + 42;

    canvas.drawLine(hubCenter, Offset(hubCenter.dx, splitY), trunkPaint);

    for (var i = 0; i < branchCenters.length; i++) {
      final target = branchCenters[i];
      final accentPaint = Paint()
        ..color = branchColors[i].withValues(alpha: 0.65)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(hubCenter.dx, splitY)
        ..lineTo(target.dx, splitY)
        ..lineTo(target.dx, target.dy - 58);
      canvas.drawPath(path, accentPaint);

      canvas.drawCircle(
        Offset(target.dx, target.dy - 58),
        5,
        Paint()..color = branchColors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BranchOverviewPainter oldDelegate) {
    return oldDelegate.hubCenter != hubCenter ||
        oldDelegate.branchCenters != branchCenters ||
        oldDelegate.branchColors != branchColors ||
        oldDelegate.hasFoundation != hasFoundation;
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
          color: Colors.white,
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
                color: const Color(0xFF111111),
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

  List<Color> get _previewGradient {
    switch (exercise.category) {
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

  @override
  Widget build(BuildContext context) {
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
              exercise.name,
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
                  'DIFFICULTY:',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _DifficultyStars(difficulty: exercise.difficulty),
                const SizedBox(width: 8),
                Text(
                  _difficultyLabel(exercise.difficulty),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exercise.description,
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Learning content coming soon.'),
                    ),
                  );
                },
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
      ),
    );
  }
}

String _difficultyLabel(int difficulty) {
  if (difficulty <= 2) return '(Easy)';
  if (difficulty == 3) return '(Medium)';
  if (difficulty == 4) return '(Hard)';
  return '(Elite)';
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
