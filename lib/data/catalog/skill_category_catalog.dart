import '../models/exercise_model.dart';
import '../models/skill_category_model.dart';

class SkillCategoryCatalog {
  SkillCategoryCatalog._();

  static const String pullupsId = 'pullups';
  static const String rowsId = 'rows';
  static const String pushupsId = 'pushups';
  static const String plancheId = 'planche';
  static const String squatId = 'squat';
  static const String lSitVSitId = 'l_sit_v_sit';
  static const String abWheelId = 'ab_wheel';
  static const String legRaisesId = 'leg_raises';
  static const String muscleUpId = 'muscle_up';
  static const String handstandPushupsId = 'handstand_pushups';
  static const String dipsId = 'dips';

  static const SkillCategory pullups = SkillCategory(
    id: pullupsId,
    title: 'Pullups',
    subtitle: 'Vertical Pull',
    description:
        'Build your pull-up strength through variations, weighted work, and one-arm progressions.',
    track: ExerciseCategory.verticalPull,
    defaultTrainingPathId: 'weighted',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
      SkillCategoryBranch(id: 'close_grip', label: 'Close Grip', lane: -1),
      SkillCategoryBranch(
        id: 'weighted',
        label: 'Weighted',
        lane: 1,
        isRecommended: true,
      ),
      SkillCategoryBranch(id: 'one_arm', label: 'One Arm', lane: 0),
      SkillCategoryBranch(id: 'l_sit', label: 'L-Sit', lane: 2),
    ],
    trainingPaths: {
      'weighted': [
        'scapular_pull',
        'arch_hang',
        'pull_up_negative',
        'assisted_pull_up',
        'pull_up',
        'weighted_pull_up_115',
        'weighted_pull_up_135',
        'weighted_pull_up_150',
        'weighted_pull_up_165',
        'weighted_pull_up_180',
        'weighted_pull_up_190',
        'weighted_pull_up_200',
      ],
      'close_grip': [
        'scapular_pull',
        'arch_hang',
        'pull_up_negative',
        'assisted_pull_up',
        'pull_up',
        'close_grip_pull_up',
        'wide_grip_pull_up',
        'typewriter_pull_up',
        'archer_pull_up',
        'sternum_pull_up',
        'belly_button_pull_up',
      ],
      'l_sit': [
        'scapular_pull',
        'arch_hang',
        'pull_up_negative',
        'assisted_pull_up',
        'pull_up',
        'l_sit_pull_up',
        'pull_over',
      ],
      'one_arm': [
        'scapular_pull',
        'arch_hang',
        'pull_up_negative',
        'assisted_pull_up',
        'pull_up',
        'close_grip_pull_up',
        'wide_grip_pull_up',
        'typewriter_pull_up',
        'archer_pull_up',
        'weighted_pull_up_115',
        'weighted_pull_up_135',
        'weighted_pull_up_150',
        'one_arm_towel_assisted_chin_up',
        'one_arm_pull_up_eccentric',
        'half_one_arm_chin_up',
        'one_arm_chin_up',
      ],
    },
  );

  static const SkillCategory rows = SkillCategory(
    id: rowsId,
    title: 'Rows',
    subtitle: 'Horizontal Pull',
    description:
        'Build your row strength from angle-based foundations into one-arm, front lever, or weighted row goals.',
    track: ExerciseCategory.horizontalPull,
    defaultTrainingPathId: 'front_lever',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
      SkillCategoryBranch(id: 'one_arm', label: 'One Arm', lane: -1),
      SkillCategoryBranch(id: 'front_lever', label: 'Front Lever', lane: 0),
      SkillCategoryBranch(id: 'weighted', label: 'Weighted', lane: 1),
    ],
    trainingPaths: {
      'front_lever': [
        'vertical_rows',
        'inverted_rows_bent_legs',
        'inverted_rows_straight_legs',
        'feet_elevated_rows',
        'horizontal_rows',
        'horizontal_wide_rows',
        'tuck_front_lever_rows_hold',
        'tuck_front_lever_rows',
        'advanced_tuck_front_lever_rows',
        'one_leg_tuck_one_extended_front_lever_rows',
        'straddle_front_lever_rows',
        'front_lever_rows',
      ],
      'one_arm': [
        'vertical_rows',
        'inverted_rows_bent_legs',
        'inverted_rows_straight_legs',
        'feet_elevated_rows',
        'horizontal_rows',
        'horizontal_wide_rows',
        'archer_rows',
        'bulgarian_rows',
        'one_arm_rows',
      ],
      'weighted': [
        'vertical_rows',
        'inverted_rows_bent_legs',
        'inverted_rows_straight_legs',
        'feet_elevated_rows',
        'horizontal_rows',
        'horizontal_wide_rows',
        'weighted_rows_bodyweight_3x10',
        'weighted_rows_plus_10',
        'weighted_rows_plus_20',
        'weighted_rows_plus_35',
        'weighted_rows_plus_50',
        'weighted_rows_plus_75',
        'weighted_rows_plus_bodyweight',
      ],
    },
  );

  static const SkillCategory pushups = SkillCategory(
    id: pushupsId,
    title: 'Pushups',
    subtitle: 'Horizontal Push',
    description:
        'Build your pushup strength from foundation work into one-arm, ring, or planche pushing goals.',
    track: ExerciseCategory.horizontalPush,
    defaultTrainingPathId: 'one_arm',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
      SkillCategoryBranch(
        id: 'one_arm',
        label: 'One Arm',
        lane: -1,
        isRecommended: true,
      ),
      SkillCategoryBranch(id: 'rings', label: 'Rings', lane: 0),
      SkillCategoryBranch(id: 'planche', label: 'Planche', lane: 1),
    ],
    trainingPaths: {
      'one_arm': [
        'wall_push_up',
        'incline_push_up',
        'push_up',
        'elbows_in_push_up',
        'decline_push_up',
        'diamond_push_up',
        'uneven_push_up',
        'archer_push_up',
        'incline_one_arm_push_up',
        'one_arm_push_up',
      ],
      'rings': [
        'wall_push_up',
        'incline_push_up',
        'push_up',
        'elbows_in_push_up',
        'decline_push_up',
        'diamond_push_up',
        'ring_wide_push_up',
        'ring_push_up',
        'rto_push_up',
        'rto_archer_push_up',
        'rto_pseudo_planche_push_up_lower_chest',
        'rto_pseudo_planche_push_up_belly_button',
        'rto_pseudo_planche_push_up_hips',
      ],
      'planche': [
        'wall_push_up',
        'incline_push_up',
        'push_up',
        'elbows_in_push_up',
        'decline_push_up',
        'diamond_push_up',
        'pseudo_planche_push_up_lower_chest',
        'pseudo_planche_push_up_belly_button',
        'pseudo_planche_push_up_hips',
        'tuck_planche_push_up',
        'advanced_tuck_planche_push_up',
        'straddle_planche_push_up',
        'planche_push_up',
      ],
    },
  );

  static const SkillCategory planche = SkillCategory(
    id: plancheId,
    title: 'Planche',
    subtitle: 'Horizontal Push',
    description:
        'Build planche-specific hold strength from leans into tuck, straddle, and full planche positions.',
    track: ExerciseCategory.horizontalPush,
    defaultTrainingPathId: 'main',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'planche_lean_just_past',
        'planche_lean_moderate',
        'planche_lean_far_past',
        'tuck_planche_lean',
        'tuck_planche_hold',
        'advanced_tuck_planche_hold',
        'straddle_planche_wide',
        'straddle_planche_medium',
        'straddle_planche_narrow',
        'full_planche_hold',
      ],
    },
  );

  static const SkillCategory squat = SkillCategory(
    id: squatId,
    title: 'Squat',
    subtitle: 'Squat',
    description:
        'Build leg strength from assisted squats into pistol squat and shrimp squat progressions.',
    track: ExerciseCategory.squat,
    defaultTrainingPathId: 'pistol',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
      SkillCategoryBranch(id: 'pistol', label: 'Pistol', lane: -1),
      SkillCategoryBranch(id: 'shrimp', label: 'Shrimp', lane: 1),
    ],
    trainingPaths: {
      'pistol': [
        'assisted_squat',
        'deep_assisted_squat',
        'squat',
        'deep_squat',
        'bulgarian_split_squat',
        'box_pistol_squat_knee_height',
        'box_pistol_squat_mid_calf_height',
        'assisted_pistol_squat',
        'counter_weighted_pistol_squat',
        'pistol_squat',
      ],
      'shrimp': [
        'assisted_squat',
        'deep_assisted_squat',
        'squat',
        'deep_squat',
        'bulgarian_split_squat',
        'beginner_shrimp_squat',
        'intermediate_shrimp_squat',
        'advanced_shrimp_squat',
      ],
    },
  );

  static const SkillCategory lSitVSit = SkillCategory(
    id: lSitVSitId,
    title: 'L-sit / V-sit',
    subtitle: 'Core',
    description:
        'Build compression and support strength from a foot-supported L-sit into a full V-sit.',
    track: ExerciseCategory.core,
    defaultTrainingPathId: 'main',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'foot_supported_l_sit',
        'l_sit_tuck',
        'advanced_tuck_l_sit',
        'l_sit',
        'straddle_l_sit',
        'v_sit',
      ],
    },
  );

  static const SkillCategory abWheel = SkillCategory(
    id: abWheelId,
    title: 'Ab Wheel',
    subtitle: 'Core',
    description:
        'Build anti-extension strength from planks into kneeling, eccentric, and full ab wheel rollouts.',
    track: ExerciseCategory.core,
    defaultTrainingPathId: 'main',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'plank',
        'plank_60s',
        'one_arm_one_leg_plank',
        'ab_wheel_kneeling',
        'ab_wheel_eccentric',
        'ab_wheel_standing',
      ],
    },
  );

  static const SkillCategory legRaises = SkillCategory(
    id: legRaisesId,
    title: 'Leg Raises',
    subtitle: 'Core',
    description:
        'Progress from lying knee raises into straight-leg hanging raises with strong pelvic control.',
    track: ExerciseCategory.core,
    defaultTrainingPathId: 'main',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'lying_knee_raises',
        'bent_leg_lying_leg_raises',
        'straight_leg_lying_leg_raises',
        'hanging_knee_raises',
        'bent_leg_hanging_leg_raises',
        'straight_leg_hanging_leg_raises',
      ],
    },
  );

  static const SkillCategory muscleUp = SkillCategory(
    id: muscleUpId,
    title: 'Muscle-up',
    subtitle: 'Standalone Skill',
    description:
        'Build the transition from false-grip pulling into controlled negatives, kip, and a full muscle-up.',
    track: ExerciseCategory.skill,
    defaultTrainingPathId: 'main',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'false_grip_pull_ups',
        'muscle_up_negatives',
        'kipping_muscle_up',
        'muscle_up',
      ],
    },
  );

  static const SkillCategory handstandPushups = SkillCategory(
    id: handstandPushupsId,
    title: 'Handstand Pushups',
    subtitle: 'Vertical Push',
    description:
        'Progress from pike pressing into wall-supported handstand pushups and eventually freestanding reps.',
    track: ExerciseCategory.verticalPush,
    defaultTrainingPathId: 'main',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'pike_push_up',
        'box_push_up',
        'wall_headstand_push_up_eccentrics',
        'wall_headstand_push_up',
        'wall_handstand_push_up',
        'free_headstand_push_up',
        'free_handstand_push_up',
      ],
    },
    unlockRequirement: SkillCategoryUnlockRequirement(
      exerciseId: 'diamond_push_up',
      message:
          'This tree is locked until you unlock Diamond Pushup in the Pushups track.',
      ctaLabel: 'Go to Pushups',
      targetSkillCategoryId: pushupsId,
    ),
  );

  static const SkillCategory dips = SkillCategory(
    id: dipsId,
    title: 'Dips',
    subtitle: 'Vertical Push',
    description:
        'Build pressing strength from bench dips into parallel bar, weighted, and ring dip goals.',
    track: ExerciseCategory.verticalPush,
    defaultTrainingPathId: 'weighted',
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
      SkillCategoryBranch(id: 'route_a', label: 'Route A', lane: -1),
      SkillCategoryBranch(id: 'weighted', label: 'Weighted', lane: -1),
      SkillCategoryBranch(id: 'rings', label: 'Rings', lane: 1),
    ],
    trainingPaths: {
      'weighted': [
        'bench_dips',
        'dip_negatives',
        'parallel_bar_dips',
        'weighted_dips_120',
        'weighted_dips_140',
        'weighted_dips_160',
        'weighted_dips_180',
        'weighted_dips_200',
      ],
      'rings': [
        'bench_dips',
        'dip_negatives',
        'parallel_bar_dips',
        'ring_dips',
        'ring_dips_rto',
      ],
    },
  );

  static const List<SkillCategory> _custom = [
    pullups,
    rows,
    pushups,
    planche,
    squat,
    lSitVSit,
    abWheel,
    legRaises,
    muscleUp,
    handstandPushups,
    dips,
  ];

  // Some tracks can exist for training-program purposes without being exposed
  // as browsable skill trees.
  static const Set<ExerciseCategory> _hiddenSkillTracks = {
    ExerciseCategory.hinge,
    ExerciseCategory.skill,
  };

  static List<SkillCategory> browsable() {
    final categories = <SkillCategory>[
      ..._custom,
      for (final track in ExerciseCategory.values)
        if (!_hiddenSkillTracks.contains(track) &&
            !_custom.any((category) => category.track == track))
          SkillCategory(
            id: track.id,
            title: track.label,
            subtitle: track.label,
            description:
                'Track your progress in ${track.label.toLowerCase()} exercises.',
            track: track,
            defaultTrainingPathId: 'main',
            branches: const [
              SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
            ],
          ),
    ];

    return categories;
  }

  static List<SkillCategory> all() {
    final categories = <SkillCategory>[
      ..._custom,
      for (final track in ExerciseCategory.values)
        if (!_hiddenSkillTracks.contains(track) &&
            !_custom.any((category) => category.track == track))
          SkillCategory(
            id: track.id,
            title: track.label,
            subtitle: track.label,
            description:
                'Track your progress in ${track.label.toLowerCase()} exercises.',
            track: track,
            defaultTrainingPathId: 'main',
            branches: const [
              SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
            ],
          ),
    ];

    return categories;
  }

  static SkillCategory? findById(String id) {
    for (final category in all()) {
      if (category.id == id) return category;
    }
    return null;
  }

  static List<SkillCategory> forTrack(ExerciseCategory track) =>
      all().where((category) => category.track == track).toList();

  static bool isBrowsableId(String id) =>
      browsable().any((category) => category.id == id);

  static SkillCategory defaultForTrack(ExerciseCategory track) {
    for (final category in all()) {
      if (category.track == track) {
        return category;
      }
    }

    return SkillCategory(
      id: track.id,
      title: track.label,
      subtitle: track.label,
      description:
          'Track your progress in ${track.label.toLowerCase()} exercises.',
      track: track,
      defaultTrainingPathId: 'main',
      branches: const [
        SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
      ],
    );
  }
}
