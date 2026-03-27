import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';

const double kNodeSize = 80.0;

const _masteredColor = Color(0xFF4CAF50);

class ExerciseNode extends StatelessWidget {
  final Exercise exercise;
  final ExerciseStatus status;
  final VoidCallback onTap;

  const ExerciseNode({
    super.key,
    required this.exercise,
    required this.status,
    required this.onTap,
  });

  Color get _bgColor {
    switch (status) {
      case ExerciseStatus.inactive: return AppColors.bgTertiary;
      case ExerciseStatus.active:   return const Color(0x33FF8904);
      case ExerciseStatus.mastered: return const Color(0x334CAF50);
    }
  }

  Color get _borderColor {
    switch (status) {
      case ExerciseStatus.inactive: return AppColors.borderPrimary;
      case ExerciseStatus.active:   return AppColors.accentBright;
      case ExerciseStatus.mastered: return _masteredColor;
    }
  }

  Color get _textColor {
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
        width: kNodeSize,
        height: kNodeSize,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == ExerciseStatus.mastered
                    ? Icons.check_circle_outline
                    : status == ExerciseStatus.active
                        ? Icons.play_circle_outline
                        : Icons.lock_outline,
                color: _textColor,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                exercise.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
