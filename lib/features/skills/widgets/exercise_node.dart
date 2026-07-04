import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise_model.dart';

const double kNodeWidth = 140.0;
const double kNodeHeight = 165.0;

const _masteredColor = Color(0xFF00FF8C);
const _activeColor = AppColors.accentBright;
const _inactiveStarColor = Color(0xFF3F3F46);
const _starColor = AppColors.accentPrimary;

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

  Color get _borderColor {
    switch (status) {
      case ExerciseStatus.inactive:
        return AppColors.borderPrimary;
      case ExerciseStatus.active:
        return _activeColor;
      case ExerciseStatus.mastered:
        return _masteredColor;
    }
  }

  Color get _surfaceColor {
    switch (status) {
      case ExerciseStatus.inactive:
        return AppColors.bgTertiary;
      case ExerciseStatus.active:
        return const Color(0x0DFF8904);
      case ExerciseStatus.mastered:
        return const Color(0x0D00FF8C);
    }
  }

  Color get _badgeColor {
    switch (status) {
      case ExerciseStatus.inactive:
        return const Color(0xFF2A2A31);
      case ExerciseStatus.active:
        return _activeColor;
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

  IconData get _heroIcon {
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

  List<Color> get _heroGradient {
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

  @override
  Widget build(BuildContext context) {
    final title = exercise.name;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: kNodeWidth,
        height: kNodeHeight,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1E000000),
              blurRadius: 22,
              offset: Offset(0, 12),
              spreadRadius: -14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _heroGradient,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          bottom: -14,
                          child: Icon(
                            _heroIcon,
                            size: 78,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.32),
                                  Colors.black.withValues(alpha: 0.92),
                                ],
                                stops: const [0.0, 0.48, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding:
                                    EdgeInsets.only(right: index == 4 ? 0 : 2),
                                child: Icon(
                                  index < exercise.difficulty
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 10,
                                  color: index < exercise.difficulty
                                      ? _starColor
                                      : _inactiveStarColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon,
                    size: status == ExerciseStatus.mastered ? 14 : 13,
                    color: status == ExerciseStatus.inactive
                        ? Colors.white70
                        : Colors.black,
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
