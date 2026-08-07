import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'data/catalog/skill_category_catalog.dart';
import 'data/models/exercise_model.dart';
import 'data/models/skill_track_model.dart';
import 'features/home/goal_wheel_picker.dart';
import 'features/home/program_setup_view.dart';
import 'features/progress/skill_wheel_data.dart';
import 'features/progress/widgets/skill_wheel.dart';
import 'features/progress/widgets/skill_wheel_screen.dart';

/// Dev probe for the radial skill wheel — the Progress tab's wheel screen
/// with mocked statuses, no auth or network. Run with:
///   flutter run -t lib/dev_skill_wheel_main.dart
void main() => runApp(const _WheelProbeApp());

/// A believable mid-journey state: several trees under way, one on a branch,
/// one with skipped steps, planche/HSPU/dips still gated or untouched.
Map<String, ExerciseStatus> _mockProgress() {
  const mastered = ExerciseStatus.mastered;
  const active = ExerciseStatus.active;
  const skipped = ExerciseStatus.skipped;

  final map = <String, ExerciseStatus>{};

  void walk(String categoryId, String branchId, int cleared,
      {bool thenActive = true, Set<int> skip = const {}}) {
    final category = SkillCategoryCatalog.findById(categoryId)!;
    final path = category.pathFor(branchId);
    for (var i = 0; i < path.length; i++) {
      if (i < cleared) {
        map[path[i]] = skip.contains(i) ? skipped : mastered;
      } else if (i == cleared && thenActive) {
        map[path[i]] = active;
        break;
      } else {
        break;
      }
    }
  }

  // Pullups: foundation cleared (one step skipped), working the weighted
  // branch.
  walk(SkillCategoryCatalog.pullupsId, 'weighted', 6, skip: {3});
  // Rows: deep into the front lever path.
  walk(SkillCategoryCatalog.rowsId, 'front_lever', 6);
  // Pushups: mid-foundation.
  walk(SkillCategoryCatalog.pushupsId, 'planche', 3);
  // Squat: just started.
  walk(SkillCategoryCatalog.squatId, 'pistol', 0);
  // Core: L-sit branch nearly done.
  walk(SkillCategoryCatalog.coreId, 'l_sit', 5);
  // Muscle-up: unlocked by the pull-up, first step cleared.
  walk(SkillCategoryCatalog.muscleUpId, 'main', 1);
  // Planche, HSPU: still locked behind the diamond pushup. Dips: untouched.
  return map;
}

List<SkillTrack> _mockTracks() {
  final now = DateTime.now();
  SkillTrack track(String categoryId, String branchId) => SkillTrack(
        skillCategoryId: categoryId,
        branchId: branchId,
        included: true,
        updatedAt: now,
      );
  return [
    track(SkillCategoryCatalog.pullupsId, 'weighted'),
    track(SkillCategoryCatalog.rowsId, 'front_lever'),
    track(SkillCategoryCatalog.pushupsId, 'planche'),
    track(SkillCategoryCatalog.squatId, 'pistol'),
    track(SkillCategoryCatalog.coreId, 'l_sit'),
    track(SkillCategoryCatalog.muscleUpId, 'main'),
  ];
}

class _WheelProbeApp extends StatelessWidget {
  const _WheelProbeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: const _WheelProbeScreen(),
    );
  }
}

class _WheelProbeScreen extends StatefulWidget {
  const _WheelProbeScreen();

  @override
  State<_WheelProbeScreen> createState() => _WheelProbeScreenState();
}

class _WheelProbeScreenState extends State<_WheelProbeScreen> {
  late final Map<String, ExerciseStatus> _progress = _mockProgress();
  late final List<WheelFamily> _families = buildWheelFamilies(
    progressMap: _progress,
    skillTracks: _mockTracks(),
  );

  /// Which screen the probe is showing: the Progress tab or program setup's
  /// goal step, both drawn on the same wheel.
  bool _picker = false;
  final List<String> _picked = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.surface,
        onPressed: () => setState(() => _picker = !_picker),
        label: Text(
          _picker ? 'Progress' : 'Goal picker',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _picker
            ? GoalWheelPicker(
                picked: _picked,
                lockedNotes: const {
                  'hspu': 'Unlock Diamond Pushup in the Pushups track',
                },
                progressMap: _progress,
                onToggleSkill: (id) => setState(() {
                  _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
                }),
                options: [
                  for (final skill in kGoalSkillOptions)
                    (id: skill.id, label: skill.label),
                ],
              )
            : SkillWheelScreen(
                families: _families,
                onOpenExercise: (_) {},
              ),
      ),
    );
  }
}
