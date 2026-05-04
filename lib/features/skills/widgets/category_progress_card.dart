import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/skill_category_model.dart';

const _badgeBg = Color(0x14FFFFFF);
const _badgeBorder = Color(0x1FFFFFFF);

class CategoryProgressCard extends StatelessWidget {
  final SkillCategory category;
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
    switch (category.track) {
      case ExerciseCategory.verticalPull:
        return Icons.sports_gymnastics_rounded;
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
      case ExerciseCategory.core:
        return Icons.radio_button_checked;
      case ExerciseCategory.skill:
        return Icons.fitness_center_rounded;
    }
  }

  List<Color> get _gradient {
    switch (category.track) {
      case ExerciseCategory.verticalPull:
        return const [Color(0xFF16384A), Color(0xFF0F1D2A)];
      case ExerciseCategory.verticalPush:
        return const [Color(0xFF3B2C1D), Color(0xFF201611)];
      case ExerciseCategory.horizontalPull:
        return const [Color(0xFF1E3446), Color(0xFF131F2E)];
      case ExerciseCategory.horizontalPush:
        return const [Color(0xFF3E241B), Color(0xFF211412)];
      case ExerciseCategory.squat:
        return const [Color(0xFF263D21), Color(0xFF162317)];
      case ExerciseCategory.hinge:
        return const [Color(0xFF3B3320), Color(0xFF201D14)];
      case ExerciseCategory.core:
        return const [Color(0xFF203746), Color(0xFF121E2B)];
      case ExerciseCategory.skill:
        return const [Color(0xFF3A233C), Color(0xFF1D1220)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? mastered / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, 12),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    _icon,
                    color: AppColors.accentBright,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _badgeBorder),
                  ),
                  child: Text(
                    category.subtitle.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.82),
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              category.title,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentBright,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$mastered / $total mastered',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
