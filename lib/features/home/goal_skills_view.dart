import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';

class GoalSkillOption {
  final Exercise exercise;
  final String categoryTitle;
  final String branchLabel;
  final int totalSteps;

  const GoalSkillOption({
    required this.exercise,
    required this.categoryTitle,
    required this.branchLabel,
    required this.totalSteps,
  });
}

/// All goal candidates: the end of every progression path in every
/// browsable skill tree.
List<GoalSkillOption> buildGoalSkillOptions() {
  final options = <GoalSkillOption>[];
  final seen = <String>{};

  for (final category in SkillCategoryCatalog.browsable()) {
    category.trainingPaths.forEach((pathId, exerciseIds) {
      if (exerciseIds.isEmpty) return;

      final exercise = ExerciseCatalog.findById(exerciseIds.last);
      if (exercise == null || !seen.add(exercise.id)) return;

      final branch =
          category.branches.where((branch) => branch.id == pathId).toList();

      options.add(
        GoalSkillOption(
          exercise: exercise,
          categoryTitle: category.title,
          branchLabel: branch.isEmpty ? pathId : branch.first.label,
          totalSteps: exerciseIds.length,
        ),
      );
    });
  }

  return options;
}

/// Multi-select picker for the long-term goal skills shown on the home
/// dashboard. Offers the terminal exercise of every progression path.
class GoalSkillsView extends StatefulWidget {
  final List<String> initialGoalIds;
  final Future<void> Function(List<String> goalIds) onSave;

  const GoalSkillsView({
    super.key,
    required this.initialGoalIds,
    required this.onSave,
  });

  @override
  State<GoalSkillsView> createState() => _GoalSkillsViewState();
}

class _GoalSkillsViewState extends State<GoalSkillsView> {
  late final List<GoalSkillOption> _options;
  late final Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _options = buildGoalSkillOptions();
    _selected = widget.initialGoalIds.toSet();
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await widget.onSave(_selected.toList());
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goals: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<GoalSkillOption>>{};
    for (final option in _options) {
      grouped.putIfAbsent(option.categoryTitle, () => []).add(option);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            SubScreenHeader(
              title: 'Goal skills',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  const Text(
                    'Pick the skills you want your training to build toward. '
                    'They show up as long-term goals on your home screen.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    SurfaceCard(
                      clip: true,
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < entry.value.length;
                              index++)
                            _GoalOptionRow(
                              option: entry.value[index],
                              showDivider: index > 0,
                              isSelected: _selected
                                  .contains(entry.value[index].exercise.id),
                              onTap: () {
                                final id = entry.value[index].exercise.id;
                                setState(() {
                                  if (!_selected.remove(id)) {
                                    _selected.add(id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: PillButton(
                label: _saving ? 'Saving…' : 'Save goals',
                onTap: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalOptionRow extends StatelessWidget {
  final GoalSkillOption option;
  final bool showDivider;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOptionRow({
    required this.option,
    required this.showDivider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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
                    option.exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${option.branchLabel} path · ${option.totalSteps} steps',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.surface3,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.accentPrimary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
