import '../models/exercise_model.dart';
import '../models/skill_category_model.dart';

class SkillCategoryCatalog {
  SkillCategoryCatalog._();

  static const String pullupsId = 'pullups';
  static const String rowsId = 'rows';
  static const String pushupsId = 'pushups';
  static const String plancheId = 'planche';
  static const String squatId = 'squat';
  static const String coreId = 'core';
  static const String lSitVSitId = 'l_sit_v_sit';
  static const String abWheelId = 'ab_wheel';
  static const String legRaisesId = 'leg_raises';
  static const String muscleUpId = 'muscle_up';
  static const String handstandPushupsId = 'handstand_pushups';
  static const String dipsId = 'dips';
  static const String barbellSquatId = 'barbell_squat';
  static const String hingeId = 'hinge';

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
        'pullups_scapular_pull',
        'pullups_arch_hang',
        'pullups_pull_up_negative',
        'pullups_assisted_pull_up',
        'pullups_pull_up',
        'pullups_weighted_pull_up_115',
        'pullups_weighted_pull_up_135',
        'pullups_weighted_pull_up_150',
        'pullups_weighted_pull_up_165',
        'pullups_weighted_pull_up_180',
        'pullups_weighted_pull_up_190',
        'pullups_weighted_pull_up_200',
      ],
      'close_grip': [
        'pullups_scapular_pull',
        'pullups_arch_hang',
        'pullups_pull_up_negative',
        'pullups_assisted_pull_up',
        'pullups_pull_up',
        'pullups_close_grip_pull_up',
        'pullups_wide_grip_pull_up',
        'pullups_typewriter_pull_up',
        'pullups_archer_pull_up',
        'pullups_sternum_pull_up',
        'pullups_belly_button_pull_up',
      ],
      'l_sit': [
        'pullups_scapular_pull',
        'pullups_arch_hang',
        'pullups_pull_up_negative',
        'pullups_assisted_pull_up',
        'pullups_pull_up',
        'pullups_l_sit_pull_up',
        'pullups_pull_over',
      ],
      'one_arm': [
        'pullups_scapular_pull',
        'pullups_arch_hang',
        'pullups_pull_up_negative',
        'pullups_assisted_pull_up',
        'pullups_pull_up',
        'pullups_one_arm_towel_assisted_chin_up',
        'pullups_one_arm_pull_up_eccentric',
        'pullups_half_one_arm_chin_up',
        'pullups_one_arm_chin_up',
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
        'rows_vertical_rows',
        'rows_inverted_rows_bent_legs',
        'rows_inverted_rows_straight_legs',
        'rows_feet_elevated_rows',
        'rows_horizontal_rows',
        'rows_horizontal_wide_rows',
        'rows_tuck_front_lever_rows_hold',
        'rows_tuck_front_lever_rows',
        'rows_advanced_tuck_front_lever_rows',
        'rows_one_leg_tuck_one_extended_front_lever_rows',
        'rows_straddle_front_lever_rows',
        'rows_front_lever_rows',
      ],
      'one_arm': [
        'rows_vertical_rows',
        'rows_inverted_rows_bent_legs',
        'rows_inverted_rows_straight_legs',
        'rows_feet_elevated_rows',
        'rows_horizontal_rows',
        'rows_horizontal_wide_rows',
        'rows_archer_rows',
        'rows_bulgarian_rows',
        'rows_one_arm_rows',
      ],
      'weighted': [
        'rows_vertical_rows',
        'rows_inverted_rows_bent_legs',
        'rows_inverted_rows_straight_legs',
        'rows_feet_elevated_rows',
        'rows_horizontal_rows',
        'rows_horizontal_wide_rows',
        'rows_weighted_rows_bodyweight_3x10',
        'rows_weighted_rows_plus_10',
        'rows_weighted_rows_plus_20',
        'rows_weighted_rows_plus_35',
        'rows_weighted_rows_plus_50',
        'rows_weighted_rows_plus_75',
        'rows_weighted_rows_plus_bodyweight',
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
    defaultTrainingPathId: 'planche',
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
        'pushups_wall_push_up',
        'pushups_incline_push_up',
        'pushups_push_up',
        'pushups_elbows_in_push_up',
        'pushups_decline_push_up',
        'pushups_diamond_push_up',
        'pushups_uneven_push_up',
        'pushups_archer_push_up',
        'pushups_incline_one_arm_push_up',
        'pushups_one_arm_push_up',
      ],
      'rings': [
        'pushups_wall_push_up',
        'pushups_incline_push_up',
        'pushups_push_up',
        'pushups_elbows_in_push_up',
        'pushups_decline_push_up',
        'pushups_diamond_push_up',
        'pushups_ring_wide_push_up',
        'pushups_ring_push_up',
        'pushups_rto_push_up',
        'pushups_rto_archer_push_up',
        'pushups_rto_pseudo_planche_push_up_lower_chest',
        'pushups_rto_pseudo_planche_push_up_belly_button',
        'pushups_rto_pseudo_planche_push_up_hips',
      ],
      'planche': [
        'pushups_wall_push_up',
        'pushups_incline_push_up',
        'pushups_push_up',
        'pushups_elbows_in_push_up',
        'pushups_decline_push_up',
        'pushups_diamond_push_up',
        'pushups_pseudo_planche_push_up_lower_chest',
        'pushups_pseudo_planche_push_up_belly_button',
        'pushups_pseudo_planche_push_up_hips',
        'pushups_tuck_planche_push_up',
        'pushups_advanced_tuck_planche_push_up',
        'pushups_straddle_planche_push_up',
        'pushups_planche_push_up',
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
        'planche_planche_lean_just_past',
        'planche_planche_lean_moderate',
        'planche_planche_lean_far_past',
        'planche_tuck_planche_lean',
        'planche_tuck_planche_hold',
        'planche_advanced_tuck_planche_hold',
        'planche_straddle_planche_wide',
        'planche_straddle_planche_medium',
        'planche_straddle_planche_narrow',
        'planche_full_planche_hold',
      ],
    },
    unlockRequirement: SkillCategoryUnlockRequirement(
      exerciseId: 'pushups_diamond_push_up',
      message:
          'This tree is locked until you unlock Diamond Pushup in the Pushups track.',
      ctaLabel: 'Go to Pushups',
      targetSkillCategoryId: pushupsId,
    ),
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
        'squat_assisted_squat',
        'squat_deep_assisted_squat',
        'squat_squat',
        'squat_deep_squat',
        'squat_bulgarian_split_squat',
        'squat_box_pistol_squat_knee_height',
        'squat_box_pistol_squat_mid_calf_height',
        'squat_assisted_pistol_squat',
        'squat_counter_weighted_pistol_squat',
        'squat_pistol_squat',
      ],
      'shrimp': [
        'squat_assisted_squat',
        'squat_deep_assisted_squat',
        'squat_squat',
        'squat_deep_squat',
        'squat_bulgarian_split_squat',
        'squat_beginner_shrimp_squat',
        'squat_intermediate_shrimp_squat',
        'squat_advanced_shrimp_squat',
      ],
    },
  );

  static const SkillCategory core = SkillCategory(
    id: coreId,
    title: 'Core',
    subtitle: 'Core',
    description:
        'Train your core through three parallel branches: compression holds, ab wheel strength, and leg raise control.',
    track: ExerciseCategory.core,
    defaultTrainingPathId: 'l_sit',
    branches: [
      SkillCategoryBranch(id: 'l_sit', label: 'L-Sit / V-Sit', lane: -1),
      SkillCategoryBranch(
        id: 'ab_wheel',
        label: 'Ab Wheel',
        lane: 0,
        isRecommended: true,
      ),
      SkillCategoryBranch(id: 'leg_raises', label: 'Leg Raises', lane: 1),
    ],
    trainingPaths: {
      'l_sit': [
        'core_foot_supported_l_sit',
        'core_l_sit_tuck',
        'core_advanced_tuck_l_sit',
        'core_l_sit',
        'core_straddle_l_sit',
        'core_v_sit',
      ],
      'ab_wheel': [
        'core_plank',
        'core_plank_60s',
        'core_one_arm_one_leg_plank',
        'core_ab_wheel_kneeling',
        'core_ab_wheel_eccentric',
        'core_ab_wheel_standing',
      ],
      'leg_raises': [
        'core_lying_knee_raises',
        'core_bent_leg_lying_leg_raises',
        'core_straight_leg_lying_leg_raises',
        'core_hanging_knee_raises',
        'core_bent_leg_hanging_leg_raises',
        'core_straight_leg_hanging_leg_raises',
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
        'muscle_up_false_grip_pull_ups',
        'muscle_up_muscle_up_negatives',
        'muscle_up_kipping_muscle_up',
        'muscle_up_muscle_up',
      ],
    },
    unlockRequirement: SkillCategoryUnlockRequirement(
      exerciseId: 'pullups_pull_up',
      message:
          'This tree is locked until you unlock Pull-up in the Pullups track.',
      ctaLabel: 'Go to Pullups',
      targetSkillCategoryId: pullupsId,
    ),
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
        'handstand_pushups_pike_push_up',
        'handstand_pushups_box_push_up',
        'handstand_pushups_wall_headstand_push_up_eccentrics',
        'handstand_pushups_wall_headstand_push_up',
        'handstand_pushups_wall_handstand_push_up',
        'handstand_pushups_free_headstand_push_up',
        'handstand_pushups_free_handstand_push_up',
      ],
    },
    unlockRequirement: SkillCategoryUnlockRequirement(
      exerciseId: 'pushups_diamond_push_up',
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
        'dips_bench_dips',
        'dips_dip_negatives',
        'dips_parallel_bar_dips',
        'dips_weighted_dips_120',
        'dips_weighted_dips_140',
        'dips_weighted_dips_160',
        'dips_weighted_dips_180',
        'dips_weighted_dips_200',
      ],
      'rings': [
        'dips_bench_dips',
        'dips_dip_negatives',
        'dips_parallel_bar_dips',
        'dips_ring_dips',
        'dips_ring_dips_rto',
      ],
    },
  );

  /// The knee-dominant slot when the user has a gym and no squat-tree goal:
  /// one loaded lift rather than a progression to climb.
  static const SkillCategory barbellSquat = SkillCategory(
    id: barbellSquatId,
    title: 'Barbell Squat',
    subtitle: 'Squat',
    description:
        'Train the knee-dominant slot with a loaded squat for 3 × 5 working sets.',
    track: ExerciseCategory.squat,
    defaultTrainingPathId: 'main',
    isBrowsable: false,
    branches: [
      SkillCategoryBranch(id: 'main', label: 'Main', lane: 0),
    ],
    trainingPaths: {
      'main': [
        'barbell_squat_barbell_squat',
      ],
    },
  );

  /// The hinge slot. Which branch a program runs is an equipment question:
  /// a Romanian deadlift with a gym, a Nordic curl without one.
  /// `posterior_chain` is the pair programs used before that split, kept so
  /// existing programs keep training exactly what they were training.
  static const SkillCategory hinge = SkillCategory(
    id: hingeId,
    title: 'Hinge',
    subtitle: 'Hinge',
    description:
        'Balance the knee-dominant work with hamstring and posterior-chain training.',
    track: ExerciseCategory.hinge,
    defaultTrainingPathId: 'nordic',
    isBrowsable: false,
    branches: [
      SkillCategoryBranch(id: 'rdl', label: 'Romanian Deadlift', lane: 0),
      SkillCategoryBranch(id: 'nordic', label: 'Nordic Curl', lane: 1),
      SkillCategoryBranch(
        id: 'posterior_chain',
        label: 'Posterior Chain',
        lane: -1,
      ),
    ],
    trainingPaths: {
      'rdl': [
        'hinge_romanian_deadlift',
      ],
      'nordic': [
        'hinge_nordic_nordic_curl',
      ],
      'posterior_chain': [
        'hinge_single_leg_rdl',
        'hinge_posterior_chain_nordic_curl',
      ],
    },
  );

  static const List<SkillCategory> _custom = [
    pullups,
    rows,
    pushups,
    planche,
    squat,
    core,
    muscleUp,
    handstandPushups,
    dips,
    barbellSquat,
    hinge,
  ];

  // Some tracks can exist for training-program purposes without being exposed
  // as browsable skill trees.
  static const Set<ExerciseCategory> _hiddenSkillTracks = {
    ExerciseCategory.hinge,
    ExerciseCategory.skill,
    // Accessory work from the general library is not a tree: there is nothing
    // to climb, so it has no level to show on Progress.
    ExerciseCategory.other,
  };

  static List<SkillCategory> browsable() {
    final categories = <SkillCategory>[
      for (final category in _custom)
        if (category.isBrowsable) category,
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
