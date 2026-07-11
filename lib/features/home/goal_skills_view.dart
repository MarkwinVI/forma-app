import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
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

      final branch = category.branches
          .where((branch) => branch.id == pathId)
          .toList();

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
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.bgSecondary,
        elevation: 0,
        title: Text(
          'Goal Skills',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Text(
                    'Pick the skills you want your training to build toward. '
                    'They show up as long-term goals on your home screen.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final entry in grouped.entries) ...[
                    Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final option in entry.value) ...[
                      _GoalOptionCard(
                        option: option,
                        isSelected: _selected.contains(option.exercise.id),
                        onTap: () {
                          setState(() {
                            if (!_selected.remove(option.exercise.id)) {
                              _selected.add(option.exercise.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingIndicator(),
                        )
                      : Text(
                          'Save goals',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.425,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  final GoalSkillOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppColors.accentPrimary : AppColors.borderPrimary,
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
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${option.branchLabel} path · ${option.totalSteps} steps',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textMuted,
                  width: 2,
                ),
                color:
                    isSelected ? AppColors.accentPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
