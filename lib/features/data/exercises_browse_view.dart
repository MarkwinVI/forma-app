import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/workout_history_model.dart';
import '../exercises/exercise_detail_view.dart';
import '../home/program_day_items.dart' show programPatternIcon;

/// Searchable list of every browsable exercise; rows open the exercise
/// detail view on its Summary tab.
class ExercisesBrowseView extends StatefulWidget {
  final List<PastWorkout> workouts;

  const ExercisesBrowseView({
    super.key,
    required this.workouts,
  });

  @override
  State<ExercisesBrowseView> createState() => _ExercisesBrowseViewState();
}

class _ExercisesBrowseViewState extends State<ExercisesBrowseView> {
  final _controller = TextEditingController();
  late final Map<String, String> _lastLoggedLabels = _buildLastLoggedLabels();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Newest-first workouts → the first match per exercise is its most
  /// recent log; label it with the best set of that session.
  Map<String, String> _buildLastLoggedLabels() {
    final labels = <String, String>{};
    for (final workout in widget.workouts) {
      for (final exercise in workout.exercises) {
        if (labels.containsKey(exercise.exerciseId) || exercise.sets.isEmpty) {
          continue;
        }
        final bestSet = exercise.sets.reduce(
          (a, b) => b.value > a.value ? b : a,
        );
        labels[exercise.exerciseId] = bestSet.isTimed
            ? '${bestSet.value}s hold'
            : '${bestSet.value} reps';
      }
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final exercises = ExerciseCatalog.browsable()
        .where(
          (exercise) =>
              query.isEmpty || exercise.name.toLowerCase().contains(query),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SubScreenHeader(
              title: 'Exercises',
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search exercises',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      Pressable(
                        onTap: _controller.clear,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: exercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises match your search.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 44),
                      children: [
                        SurfaceCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              for (var i = 0; i < exercises.length; i++)
                                _ExerciseRow(
                                  exercise: exercises[i],
                                  lastLogged:
                                      _lastLoggedLabels[exercises[i].id],
                                  showDivider: i > 0,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final String? lastLogged;
  final bool showDivider;

  const _ExerciseRow({
    required this.exercise,
    required this.lastLogged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => openExerciseDetailView<void>(
        context,
        exercise: exercise,
        initialTab: ExerciseDetailTab.summary,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            IconTile(icon: programPatternIcon(exercise.category), size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    exercise.category.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (lastLogged != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastLogged!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'last logged',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
