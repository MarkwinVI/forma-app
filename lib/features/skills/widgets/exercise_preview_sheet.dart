import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/catalog/skill_category_catalog.dart';
import '../../../data/models/exercise_model.dart';

class ExercisePreviewSheet extends StatelessWidget {
  final Exercise exercise;
  final String skillCategoryId;
  final VoidCallback onLearnMore;

  const ExercisePreviewSheet({
    super.key,
    required this.exercise,
    required this.skillCategoryId,
    required this.onLearnMore,
  });

  /// Difficulty in words — the 1–5 catalog scale collapsed to the three
  /// levels the app talks in.
  String get _difficultyLabel {
    if (exercise.difficulty <= 1) return 'Beginner';
    if (exercise.difficulty == 2) return 'Intermediate';
    return 'Advanced';
  }

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
    final skillCategory = SkillCategoryCatalog.findById(skillCategoryId);

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
              style: const TextStyle(
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
                  skillCategory?.title ?? exercise.category.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '·',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _difficultyLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exercise.description,
              style: const TextStyle(
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
                      style: TextStyle(
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
                onPressed: onLearnMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Learn more',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.425,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

