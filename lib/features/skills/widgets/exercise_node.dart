import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';

const double kNodeWidth = 128.0;
const double kNodeHeight = 72.0;

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
      case ExerciseStatus.inactive:
        return AppColors.bgTertiary;
      case ExerciseStatus.active:
        return const Color(0x33FF8904);
      case ExerciseStatus.mastered:
        return const Color(0x334CAF50);
    }
  }

  Color get _borderColor {
    switch (status) {
      case ExerciseStatus.inactive:
        return AppColors.borderPrimary;
      case ExerciseStatus.active:
        return AppColors.accentBright;
      case ExerciseStatus.mastered:
        return _masteredColor;
    }
  }

  Color get _textColor {
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
        width: kNodeWidth,
        height: kNodeHeight,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 18,
              offset: Offset(0, 10),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _textColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == ExerciseStatus.mastered
                      ? Icons.check_circle_outline
                      : status == ExerciseStatus.active
                          ? Icons.play_circle_outline
                          : Icons.lock_outline,
                  color: _textColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
