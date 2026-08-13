/// Old exercise ids, and the tree step each became.
///
/// The sheet gave every step an id that names its tree, so `pull_up` became
/// `pullups_pull_up`. Progress, logs and program days already stored under the
/// old ids have to keep pointing at the same step, so they are read through
/// this on the way in.
///
/// Only the skill-tree steps are here. The library was replaced wholesale and
/// its old ids have no counterpart to map to.
class ExerciseIdMigration {
  ExerciseIdMigration._();

  static const Map<String, String> _renamed = {
    'scapular_pull': 'pullups_scapular_pull',
    'arch_hang': 'pullups_pull_up_negative',
    'pullups_arch_hang': 'pullups_pull_up_negative',
    'pull_up_negative': 'pullups_pull_up_negative',
    'assisted_pull_up': 'pullups_assisted_pull_up',
    'pull_up': 'pullups_pull_up',
    'close_grip_pull_up': 'pullups_close_grip_pull_up',
    'wide_grip_pull_up': 'pullups_wide_grip_pull_up',
    'typewriter_pull_up': 'pullups_typewriter_pull_up',
    'archer_pull_up': 'pullups_archer_pull_up',
    'sternum_pull_up': 'pullups_sternum_pull_up',
    'belly_button_pull_up': 'pullups_belly_button_pull_up',
    'weighted_pull_up_115': 'pullups_weighted_pull_up_115',
    'weighted_pull_up_135': 'pullups_weighted_pull_up_135',
    'weighted_pull_up_150': 'pullups_weighted_pull_up_150',
    'weighted_pull_up_165': 'pullups_weighted_pull_up_165',
    'weighted_pull_up_180': 'pullups_weighted_pull_up_180',
    'weighted_pull_up_190': 'pullups_weighted_pull_up_190',
    'weighted_pull_up_200': 'pullups_weighted_pull_up_200',
    'l_sit_pull_up': 'pullups_l_sit_pull_up',
    'pull_over': 'pullups_pull_over',
    'one_arm_towel_assisted_chin_up': 'pullups_one_arm_towel_assisted_chin_up',
    'one_arm_pull_up_eccentric': 'pullups_one_arm_pull_up_eccentric',
    'half_one_arm_chin_up': 'pullups_half_one_arm_chin_up',
    'one_arm_chin_up': 'pullups_one_arm_chin_up',
    'pike_push_up': 'handstand_pushups_pike_push_up',
    'box_push_up': 'handstand_pushups_box_push_up',
    'wall_headstand_push_up_eccentrics':
        'handstand_pushups_wall_headstand_push_up_eccentrics',
    'wall_headstand_push_up': 'handstand_pushups_wall_headstand_push_up',
    'wall_handstand_push_up': 'handstand_pushups_wall_handstand_push_up',
    'free_headstand_push_up': 'handstand_pushups_free_headstand_push_up',
    'free_handstand_push_up': 'handstand_pushups_free_handstand_push_up',
    'bench_dips': 'dips_bench_dips',
    'dip_negatives': 'dips_dip_negatives',
    'parallel_bar_dips': 'dips_parallel_bar_dips',
    'weighted_dips_120': 'dips_weighted_dips_120',
    'weighted_dips_140': 'dips_weighted_dips_140',
    'weighted_dips_160': 'dips_weighted_dips_160',
    'weighted_dips_180': 'dips_weighted_dips_180',
    'weighted_dips_200': 'dips_weighted_dips_200',
    'ring_dips': 'dips_ring_dips',
    'ring_dips_rto': 'dips_ring_dips_rto',
    'vertical_rows': 'rows_vertical_rows',
    'inverted_rows_bent_legs': 'rows_inverted_rows_bent_legs',
    'inverted_rows_straight_legs': 'rows_inverted_rows_straight_legs',
    'feet_elevated_rows': 'rows_feet_elevated_rows',
    'horizontal_rows': 'rows_horizontal_wide_rows',
    'rows_horizontal_rows': 'rows_horizontal_wide_rows',
    'horizontal_wide_rows': 'rows_horizontal_wide_rows',
    'archer_rows': 'rows_archer_rows',
    'bulgarian_rows': 'rows_bulgarian_rows',
    'one_arm_rows': 'rows_one_arm_rows',
    'tuck_front_lever_rows_hold': 'rows_tuck_front_lever_rows_hold',
    'tuck_front_lever_rows': 'rows_tuck_front_lever_rows',
    'advanced_tuck_front_lever_rows': 'rows_advanced_tuck_front_lever_rows',
    'one_leg_tuck_one_extended_front_lever_rows':
        'rows_one_leg_tuck_one_extended_front_lever_rows',
    'straddle_front_lever_rows': 'rows_straddle_front_lever_rows',
    'front_lever_rows': 'rows_front_lever_rows',
    'weighted_rows_bodyweight_3x10': 'rows_weighted_rows_bodyweight_3x10',
    'weighted_rows_plus_10': 'rows_weighted_rows_plus_10',
    'weighted_rows_plus_20': 'rows_weighted_rows_plus_20',
    'weighted_rows_plus_35': 'rows_weighted_rows_plus_35',
    'weighted_rows_plus_50': 'rows_weighted_rows_plus_50',
    'weighted_rows_plus_75': 'rows_weighted_rows_plus_75',
    'weighted_rows_plus_bodyweight': 'rows_weighted_rows_plus_bodyweight',
    'wall_push_up': 'pushups_wall_push_up',
    'incline_push_up': 'pushups_incline_push_up',
    'push_up': 'pushups_push_up',
    'elbows_in_push_up': 'pushups_elbows_in_push_up',
    'decline_push_up': 'pushups_diamond_push_up',
    'pushups_decline_push_up': 'pushups_diamond_push_up',
    'diamond_push_up': 'pushups_diamond_push_up',
    'uneven_push_up': 'pushups_uneven_push_up',
    'archer_push_up': 'pushups_archer_push_up',
    'incline_one_arm_push_up': 'pushups_incline_one_arm_push_up',
    'one_arm_push_up': 'pushups_one_arm_push_up',
    'ring_wide_push_up': 'pushups_ring_wide_push_up',
    'ring_push_up': 'pushups_ring_push_up',
    'rto_push_up': 'pushups_rto_push_up',
    'rto_archer_push_up': 'pushups_rto_archer_push_up',
    'rto_pseudo_planche_push_up_lower_chest':
        'pushups_rto_pseudo_planche_push_up_lower_chest',
    'rto_pseudo_planche_push_up_belly_button':
        'pushups_rto_pseudo_planche_push_up_belly_button',
    'rto_pseudo_planche_push_up_hips':
        'pushups_rto_pseudo_planche_push_up_hips',
    'pseudo_planche_push_up_lower_chest':
        'pushups_pseudo_planche_push_up_lower_chest',
    'pseudo_planche_push_up_belly_button':
        'pushups_pseudo_planche_push_up_belly_button',
    'pseudo_planche_push_up_hips': 'pushups_pseudo_planche_push_up_hips',
    'tuck_planche_push_up': 'pushups_tuck_planche_push_up',
    'advanced_tuck_planche_push_up': 'pushups_advanced_tuck_planche_push_up',
    'straddle_planche_push_up': 'pushups_straddle_planche_push_up',
    'planche_push_up': 'pushups_planche_push_up',
    'planche_lean_just_past': 'planche_planche_lean_just_past',
    'planche_lean_moderate': 'planche_planche_lean_moderate',
    'planche_lean_far_past': 'planche_planche_lean_far_past',
    'tuck_planche_lean': 'planche_tuck_planche_lean',
    'tuck_planche_hold': 'planche_tuck_planche_hold',
    'advanced_tuck_planche_hold': 'planche_advanced_tuck_planche_hold',
    'straddle_planche_wide': 'planche_straddle_planche_wide',
    'straddle_planche_medium': 'planche_straddle_planche_medium',
    'straddle_planche_narrow': 'planche_straddle_planche_narrow',
    'full_planche_hold': 'planche_full_planche_hold',
    'assisted_squat': 'squat_assisted_squat',
    'deep_assisted_squat': 'squat_deep_assisted_squat',
    'squat': 'squat_squat',
    'deep_squat': 'squat_deep_squat',
    'bulgarian_split_squat': 'squat_bulgarian_split_squat',
    'single_leg_rdl': 'hinge_single_leg_rdl',
    'barbell_squat': 'barbell_squat_barbell_squat',
    'romanian_deadlift': 'hinge_romanian_deadlift_barbell',
    'box_pistol_squat_knee_height': 'squat_box_pistol_squat_knee_height',
    'nordic_curl': 'hinge_nordic_curl',
    // The hinge slot's pre-tree steps, replaced when it grew into a real
    // progression: the loaded RDL became the weighted ladder's bar step, and
    // both Nordic steps the ladder's final curl.
    'hinge_romanian_deadlift': 'hinge_romanian_deadlift_barbell',
    'hinge_nordic_nordic_curl': 'hinge_nordic_curl',
    'hinge_posterior_chain_nordic_curl': 'hinge_nordic_curl',
    'box_pistol_squat_mid_calf_height':
        'squat_box_pistol_squat_mid_calf_height',
    'beginner_shrimp_squat': 'squat_beginner_shrimp_squat',
    'assisted_pistol_squat': 'squat_assisted_pistol_squat',
    'intermediate_shrimp_squat': 'squat_intermediate_shrimp_squat',
    'counter_weighted_pistol_squat': 'squat_counter_weighted_pistol_squat',
    'advanced_shrimp_squat': 'squat_advanced_shrimp_squat',
    'pistol_squat': 'squat_pistol_squat',
    'lying_knee_raises': 'core_lying_knee_raises',
    'foot_supported_l_sit': 'core_foot_supported_l_sit',
    'plank': 'core_plank',
    'bent_leg_lying_leg_raises': 'core_bent_leg_lying_leg_raises',
    'l_sit_tuck': 'core_l_sit_tuck',
    'plank_60s': 'core_plank_60s',
    'straight_leg_lying_leg_raises': 'core_straight_leg_lying_leg_raises',
    'advanced_tuck_l_sit': 'core_advanced_tuck_l_sit',
    'one_arm_one_leg_plank': 'core_one_arm_one_leg_plank',
    'hanging_knee_raises': 'core_hanging_knee_raises',
    'l_sit': 'core_l_sit',
    'ab_wheel_kneeling': 'core_ab_wheel_kneeling',
    'bent_leg_hanging_leg_raises': 'core_bent_leg_hanging_leg_raises',
    'straddle_l_sit': 'core_straddle_l_sit',
    'ab_wheel_eccentric': 'core_ab_wheel_eccentric',
    'straight_leg_hanging_leg_raises': 'core_straight_leg_hanging_leg_raises',
    'v_sit': 'core_v_sit',
    'ab_wheel_standing': 'core_ab_wheel_standing',
    'false_grip_pull_ups': 'muscle_up_false_grip_pull_ups',
    'muscle_up_negatives': 'muscle_up_muscle_up_negatives',
    'kipping_muscle_up': 'muscle_up_kipping_muscle_up',
    'muscle_up': 'muscle_up_muscle_up',
  };

  /// Every id that was renamed.
  static Iterable<String> get renamedIds => _renamed.keys;

  /// The current id for [id], which is [id] itself unless it is one of the
  /// old names.
  static String resolve(String id) => _renamed[id] ?? id;

  /// Re-keys anything stored per exercise id.
  static Map<String, T> resolveKeys<T>(Map<String, T> stored) =>
      {for (final entry in stored.entries) resolve(entry.key): entry.value};
}
