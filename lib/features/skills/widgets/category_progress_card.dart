import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';

const _iconBg = Color(0x1AFF6900);
const _iconBorder = Color(0x4DFF6900);

class CategoryProgressCard extends StatelessWidget {
  final ExerciseCategory category;
  final int mastered;
  final int total;
  final VoidCallback onTap;

  const CategoryProgressCard({
    super.key,
    required this.category,
    required this.mastered,
    required this.total,
    required this.onTap,
  });

  IconData get _icon {
    switch (category) {
      case ExerciseCategory.verticalPull:
        return Icons.arrow_upward;
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
      case ExerciseCategory.calves:
        return Icons.stairs_outlined;
      case ExerciseCategory.core:
        return Icons.radio_button_checked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? mastered / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _iconBorder),
              ),
              child: Icon(_icon, color: AppColors.accentPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.progressBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.progressFill),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$mastered / $total mastered',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
