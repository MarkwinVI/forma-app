import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import 'live_workout_view.dart';

const _overviewBg = Color(0xFF252323);
const _overviewCard = Color(0xFF09090B);
const _overviewSurface = Color(0x08FFFFFF);

class SessionOverviewView extends StatelessWidget {
  final DailyTrainingRecommendation recommendation;

  const SessionOverviewView({
    super.key,
    required this.recommendation,
  });

  static const _sectionOrder = [
    ExerciseProgramSection.warmup,
    ExerciseProgramSection.skillWork,
    ExerciseProgramSection.mainExercises,
    ExerciseProgramSection.coolDown,
  ];

  List<TrainingRecommendationItem> _itemsForSection(
    ExerciseProgramSection section,
  ) {
    return recommendation.items
        .where((item) => item.exercise.programSection == section)
        .toList();
  }

  void _openLiveWorkout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveWorkoutView(
          recommendation: recommendation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSections = _sectionOrder
        .map((section) => (section: section, items: _itemsForSection(section)))
        .where((entry) => entry.items.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: _overviewBg,
      appBar: AppBar(
        backgroundColor: _overviewBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: _overviewBg,
        title: Text(
          recommendation.sessionLabel,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _OverviewHeroCard(exerciseCount: recommendation.items.length),
            const SizedBox(height: 24),
            if (visibleSections.isEmpty)
              const _EmptySessionCard()
            else
              ...visibleSections.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _SessionSectionCard(
                    section: entry.section,
                    items: entry.items,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
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
              onPressed: () => _openLiveWorkout(context),
              child: Text(
                'Start',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.425,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  final int exerciseCount;

  const _OverviewHeroCard({
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _overviewCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION OVERVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything queued for this workout, grouped by training block.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              exerciseCount.toString(),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSectionCard extends StatelessWidget {
  final ExerciseProgramSection section;
  final List<TrainingRecommendationItem> items;

  const _SessionSectionCard({
    required this.section,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final sectionColor = _overviewSectionColor(section);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: sectionColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              section.label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '${items.length} exercises',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SessionExerciseRow(
              item: item,
              sectionColor: sectionColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySessionCard extends StatelessWidget {
  const _EmptySessionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _overviewCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Text(
        'No exercises queued for this session.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SessionExerciseRow extends StatelessWidget {
  final TrainingRecommendationItem item;
  final Color sectionColor;

  const _SessionExerciseRow({
    required this.item,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    final skillCategory =
        SkillCategoryCatalog.findById(item.sourceSkillCategoryId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _overviewCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sectionColor.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              _overviewIsTimedExercise(item.exercise)
                  ? Icons.timer_outlined
                  : Icons.bar_chart_rounded,
              size: 17,
              color: sectionColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.track.label} · ${skillCategory?.title ?? item.exercise.category.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _overviewSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Text(
              _overviewDifficultyLabel(item.exercise.difficulty),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _overviewSectionColor(ExerciseProgramSection section) {
  switch (section) {
    case ExerciseProgramSection.warmup:
      return const Color(0xFF4ECDC4);
    case ExerciseProgramSection.skillWork:
      return const Color(0xFFA78BFA);
    case ExerciseProgramSection.mainExercises:
      return AppColors.accentPrimary;
    case ExerciseProgramSection.coolDown:
      return const Color(0xFF34D399);
  }
}

bool _overviewIsTimedExercise(Exercise exercise) {
  final name = exercise.name.toLowerCase();
  final description = exercise.description.toLowerCase();

  return name.contains('hold') ||
      name.contains('hang') ||
      name.contains('plank') ||
      name.contains('lever') ||
      name.contains('handstand') ||
      description.contains('for time');
}

String _overviewDifficultyLabel(int difficulty) {
  if (difficulty <= 1) return 'Beginner';
  if (difficulty <= 3) return 'Intermediate';
  return 'Advanced';
}
