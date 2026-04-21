import '../models/exercise_model.dart';

class ExerciseCatalog {
  ExerciseCatalog._();

  static const List<Exercise> _all = [
    // ── Vertical Pull ─────────────────────────────────────────────────────
    Exercise(
      id: 'dead_hang',
      category: ExerciseCategory.verticalPull,
      name: 'Dead Hang',
      description:
          'Hang from a bar with straight arms for time. Builds grip strength and shoulder stability.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'scapular_pull',
      category: ExerciseCategory.verticalPull,
      name: 'Scapular Pull',
      description:
          'From a dead hang, retract and depress your shoulder blades without bending your elbows.',
      difficulty: 1,
      treeOrder: 1,
      prerequisiteIds: ['dead_hang'],
    ),
    Exercise(
      id: 'negative_pull_up',
      category: ExerciseCategory.verticalPull,
      name: 'Negative Pull-up',
      description:
          'Jump to the top position and lower yourself slowly with control over 3–5 seconds.',
      difficulty: 2,
      treeOrder: 2,
      prerequisiteIds: ['scapular_pull'],
    ),
    Exercise(
      id: 'pull_up',
      category: ExerciseCategory.verticalPull,
      name: 'Pull-up',
      description:
          'Full pull-up with pronated grip from dead hang to chin over bar.',
      difficulty: 3,
      treeOrder: 3,
      prerequisiteIds: ['negative_pull_up'],
    ),
    Exercise(
      id: 'chin_up',
      category: ExerciseCategory.verticalPull,
      name: 'Chin-up',
      description:
          'Pull-up with supinated (underhand) grip, emphasising the biceps.',
      difficulty: 3,
      treeOrder: 3,
      prerequisiteIds: ['negative_pull_up'],
    ),
    Exercise(
      id: 'archer_pull_up',
      category: ExerciseCategory.verticalPull,
      name: 'Archer Pull-up',
      description:
          'Pull to one side while the opposite arm extends, loading one arm significantly more.',
      difficulty: 4,
      treeOrder: 4,
      prerequisiteIds: ['pull_up'],
    ),
    Exercise(
      id: 'weighted_pull_up',
      category: ExerciseCategory.verticalPull,
      name: 'Weighted Pull-up',
      description: 'Standard pull-up with added weight via belt or vest.',
      difficulty: 4,
      treeOrder: 4,
      prerequisiteIds: ['pull_up'],
    ),
    Exercise(
      id: 'one_arm_negative',
      category: ExerciseCategory.verticalPull,
      name: 'One Arm Negative',
      description:
          'Start at the top with one arm and lower yourself as slowly as possible.',
      difficulty: 5,
      treeOrder: 5,
      prerequisiteIds: ['archer_pull_up'],
    ),
    Exercise(
      id: 'one_arm_pull_up',
      category: ExerciseCategory.verticalPull,
      name: 'One Arm Pull-up',
      description:
          'The ultimate pulling feat — a full pull-up using a single arm.',
      difficulty: 5,
      treeOrder: 6,
      prerequisiteIds: ['one_arm_negative'],
    ),

    // ── Vertical Push ─────────────────────────────────────────────────────
    Exercise(
      id: 'wall_plank',
      category: ExerciseCategory.verticalPush,
      name: 'Wall Plank',
      description:
          'Hold a plank position with feet on a wall to practise a vertical body line.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'pike_push_up',
      category: ExerciseCategory.verticalPush,
      name: 'Pike Push-up',
      description:
          'Push-up in an inverted-V position, targeting the shoulders like a vertical press.',
      difficulty: 2,
      treeOrder: 1,
      prerequisiteIds: ['wall_plank'],
    ),
    Exercise(
      id: 'elevated_pike_push_up',
      category: ExerciseCategory.verticalPush,
      name: 'Elevated Pike Push-up',
      description:
          'Pike push-up with feet elevated to increase shoulder loading.',
      difficulty: 3,
      treeOrder: 2,
      prerequisiteIds: ['pike_push_up'],
    ),
    Exercise(
      id: 'wall_handstand',
      category: ExerciseCategory.verticalPush,
      name: 'Wall Handstand',
      description: 'Hold a handstand with your back against the wall for time.',
      difficulty: 3,
      treeOrder: 2,
      prerequisiteIds: ['pike_push_up'],
    ),
    Exercise(
      id: 'wall_hspu',
      category: ExerciseCategory.verticalPush,
      name: 'Wall HSPU',
      description: 'Handstand push-up with feet supported on the wall.',
      difficulty: 4,
      treeOrder: 3,
      prerequisiteIds: ['elevated_pike_push_up', 'wall_handstand'],
    ),
    Exercise(
      id: 'freestanding_handstand',
      category: ExerciseCategory.verticalPush,
      name: 'Freestanding Handstand',
      description: 'Hold a balanced handstand away from the wall.',
      difficulty: 4,
      treeOrder: 3,
      prerequisiteIds: ['wall_handstand'],
    ),
    Exercise(
      id: 'freestanding_hspu',
      category: ExerciseCategory.verticalPush,
      name: 'Freestanding HSPU',
      description: 'Press to and from a handstand without wall support.',
      difficulty: 5,
      treeOrder: 4,
      prerequisiteIds: ['wall_hspu', 'freestanding_handstand'],
    ),

    // ── Horizontal Pull ───────────────────────────────────────────────────
    Exercise(
      id: 'table_row',
      category: ExerciseCategory.horizontalPull,
      name: 'Table Row',
      description: 'Row using a table edge with your body at a shallow angle.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'incline_row',
      category: ExerciseCategory.horizontalPull,
      name: 'Incline Row',
      description: 'Row at a steeper incline using rings or a bar.',
      difficulty: 2,
      treeOrder: 1,
      prerequisiteIds: ['table_row'],
    ),
    Exercise(
      id: 'australian_pull_up',
      category: ExerciseCategory.horizontalPull,
      name: 'Australian Pull-up',
      description:
          'Bodyweight row with body horizontal, also called a supine row.',
      difficulty: 2,
      treeOrder: 2,
      prerequisiteIds: ['incline_row'],
    ),
    Exercise(
      id: 'tuck_front_lever',
      category: ExerciseCategory.horizontalPull,
      name: 'Tuck Front Lever',
      description: 'Hold a tucked front lever position on a bar or rings.',
      difficulty: 3,
      treeOrder: 3,
      prerequisiteIds: ['australian_pull_up'],
    ),
    Exercise(
      id: 'adv_tuck_front_lever',
      category: ExerciseCategory.horizontalPull,
      name: 'Adv. Tuck Front Lever',
      description: 'Front lever with hips extended to a flatter position.',
      difficulty: 4,
      treeOrder: 4,
      prerequisiteIds: ['tuck_front_lever'],
    ),
    Exercise(
      id: 'straddle_front_lever',
      category: ExerciseCategory.horizontalPull,
      name: 'Straddle Front Lever',
      description: 'Front lever with legs straddled wide to reduce load.',
      difficulty: 4,
      treeOrder: 4,
      prerequisiteIds: ['adv_tuck_front_lever'],
    ),
    Exercise(
      id: 'front_lever',
      category: ExerciseCategory.horizontalPull,
      name: 'Front Lever',
      description:
          'Full front lever with legs together, body parallel to the ground.',
      difficulty: 5,
      treeOrder: 5,
      prerequisiteIds: ['straddle_front_lever'],
    ),

    // ── Horizontal Push ───────────────────────────────────────────────────
    Exercise(
      id: 'wall_push_up',
      category: ExerciseCategory.horizontalPush,
      name: 'Wall Push-up',
      description:
          'Push-up against a wall — the most accessible starting point.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'incline_push_up',
      category: ExerciseCategory.horizontalPush,
      name: 'Incline Push-up',
      description: 'Push-up with hands elevated on a bench or box.',
      difficulty: 1,
      treeOrder: 1,
      prerequisiteIds: ['wall_push_up'],
    ),
    Exercise(
      id: 'push_up',
      category: ExerciseCategory.horizontalPush,
      name: 'Push-up',
      description: 'Standard push-up from the floor with full range of motion.',
      difficulty: 2,
      treeOrder: 2,
      prerequisiteIds: ['incline_push_up'],
    ),
    Exercise(
      id: 'diamond_push_up',
      category: ExerciseCategory.horizontalPush,
      name: 'Diamond Push-up',
      description: 'Push-up with hands close together to target triceps.',
      difficulty: 3,
      treeOrder: 3,
      prerequisiteIds: ['push_up'],
    ),
    Exercise(
      id: 'archer_push_up',
      category: ExerciseCategory.horizontalPush,
      name: 'Archer Push-up',
      description:
          'Push-up where one arm extends while the other does the work.',
      difficulty: 3,
      treeOrder: 3,
      prerequisiteIds: ['push_up'],
    ),
    Exercise(
      id: 'planche_lean',
      category: ExerciseCategory.horizontalPush,
      name: 'Planche Lean',
      description:
          'Lean forward in a plank position to shift load onto the wrists and shoulders.',
      difficulty: 3,
      treeOrder: 3,
      prerequisiteIds: ['push_up'],
    ),
    Exercise(
      id: 'tuck_planche',
      category: ExerciseCategory.horizontalPush,
      name: 'Tuck Planche',
      description: 'Hold body horizontal with knees tucked to chest.',
      difficulty: 4,
      treeOrder: 4,
      prerequisiteIds: ['planche_lean'],
    ),
    Exercise(
      id: 'one_arm_push_up',
      category: ExerciseCategory.horizontalPush,
      name: 'One Arm Push-up',
      description: 'Push-up using only one arm.',
      difficulty: 4,
      treeOrder: 4,
      prerequisiteIds: ['archer_push_up'],
    ),
    Exercise(
      id: 'full_planche',
      category: ExerciseCategory.horizontalPush,
      name: 'Full Planche',
      description:
          'Hold the full planche with body horizontal and legs straight.',
      difficulty: 5,
      treeOrder: 5,
      prerequisiteIds: ['tuck_planche'],
    ),

    // ── Squat ─────────────────────────────────────────────────────────────
    Exercise(
      id: 'squat',
      category: ExerciseCategory.squat,
      name: 'Squat',
      description: 'Bodyweight squat with full depth and controlled tempo.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'lunge',
      category: ExerciseCategory.squat,
      name: 'Lunge',
      description:
          'Forward or reverse lunge, building unilateral strength and balance.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'bulgarian_split_squat',
      category: ExerciseCategory.squat,
      name: 'Bulgarian Split Squat',
      description:
          'Rear foot elevated split squat — a demanding unilateral movement.',
      difficulty: 2,
      treeOrder: 1,
      prerequisiteIds: ['squat'],
    ),
    Exercise(
      id: 'single_leg_rdl',
      category: ExerciseCategory.hinge,
      name: 'Single Leg RDL',
      description: 'Hinge on one leg to train hamstrings and balance.',
      difficulty: 2,
      treeOrder: 0,
    ),
    Exercise(
      id: 'pistol_squat_neg',
      category: ExerciseCategory.squat,
      name: 'Pistol Squat Negative',
      description:
          'Lower slowly on one leg, using support if needed for the ascent.',
      difficulty: 3,
      treeOrder: 2,
      prerequisiteIds: ['bulgarian_split_squat'],
    ),
    Exercise(
      id: 'nordic_curl',
      category: ExerciseCategory.hinge,
      name: 'Nordic Curl',
      description:
          'Anchor feet and lower your body to the floor under hamstring control.',
      difficulty: 3,
      treeOrder: 1,
      prerequisiteIds: ['single_leg_rdl'],
    ),
    Exercise(
      id: 'pistol_squat',
      category: ExerciseCategory.squat,
      name: 'Pistol Squat',
      description: 'Full single-leg squat to depth and back up.',
      difficulty: 4,
      treeOrder: 3,
      prerequisiteIds: ['pistol_squat_neg'],
    ),
    Exercise(
      id: 'shrimp_squat',
      category: ExerciseCategory.squat,
      name: 'Shrimp Squat',
      description: 'Single-leg squat with the back leg bent up behind you.',
      difficulty: 4,
      treeOrder: 3,
      prerequisiteIds: ['pistol_squat_neg'],
    ),
    Exercise(
      id: 'dragon_squat',
      category: ExerciseCategory.squat,
      name: 'Dragon Squat',
      description:
          'Advanced single-leg squat crossing the free leg behind the standing leg.',
      difficulty: 5,
      treeOrder: 4,
      prerequisiteIds: ['pistol_squat', 'shrimp_squat'],
    ),

    // ── Calves ────────────────────────────────────────────────────────────
    Exercise(
      id: 'calf_raise',
      category: ExerciseCategory.calves,
      name: 'Calf Raise',
      description:
          'Controlled standing calf raises to build ankle strength and lower-leg endurance.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'single_leg_calf_raise',
      category: ExerciseCategory.calves,
      name: 'Single Leg Calf Raise',
      description:
          'Perform calf raises one leg at a time for more load and balance demand.',
      difficulty: 2,
      treeOrder: 1,
      prerequisiteIds: ['calf_raise'],
    ),

    // ── Core ──────────────────────────────────────────────────────────────
    Exercise(
      id: 'plank',
      category: ExerciseCategory.core,
      name: 'Plank',
      description:
          'Hold a straight body position on forearms and toes for time.',
      difficulty: 1,
      treeOrder: 0,
    ),
    Exercise(
      id: 'hollow_body',
      category: ExerciseCategory.core,
      name: 'Hollow Body Hold',
      description:
          'Supine hold with lower back pressed to the floor, arms and legs elevated.',
      difficulty: 1,
      treeOrder: 0,
      programSection: ExerciseProgramSection.skillWork,
    ),
    Exercise(
      id: 'ab_wheel_kneeling',
      category: ExerciseCategory.core,
      name: 'Ab Wheel (kneeling)',
      description:
          'Roll the ab wheel out from a kneeling position and return with control.',
      difficulty: 2,
      treeOrder: 1,
      prerequisiteIds: ['plank'],
    ),
    Exercise(
      id: 'l_sit_tuck',
      category: ExerciseCategory.core,
      name: 'L-sit Tuck',
      description:
          'Support yourself on parallel bars or rings with knees tucked.',
      difficulty: 2,
      treeOrder: 1,
      prerequisiteIds: ['hollow_body'],
      programSection: ExerciseProgramSection.skillWork,
    ),
    Exercise(
      id: 'dragon_flag_neg',
      category: ExerciseCategory.core,
      name: 'Dragon Flag Neg.',
      description:
          'Lower your straight body from vertical to horizontal under control.',
      difficulty: 3,
      treeOrder: 2,
      prerequisiteIds: ['ab_wheel_kneeling'],
    ),
    Exercise(
      id: 'l_sit',
      category: ExerciseCategory.core,
      name: 'L-sit',
      description:
          'Hold legs straight and parallel to the floor on parallel bars or rings.',
      difficulty: 3,
      treeOrder: 2,
      prerequisiteIds: ['l_sit_tuck'],
      programSection: ExerciseProgramSection.skillWork,
    ),
    Exercise(
      id: 'ab_wheel_standing',
      category: ExerciseCategory.core,
      name: 'Ab Wheel (standing)',
      description:
          'Full standing ab wheel rollout — extreme anti-extension demand.',
      difficulty: 4,
      treeOrder: 3,
      prerequisiteIds: ['dragon_flag_neg'],
    ),
    Exercise(
      id: 'dragon_flag',
      category: ExerciseCategory.core,
      name: 'Dragon Flag',
      description:
          'Full dragon flag, lowering and raising the body while keeping it perfectly straight.',
      difficulty: 4,
      treeOrder: 3,
      prerequisiteIds: ['dragon_flag_neg'],
    ),
    Exercise(
      id: 'v_sit',
      category: ExerciseCategory.core,
      name: 'V-sit',
      description:
          'Hold an L-sit with legs raised above horizontal forming a V shape.',
      difficulty: 5,
      treeOrder: 4,
      prerequisiteIds: ['l_sit'],
      programSection: ExerciseProgramSection.skillWork,
    ),
  ];

  static List<Exercise> all() => _all;

  static List<Exercise> forCategory(ExerciseCategory category) =>
      _all.where((e) => e.category == category).toList()
        ..sort((a, b) => a.treeOrder.compareTo(b.treeOrder));

  static int totalForCategory(ExerciseCategory category) =>
      _all.where((e) => e.category == category).length;

  static Exercise? findById(String id) {
    for (final exercise in _all) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }
}
