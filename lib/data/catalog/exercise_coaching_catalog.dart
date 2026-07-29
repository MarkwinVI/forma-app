/// What the exercise detail view says about a movement: how to do it, what
/// every rep has to pass, and the demo that shows it.
///
/// Kept apart from [ExerciseCatalog], which says where a movement sits in a
/// tree. Both are generated from the same exercise sheet, but this is the
/// half a reader looks at and that half changes on its own schedule.
class ExerciseCoaching {
  /// Ordered steps, read as a numbered list. Three for most movements, four
  /// where the barbell lifts need a separate setup step.
  final List<String> howTo;

  /// The short lines every rep is judged against.
  final List<String> formChecks;

  /// YouTube demo for the movement. Some steps of a weighted ladder share
  /// one clip — there is a single demo of a weighted pull-up, not seven.
  final String videoUrl;

  /// Still frame, used until the video is ready and whenever it cannot load.
  final String imageUrl;

  const ExerciseCoaching({
    required this.howTo,
    required this.formChecks,
    required this.videoUrl,
    required this.imageUrl,
  });
}

class ExerciseCoachingCatalog {
  ExerciseCoachingCatalog._();

  static const Map<String, ExerciseCoaching> _byId = {
    'scapular_pull': ExerciseCoaching(
      howTo: [
        'Hang from the bar with straight arms and the shoulders relaxed up by the ears.',
        'Without bending the elbows, pull the shoulder blades down and together until the body rises an inch or two.',
        'Pause at the top, then lower back into a fully relaxed hang.',
      ],
      formChecks: [
        'Elbows stay straight',
        'Move only the shoulder blades',
        'Pause at the top of each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=kCoCVLZvI8E',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Scapular_Pull-Up/0.jpg',
    ),
    'arch_hang': ExerciseCoaching(
      howTo: [
        'Hang from the bar and pull the shoulder blades down away from the ears.',
        'Arch the chest toward the bar while looking up, and hold the shape briefly.',
        'Return to a hollow hang and alternate between the two positions.',
      ],
      formChecks: [
        'Chest up toward the bar',
        'Shoulders stay pulled down',
        'Alternate hollow and arch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KoOKCFtU-Zc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Scapular_Pull-Up/0.jpg',
    ),
    'pull_up_negative': ExerciseCoaching(
      howTo: [
        'Jump or step up so the chin starts above the bar.',
        'Lower yourself over three to five seconds until the arms are straight.',
        'Step down, reset, and start the next rep from the top again.',
      ],
      formChecks: [
        'Three to five seconds down',
        'Finish with straight arms',
        'Step down and reset each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zr_NfZk1O4w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'assisted_pull_up': ExerciseCoaching(
      howTo: [
        'Loop a band under the knee or foot, or rest one foot on a low box.',
        'Pull to full range with the chin over the bar, using only as much help as you need.',
        'Lower to straight arms, and reduce the assistance as you get stronger.',
      ],
      formChecks: [
        'Use the least help that works',
        'Full range every rep',
        'Drop the assistance as you get stronger',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=B_VkNQS5YLs',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Band_Assisted_Pull-Up/0.jpg',
    ),
    'pull_up': ExerciseCoaching(
      howTo: [
        'Hang from the bar with an overhand grip at shoulder width.',
        'Pull until the chin clears the bar, keeping the body quiet.',
        'Lower all the way to straight arms under control.',
      ],
      formChecks: [
        'Chin fully over the bar',
        'Lower to straight arms',
        'Keep the body from swinging',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UH30Wm_KAl8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'close_grip_pull_up': ExerciseCoaching(
      howTo: [
        'Take an overhand grip narrower than shoulder width.',
        'Pull to the bar keeping the elbows close to the body.',
        'Lower to a full hang before the next rep.',
      ],
      formChecks: [
        'Hands inside shoulder width',
        'Elbows brush the ribs',
        'Full hang at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dhdfTfEP8cU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'wide_grip_pull_up': ExerciseCoaching(
      howTo: [
        'Take an overhand grip wider than shoulder width.',
        'Pull the chest toward the bar while keeping the shoulders pulled down.',
        'Lower to straight arms without shortening the range.',
      ],
      formChecks: [
        'Hands wider than the shoulders',
        'Lead with the chest',
        'Do not shorten the range',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IK3sH7wOAWE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'typewriter_pull_up': ExerciseCoaching(
      howTo: [
        'Pull to the top with a wide grip.',
        'Shift sideways over one hand while the other arm straightens.',
        'Travel back across the bar, then lower under control.',
      ],
      formChecks: [
        'Stay high while you travel',
        'Straighten the trailing arm',
        'Even reps on both sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=TVT5Ro_g1Go',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'archer_pull_up': ExerciseCoaching(
      howTo: [
        'Pull up with a wide grip.',
        'Travel toward one hand while the opposite arm stays straight along the bar.',
        'Lower under control and alternate sides each rep.',
      ],
      formChecks: [
        'One arm straight like drawing a bow',
        'Pull high before you shift',
        'Alternate sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=73lhGA-Okkc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'sternum_pull_up': ExerciseCoaching(
      howTo: [
        'Pull explosively while leaning back away from the bar.',
        'Keep pulling until the bar meets the lower chest.',
        'Drive the elbows down and behind you at the top, then lower.',
      ],
      formChecks: [
        'Bar touches the lower chest',
        'Lean back at the top',
        'Drive the elbows down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=PmdNNN8nLGI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'belly_button_pull_up': ExerciseCoaching(
      howTo: [
        'Lean back hard and pull as high as you can.',
        'Keep the bar travelling toward the navel rather than the chin.',
        'Keep the pull smooth — no kipping into position.',
      ],
      formChecks: [
        'Bar aims for the navel',
        'Big lean back',
        'No kip',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=-XXuIwW56Zw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'weighted_pull_up_115': ExerciseCoaching(
      howTo: [
        'Wear a belt or vest holding about fifteen percent of your bodyweight.',
        'Pull full range from a hang to chin over the bar, for sets of three to five.',
        'Add weight in small steps once the range holds up.',
      ],
      formChecks: [
        'Full hang to chin over bar',
        'Sets of three to five',
        'Add weight in small steps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'weighted_pull_up_135': ExerciseCoaching(
      howTo: [
        'Load the belt to roughly thirty five percent of bodyweight.',
        'Warm up to the load in steps rather than jumping straight to it.',
        'Hold the same full range as unweighted and control every descent.',
      ],
      formChecks: [
        'Same range as unweighted',
        'Control the descent',
        'Warm up in steps to the load',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'weighted_pull_up_150': ExerciseCoaching(
      howTo: [
        'Carry half your bodyweight on the belt.',
        'Pull full range from a full hang each rep.',
        'Keep the reps crisp and stop the set when they slow.',
      ],
      formChecks: [
        'Half bodyweight added',
        'Full hang each rep',
        'Keep the reps crisp',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'weighted_pull_up_165': ExerciseCoaching(
      howTo: [
        'Load about sixty five percent of bodyweight on the belt.',
        'Pull clean full-range reps with no kipping.',
        'Rest fully between sets — this is heavy work.',
      ],
      formChecks: [
        'Heavy but full range',
        'No kipping',
        'Rest fully between sets',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'weighted_pull_up_180': ExerciseCoaching(
      howTo: [
        'Carry about eighty percent of bodyweight on the belt.',
        'Brace the core so the body does not swing under the load.',
        'Hold full range, and build toward this over weeks rather than sessions.',
      ],
      formChecks: [
        'Full range under heavy load',
        'Brace the core to stop swinging',
        'Build up over weeks',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'weighted_pull_up_190': ExerciseCoaching(
      howTo: [
        'Load about ninety percent of bodyweight — near double your own.',
        'Pull from a full hang to chin over the bar.',
        'Take long rests between sets.',
      ],
      formChecks: [
        'Near double bodyweight',
        'Full hang to chin over bar',
        'Long rests between sets',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'weighted_pull_up_200': ExerciseCoaching(
      howTo: [
        'Carry a full bodyweight on the belt so the total load is double your own.',
        'Keep every rep full range with no cut at the bottom or top.',
        'Treat this as the close of the pulling ladder — years of loading, not months.',
      ],
      formChecks: [
        'Double bodyweight total load',
        'No range cut',
        'Years of loading, not months',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J3JW_cPynwI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Weighted_Pull_Ups/0.jpg',
    ),
    'l_sit_pull_up': ExerciseCoaching(
      howTo: [
        'Hang from the bar and lift both legs straight out in front at hip height.',
        'Pull full range without letting the legs drop or the body swing.',
        'End the set as soon as the legs start to sag.',
      ],
      formChecks: [
        'Legs stay parallel to the floor',
        'No swinging',
        'Drop the set when the legs sag',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LoiAKbaOwl8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'pull_over': ExerciseCoaching(
      howTo: [
        'Pull hard until the bar reaches the waist.',
        'Lean the shoulders forward over the bar early.',
        'Rotate over the bar into a straight-arm support, keeping the bar close.',
      ],
      formChecks: [
        'Pull to the waist before rotating',
        'Lean the shoulders over early',
        'Keep the bar close to the body',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ExqodKpe8lw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pullups/0.jpg',
    ),
    'one_arm_towel_assisted_chin_up': ExerciseCoaching(
      howTo: [
        'Hang a towel over the bar next to your working hand.',
        'Grip the towel as low as you can with the free hand.',
        'Pull with the working arm, letting the towel hand give only light help.',
      ],
      formChecks: [
        'Grip the towel as low as you can',
        'Working arm does the work',
        'Even sets on both sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LP99wdTXP_Q',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Chin-Up/0.jpg',
    ),
    'one_arm_pull_up_eccentric': ExerciseCoaching(
      howTo: [
        'Start at the top with one arm and the chin over the bar.',
        'Lower as slowly as you can through the full range until the arm is straight.',
        'Stop the set once the descent turns into a drop.',
      ],
      formChecks: [
        'Start at the top',
        'Fight the whole way down',
        'Stop when the descent turns into a drop',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=zUU4g31auEI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Chin-Up/0.jpg',
    ),
    'half_one_arm_chin_up': ExerciseCoaching(
      howTo: [
        'Grip the bar with one hand in a supinated grip.',
        'Pull through the top half of the range only.',
        'Lower under control and rest before the next rep.',
      ],
      formChecks: [
        'Work the top half of the range',
        'Supinated grip',
        'Even work on both arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=qkIp4kUG5w4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Chin-Up/0.jpg',
    ),
    'one_arm_chin_up': ExerciseCoaching(
      howTo: [
        'Hang from one hand with a supinated grip.',
        'Pull until the chin clears the bar, resisting the twist.',
        'Lower all the way to a straight arm.',
      ],
      formChecks: [
        'Chin fully over the bar',
        'Resist the twist',
        'Full straight arm at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Nj1NvN7Te_s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/One_Arm_Chin-Up/0.jpg',
    ),
    'pike_push_up': ExerciseCoaching(
      howTo: [
        'From a pushup position, walk the feet in so the hips lift into an upside-down V.',
        'Bend the elbows to lower the crown of the head toward the floor.',
        'Press back up with the elbows tracking forward.',
      ],
      formChecks: [
        'Hips high, body in a V',
        'Head lowers between the hands',
        'Elbows track forward',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=x7_I5SUAd00',
      imageUrl:
          'https://img.youtube.com/vi/x7_I5SUAd00/hqdefault.jpg',
    ),
    'box_push_up': ExerciseCoaching(
      howTo: [
        'Put the feet on a box so the hips stack higher over the shoulders.',
        'Lower the head toward the floor between the hands.',
        'Press back up, keeping the elbows tracking forward.',
      ],
      formChecks: [
        'Higher box means more vertical load',
        'Stack the hips over the shoulders',
        'Head between the hands',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=iEn2EdmP4V4',
      imageUrl:
          'https://img.youtube.com/vi/iEn2EdmP4V4/hqdefault.jpg',
    ),
    'wall_headstand_push_up_eccentrics': ExerciseCoaching(
      howTo: [
        'Kick up to a handstand with the heels resting on the wall.',
        'Lower over three to five seconds until the head touches the floor between the hands.',
        'Come down off the wall and reset instead of pressing back up.',
      ],
      formChecks: [
        'Three to five seconds down',
        'Head lands between the hands',
        'Come off the wall to reset',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=glPLvcCwNyE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Handstand_Push-Ups/0.jpg',
    ),
    'wall_headstand_push_up': ExerciseCoaching(
      howTo: [
        'Set up in a wall handstand with the hands and head forming a triangle.',
        'Lower until the head touches the floor between the hands.',
        'Press evenly with both arms back to straight, keeping the ribs down.',
      ],
      formChecks: [
        'Head and hands make a triangle',
        'Press evenly with both arms',
        'Keep the ribs down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7TDsXo4-taM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Handstand_Push-Ups/0.jpg',
    ),
    'wall_handstand_push_up': ExerciseCoaching(
      howTo: [
        'Kick up to a wall handstand with the hands on parallettes or blocks.',
        'Lower until the head passes below the hands.',
        'Press all the way back to a locked-out handstand with the body straight.',
      ],
      formChecks: [
        'Full range below the hands',
        'Lock the elbows at the top',
        'Keep the body straight, not arched',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=lkPPVyExFpU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Handstand_Push-Ups/0.jpg',
    ),
    'free_headstand_push_up': ExerciseCoaching(
      howTo: [
        'Kick up to a freestanding handstand.',
        'Lower under control until the head touches the floor.',
        'Press back up, correcting the balance with the fingertips.',
      ],
      formChecks: [
        'Balance with the fingertips',
        'Lower under control',
        'Bail to the side if you lose it',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UpenGNGXETc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Handstand_Push-Ups/0.jpg',
    ),
    'free_handstand_push_up': ExerciseCoaching(
      howTo: [
        'Hold a freestanding handstand with no wall at any point.',
        'Lower to full depth, keeping the body line tight.',
        'Press back to straight arms, correcting balance with the fingers throughout.',
      ],
      formChecks: [
        'No wall at any point',
        'Full depth then full lockout',
        'Keep the body line tight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=w6ORorYVm70',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Handstand_Push-Ups/0.jpg',
    ),
    'bench_dips': ExerciseCoaching(
      howTo: [
        'Sit on a bench with the hands beside the hips and the feet on the floor in front.',
        'Slide off the edge and lower until the elbows reach a right angle.',
        'Press back up, keeping the hips close to the bench and the elbows pointing back.',
      ],
      formChecks: [
        'Elbows point back, not out',
        'Keep the hips close to the bench',
        'Stop at ninety degrees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=uZm3RYM25TI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bench_Dips/0.jpg',
    ),
    'dip_negatives': ExerciseCoaching(
      howTo: [
        'Jump or step to the top of the parallel bars with straight arms.',
        'Lower over three to five seconds until the shoulders reach elbow height.',
        'Step off and reset for the next rep.',
      ],
      formChecks: [
        'Three to five seconds down',
        'Elbows stay close to the body',
        'Step off and reset each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_po_lMeNcAQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'parallel_bar_dips': ExerciseCoaching(
      howTo: [
        'Support yourself on parallel bars with straight arms and a tall chest.',
        'Lower until the shoulders drop to elbow height, elbows close to the body.',
        'Press back up to a locked-out top position.',
      ],
      formChecks: [
        'Lower until shoulders reach elbow height',
        'Elbows close to the body',
        'Lock out at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=U7HeutDqS_w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'weighted_dips_120': ExerciseCoaching(
      howTo: [
        'Wear a dip belt loaded to about twenty percent of your bodyweight.',
        'Dip through full depth for sets of three.',
        'Add weight only once the depth holds.',
      ],
      formChecks: [
        'Full depth even with load',
        'Sets of three',
        'Add weight only when the depth holds',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZ_kEpmACZ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'weighted_dips_140': ExerciseCoaching(
      howTo: [
        'Load the belt to roughly forty percent of bodyweight.',
        'Keep the reps smooth and the depth the same as unweighted.',
        'Stop the set when the speed drops.',
      ],
      formChecks: [
        'Same depth as unweighted',
        'Crisp triples',
        'Stop the set when speed drops',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZ_kEpmACZ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'weighted_dips_160': ExerciseCoaching(
      howTo: [
        'Add about sixty percent of bodyweight to the belt.',
        'Set the shoulders before you lift the feet.',
        'Press through full range to a full lockout, elbows tracking back.',
      ],
      formChecks: [
        'Set the shoulders before you lift the feet',
        'Full lockout each rep',
        'Keep the elbows tracking back',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZ_kEpmACZ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'weighted_dips_180': ExerciseCoaching(
      howTo: [
        'Warm up in steps to about eighty percent of bodyweight on the belt.',
        'Hold the same depth and control as the lighter sets.',
        'Rest fully between sets — a rep short of depth does not count.',
      ],
      formChecks: [
        'Warm up in steps to this load',
        'Full depth or the rep does not count',
        'Rest fully between sets',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZ_kEpmACZ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'weighted_dips_200': ExerciseCoaching(
      howTo: [
        'Carry a full bodyweight on the belt so the total load is double your own.',
        'Dip through full range with the elbows tracking back.',
        'Build to this slowly to protect the shoulders — it closes the dip ladder.',
      ],
      formChecks: [
        'Double bodyweight total load',
        'Full range, no half reps',
        'Build slowly to protect the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=UZ_kEpmACZ4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Parallel_Bar_Dip/0.jpg',
    ),
    'ring_dips': ExerciseCoaching(
      howTo: [
        'Support on rings with straight arms and the rings held close to the hips.',
        'Lower under control to the bottom.',
        'Press back up while stopping the rings from drifting out.',
      ],
      formChecks: [
        'Keep the rings pinned near the hips',
        'Slow and controlled',
        'Straight arms at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dHKvF9zODqI',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ring_Dips/0.jpg',
    ),
    'ring_dips_rto': ExerciseCoaching(
      howTo: [
        'Dip on rings as normal, keeping the elbows in.',
        'Finish each press by turning the rings out so the palms face forward.',
        'Hold that turnout for a moment before the next rep.',
      ],
      formChecks: [
        'Turn the rings out at the top',
        'Elbows stay in',
        'Start with a short turned out hold',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=m71NuzJ0GUE',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ring_Dips/0.jpg',
    ),
    'vertical_rows': ExerciseCoaching(
      howTo: [
        'Set a bar or rings at chest height and hold on with the body almost upright.',
        'Walk the feet forward a little to add load.',
        'Pull the chest to the bar, squeeze the shoulder blades, then lower under control.',
      ],
      formChecks: [
        'Body near upright',
        'Pull the chest to the bar',
        'Squeeze the shoulder blades',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0AsxBmXeOIo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'inverted_rows_bent_legs': ExerciseCoaching(
      howTo: [
        'Hang under a bar with the knees bent and the feet flat on the floor.',
        'Pull the chest to the bar, keeping the body in one line and the hips up.',
        'Lower to straight arms.',
      ],
      formChecks: [
        'Knees bent to lighten the load',
        'Chest touches the bar',
        'Hips stay up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=M3Tp_iDrKoc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'inverted_rows_straight_legs': ExerciseCoaching(
      howTo: [
        'Hang under the bar with straight legs and the heels on the floor at about forty five degrees.',
        'Pull the chest to the bar, holding one line from head to heels.',
        'Lower with control to full arm extension.',
      ],
      formChecks: [
        'Straight legs, heels down',
        'One line from head to heels',
        'Full arm extension at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9fItzuh9Iok',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'feet_elevated_rows': ExerciseCoaching(
      howTo: [
        'Put the feet on a box so the body sits close to horizontal under the bar.',
        'Pull the chest to the bar without letting the hips drop.',
        'Lower slowly to straight arms.',
      ],
      formChecks: [
        'Feet elevated to the bar height',
        'Hips stay lifted',
        'Chest to the bar each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=NeaONUgPfWk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'horizontal_rows': ExerciseCoaching(
      howTo: [
        'Set up with the body fully parallel to the floor under the bar or rings.',
        'Pull the chest to the bar and pause there.',
        'Lower to straight arms without sagging at the hips.',
      ],
      formChecks: [
        'Body parallel to the floor',
        'Pause at the top',
        'No sagging hips',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JqsuPc6-FDg',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'horizontal_wide_rows': ExerciseCoaching(
      howTo: [
        'Set up horizontal under the bar with the hands wider than shoulder width.',
        'Pull the chest to the bar and squeeze the shoulder blades together at the top.',
        'Lower with the body held flat.',
      ],
      formChecks: [
        'Wider grip loads the upper back',
        'Squeeze the shoulder blades',
        'Keep the body flat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8XLoq0GHktQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'archer_rows': ExerciseCoaching(
      howTo: [
        'Set up in a horizontal row position.',
        'Pull toward one hand while the other arm straightens out to the side.',
        'Lower and alternate sides each rep, keeping the hips square.',
      ],
      formChecks: [
        'Pull to one side at a time',
        'Far arm straightens',
        'Hips stay square',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WRMnf6ClD6k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'bulgarian_rows': ExerciseCoaching(
      howTo: [
        'Row horizontally with most of the load on one arm.',
        'Rest the other hand lightly on the bar or a strap for support.',
        'Keep the hips square and switch sides between sets.',
      ],
      formChecks: [
        'One arm does most of the work',
        'Support hand stays light',
        'Keep the hips square',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cox0_i8x7hc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'one_arm_rows': ExerciseCoaching(
      howTo: [
        'Set up horizontally under the bar and take one hand off.',
        'Row with a single arm while the body stays rigid and square.',
        'Resist the twist on the way down, and switch arms between sets.',
      ],
      formChecks: [
        'One hand only',
        'Resist the twist',
        'Body stays parallel to the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aoe2srzmUyA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'tuck_front_lever_rows_hold': ExerciseCoaching(
      howTo: [
        'Hang from a bar and pull the knees tight to the chest.',
        'Rotate back until the back faces the floor and the shins point forward.',
        'Hold with the arms locked and the back parallel to the floor.',
      ],
      formChecks: [
        'Back parallel to the floor',
        'Knees tight to the chest',
        'Arms stay locked',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=IFpELc7EdZY',
      imageUrl:
          'https://img.youtube.com/vi/IFpELc7EdZY/hqdefault.jpg',
    ),
    'tuck_front_lever_rows': ExerciseCoaching(
      howTo: [
        'Hold a tuck front lever with the back flat and the knees tucked.',
        'Pull the chest toward the bar without losing the shape.',
        'Lower to straight arms, still in the tuck.',
      ],
      formChecks: [
        'Hold the tuck through the pull',
        'Back stays parallel to the floor',
        'Straight arms at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VUe3M0iLPG0',
      imageUrl:
          'https://img.youtube.com/vi/VUe3M0iLPG0/hqdefault.jpg',
    ),
    'advanced_tuck_front_lever_rows': ExerciseCoaching(
      howTo: [
        'Hold an advanced tuck front lever with the knees opened away from the chest.',
        'Keep the hips high as you pull the chest to the bar.',
        'Lower to straight arms without letting the tuck close.',
      ],
      formChecks: [
        'Open the tuck',
        'Hips stay high',
        'Pull the chest to the bar',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mpX5l2V2MnY',
      imageUrl:
          'https://img.youtube.com/vi/mpX5l2V2MnY/hqdefault.jpg',
    ),
    'one_leg_tuck_one_extended_front_lever_rows': ExerciseCoaching(
      howTo: [
        'Hold a front lever with one leg extended and the other tucked.',
        'Pull the chest toward the bar, keeping the hips level.',
        'Lower to straight arms, and swap which leg extends between sets.',
      ],
      formChecks: [
        'One leg long, one tucked',
        'Hips stay level',
        'Even work on both sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=iK78Q6NwH-Q',
      imageUrl:
          'https://img.youtube.com/vi/iK78Q6NwH-Q/hqdefault.jpg',
    ),
    'straddle_front_lever_rows': ExerciseCoaching(
      howTo: [
        'Hold a straddle front lever with the legs wide and the body flat.',
        'Row the chest toward the bar.',
        'Lower to straight arms between reps.',
      ],
      formChecks: [
        'Legs wide to lighten the lever',
        'Body flat',
        'Straight arms between reps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vui6NkGu8pU',
      imageUrl:
          'https://img.youtube.com/vi/vui6NkGu8pU/hqdefault.jpg',
    ),
    'front_lever_rows': ExerciseCoaching(
      howTo: [
        'Hold a full front lever with straight legs together, body parallel to the floor.',
        'Pull the chest to the bar without piking at the hips.',
        'Lower to straight arms, holding the flat body line.',
      ],
      formChecks: [
        'Full lever, legs together',
        'Body parallel to the floor',
        'No hip pike',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5c5HwNSnj5U',
      imageUrl:
          'https://img.youtube.com/vi/5c5HwNSnj5U/hqdefault.jpg',
    ),
    'weighted_rows_bodyweight_3x10': ExerciseCoaching(
      howTo: [
        'Set the bar or rings low enough that your body is parallel to the floor.',
        'Pull the chest to the bar and lower to straight arms.',
        'Hit three sets of ten clean reps at this angle before you add any load.',
      ],
      formChecks: [
        'Three sets of ten',
        'Body stays horizontal',
        'Full range every rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=KOaCM1HMwU0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'weighted_rows_plus_10': ExerciseCoaching(
      howTo: [
        'Wear a vest or belt holding ten percent of your bodyweight.',
        'Row with the body fully horizontal.',
        'Keep the range full — do not raise the body angle to make it easier.',
      ],
      formChecks: [
        'Ten percent added',
        'Do not raise the body angle',
        'Full range each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EfElq5QuFfk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'weighted_rows_plus_20': ExerciseCoaching(
      howTo: [
        'Add twenty percent of bodyweight in a vest or on the hips.',
        'Hold the same horizontal body angle through every rep.',
        'Control the lowering rather than dropping.',
      ],
      formChecks: [
        'Twenty percent added',
        'Angle stays horizontal',
        'Control the lowering',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EfElq5QuFfk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'weighted_rows_plus_35': ExerciseCoaching(
      howTo: [
        'Load thirty five percent of bodyweight.',
        'Row the chest to the bar while staying parallel to the floor.',
        'Brace hard to stop the hips dropping.',
      ],
      formChecks: [
        'Thirty five percent added',
        'Chest to the bar',
        'Brace to stop the hips dropping',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EfElq5QuFfk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'weighted_rows_plus_50': ExerciseCoaching(
      howTo: [
        'Load half your bodyweight.',
        'Row from a true horizontal position with no angle cheat.',
        'Pause briefly at the top of each rep.',
      ],
      formChecks: [
        'Half bodyweight added',
        'No angle cheat',
        'Pause briefly at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EfElq5QuFfk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'weighted_rows_plus_75': ExerciseCoaching(
      howTo: [
        'Load seventy five percent of bodyweight.',
        'Keep the body fixed parallel to the floor — heavy but horizontal.',
        'Take long rests between sets and hold full range.',
      ],
      formChecks: [
        'Heavy but horizontal',
        'Full range',
        'Long rests between sets',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EfElq5QuFfk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'weighted_rows_plus_bodyweight': ExerciseCoaching(
      howTo: [
        'Add a full bodyweight of external load, so the total comes to double your own.',
        'Stay parallel to the floor throughout.',
        'Build to it over months — this closes out the rowing ladder.',
      ],
      formChecks: [
        'Double bodyweight total',
        'Body stays parallel to the floor',
        'Build to it over months',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ANo7wslfhrQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Inverted_Row/0.jpg',
    ),
    'wall_push_up': ExerciseCoaching(
      howTo: [
        'Stand an arm length from a wall with the hands on it at chest height.',
        'Bend the elbows to about forty five degrees and bring the chest to the wall.',
        'Press back to straight arms, keeping the body in one line.',
      ],
      formChecks: [
        'Body stays in one line',
        'Elbows at about forty five degrees',
        'Step the feet back to make it harder',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=EOf3cGIQpA4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Push-Up/0.jpg',
    ),
    'incline_push_up': ExerciseCoaching(
      howTo: [
        'Put the hands on a bench, box or bar with the body in a straight line.',
        'Lower the chest to the surface.',
        'Press back up, and lower the hand height as you get stronger.',
      ],
      formChecks: [
        'Lower hands means harder',
        'Straight line from head to heels',
        'Chest touches each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=yAbg3_pJKvw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Incline_Push-Up/0.jpg',
    ),
    'push_up': ExerciseCoaching(
      howTo: [
        'Set the hands slightly wider than the shoulders, body in a straight line.',
        'Lower until the chest is just off the floor, elbows at about forty five degrees.',
        'Press back to locked arms with the hips in line with the shoulders.',
      ],
      formChecks: [
        'Elbows at about forty five degrees',
        'Hips in line with the shoulders',
        'Full lockout at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=WDIpL0pjun0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'elbows_in_push_up': ExerciseCoaching(
      howTo: [
        'Set the hands under the lower chest rather than out wide.',
        'Lower with the elbows tucked close to the ribs the whole way.',
        'Press back up — expect more triceps work than a standard pushup.',
      ],
      formChecks: [
        'Elbows brush the ribs',
        'Hands under the lower chest',
        'Expect more triceps work',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=mm_yyN2Rtvo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'decline_push_up': ExerciseCoaching(
      howTo: [
        'Place the feet on a box or bench with the hands on the floor.',
        'Lower the chest to the floor without letting the hips sag.',
        'Press back up; a higher box means more load.',
      ],
      formChecks: [
        'Higher feet means more load',
        'No sagging hips',
        'Chest to the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=DBz85WuXqMk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Decline_Push-Up/0.jpg',
    ),
    'diamond_push_up': ExerciseCoaching(
      howTo: [
        'Place the hands together under the chest so thumbs and index fingers form a triangle.',
        'Lower with the elbows tucked.',
        'Press back up, and stop the set if the wrists complain.',
      ],
      formChecks: [
        'Hands together under the chest',
        'Elbows stay tucked',
        'Stop if the wrists complain',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Q6PHAI7rb4g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Push-Ups_-_Close_Triceps_Position/0.jpg',
    ),
    'uneven_push_up': ExerciseCoaching(
      howTo: [
        'Put one hand on a low block or ball and the other on the floor.',
        'Push up so the lower arm takes most of the load, hips square.',
        'Switch sides so both arms get even sets.',
      ],
      formChecks: [
        'Lower hand does most of the work',
        'Keep the hips square',
        'Even sets on both sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J1pEqEB10lA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'archer_push_up': ExerciseCoaching(
      howTo: [
        'Take a wide hand position.',
        'Lower toward one hand while the other arm straightens out to the side.',
        'Press back up and alternate sides each rep.',
      ],
      formChecks: [
        'Straighten the far arm',
        'Chest lands over the working hand',
        'Alternate each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=wJKLatFY-aU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'incline_one_arm_push_up': ExerciseCoaching(
      howTo: [
        'Place one hand on a bench or box, the other behind the back, feet wide.',
        'Lower the chest to the surface with the hips square.',
        'Press back up, then switch sides — lower the surface as you progress.',
      ],
      formChecks: [
        'Feet wide for balance',
        'Lower the surface as you progress',
        'Hips stay square',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=efchxULAT6M',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Arm_Push-Up/0.jpg',
    ),
    'one_arm_push_up': ExerciseCoaching(
      howTo: [
        'Set the feet wide with one hand under the chest and the other behind the back.',
        'Lower the chest to the floor, keeping the hips square.',
        'Press back up without twisting.',
      ],
      formChecks: [
        'Feet wide for balance',
        'Hips stay square to the floor',
        'Chest touches the floor',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JiHkxqbhNuw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Single-Arm_Push-Up/0.jpg',
    ),
    'ring_wide_push_up': ExerciseCoaching(
      howTo: [
        'Set the rings a few inches off the floor and take a wide hand position.',
        'Lower the chest between the rings, body in one line.',
        'Press back up while stopping the rings from drifting.',
      ],
      formChecks: [
        'Wide hands, deeper stretch',
        'Rings stay steady',
        'Body in one line',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=sOqMm0Y1bQw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'ring_push_up': ExerciseCoaching(
      howTo: [
        'Set the rings just off the floor, held at shoulder width under the shoulders.',
        'Lower the chest to ring height.',
        'Press back up, squeezing the rings hard to stop the wobble.',
      ],
      formChecks: [
        'Rings stay under the shoulders',
        'Full range each rep',
        'Squeeze the rings hard',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=FRiiZRhapeU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'rto_push_up': ExerciseCoaching(
      howTo: [
        'Set the rings just off the floor and turn them out so the palms face forward.',
        'Lower to the chest with the elbows close.',
        'Press back up and restore the turnout at the top of each rep.',
      ],
      formChecks: [
        'Turn the rings out at lockout',
        'Elbows stay close',
        'Control the wobble',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=J1N2v6yJ_54',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'rto_archer_push_up': ExerciseCoaching(
      howTo: [
        'Set up on rings turned out at the top.',
        'Lower toward one ring while the other arm straightens.',
        'Press back, turn the rings out again, and alternate sides.',
      ],
      formChecks: [
        'Turnout at the top of each rep',
        'Far arm straightens',
        'Alternate sides',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=_CakWOnh3-Y',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'rto_pseudo_planche_push_up_lower_chest': ExerciseCoaching(
      howTo: [
        'On rings turned out, set the hands beside the lower chest.',
        'Lean the shoulders forward past the hands and hold that lean.',
        'Press through full range without losing the lean or the turnout.',
      ],
      formChecks: [
        'Rings turned out',
        'Hands beside the lower chest',
        'Hold the lean the whole rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oso20DQ0JjQ',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'rto_pseudo_planche_push_up_belly_button': ExerciseCoaching(
      howTo: [
        'On turned-out rings, move the hands back beside the navel.',
        'Lean further forward — warm the wrists and elbows first.',
        'Press through full range while stopping the rings from drifting.',
      ],
      formChecks: [
        'Hands beside the navel',
        'Bigger lean on rings',
        'Wrists and elbows warm first',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oFVd9_Mpr5k',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'rto_pseudo_planche_push_up_hips': ExerciseCoaching(
      howTo: [
        'Set the hands beside the hips on turned-out rings.',
        'Let the shoulders travel far in front — the deepest lean in this branch.',
        'Press back up under control, keeping the rings turned out at the top.',
      ],
      formChecks: [
        'Hands beside the hips',
        'Rings turned out at the top',
        'Build to it slowly',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aoiWsmqXA_U',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Suspended_Push-Up/0.jpg',
    ),
    'pseudo_planche_push_up_lower_chest': ExerciseCoaching(
      howTo: [
        'Set the hands beside the lower chest with the fingers turned slightly out.',
        'Lean the shoulders forward past the hands.',
        'Push up holding that lean for the whole rep.',
      ],
      formChecks: [
        'Hands beside the lower chest',
        'Shoulders stay in front of the hands',
        'Keep the lean the whole rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jZsSSPEgJQk',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'pseudo_planche_push_up_belly_button': ExerciseCoaching(
      howTo: [
        'Move the hands back so they sit beside the navel.',
        'Lean the shoulders well past them, wrists warmed up first.',
        'Push up holding that forward lean with straight wrists.',
      ],
      formChecks: [
        'Hands beside the navel',
        'Big forward lean',
        'Wrists warmed up first',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Cdmg0CfMZeo',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'pseudo_planche_push_up_hips': ExerciseCoaching(
      howTo: [
        'Set the hands beside the hips.',
        'Lean the shoulders far past them — the deepest lean of the three.',
        'Push up with the arms working close to the body and the body in one line.',
      ],
      formChecks: [
        'Hands beside the hips',
        'Deepest lean of the three',
        'Keep the body in one line',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=m2KH4Bcg6g0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Pushups/0.jpg',
    ),
    'tuck_planche_push_up': ExerciseCoaching(
      howTo: [
        'Hold a tuck planche with the knees at the chest and the hips high.',
        'Bend the arms to lower the chest.',
        'Press back up without letting the feet touch down — keep the sets short.',
      ],
      formChecks: [
        'Feet never touch the floor',
        'Hips stay high',
        'Short sets',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=d979_qlKCyM',
      imageUrl:
          'https://img.youtube.com/vi/d979_qlKCyM/hqdefault.jpg',
    ),
    'advanced_tuck_planche_push_up': ExerciseCoaching(
      howTo: [
        'Hold an advanced tuck planche with a flat back and the knees away from the chest.',
        'Lower under control, hips level with the shoulders.',
        'Press back up, and end the set when the tuck starts to close.',
      ],
      formChecks: [
        'Flat back throughout',
        'Hips level with the shoulders',
        'Stop the set when the tuck closes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hxmqiYCamIg',
      imageUrl:
          'https://img.youtube.com/vi/hxmqiYCamIg/hqdefault.jpg',
    ),
    'straddle_planche_push_up': ExerciseCoaching(
      howTo: [
        'Hold a straddle planche with the legs wide and the body horizontal.',
        'Bend the arms to lower, keeping the hips from dropping.',
        'Press back to straight arms and a full lockout.',
      ],
      formChecks: [
        'Legs wide to shorten the lever',
        'Body stays parallel to the floor',
        'Full lockout at the top',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=vVJcZv6zHV8',
      imageUrl:
          'https://img.youtube.com/vi/vVJcZv6zHV8/hqdefault.jpg',
    ),
    'planche_push_up': ExerciseCoaching(
      howTo: [
        'Hold a full planche with the legs together and the body horizontal.',
        'Lower the chest toward the floor.',
        'Press back to straight arms with the feet never touching down.',
      ],
      formChecks: [
        'Legs together and straight',
        'Body parallel to the floor',
        'Feet never touch',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=tdvYjyuRSE4',
      imageUrl:
          'https://img.youtube.com/vi/tdvYjyuRSE4/hqdefault.jpg',
    ),
    'planche_lean_just_past': ExerciseCoaching(
      howTo: [
        'Start in a pushup position with the hands turned slightly out and the elbows locked.',
        'Lean forward until the shoulders sit just past the wrists.',
        'Hold there with the body in one line and the shoulder blades protracted.',
      ],
      formChecks: [
        'Arms stay locked',
        'Shoulders just past the wrists',
        'Protract the shoulder blades',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=iZ03RYvjjmE',
      imageUrl:
          'https://img.youtube.com/vi/iZ03RYvjjmE/hqdefault.jpg',
    ),
    'planche_lean_moderate': ExerciseCoaching(
      howTo: [
        'Take the same locked-arm position and lean until the shoulders are well past the wrists.',
        'Push the floor away hard, hips in line with the shoulders.',
        'Hold for short sets and build wrist tolerance gradually.',
      ],
      formChecks: [
        'Push the floor away hard',
        'Keep the hips in line with the shoulders',
        'Short sets, many of them',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3CltFxibIu0',
      imageUrl:
          'https://img.youtube.com/vi/3CltFxibIu0/hqdefault.jpg',
    ),
    'planche_lean_far_past': ExerciseCoaching(
      howTo: [
        'Lean until the shoulders are far past the wrists and the toes barely hold weight.',
        'Keep the arms straight with no bend, body in a single line from head to heels.',
        'End the hold as soon as the hips drop.',
      ],
      formChecks: [
        'Toes barely loaded',
        'Straight arms, no bend',
        'Stop the hold when the hips drop',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=oVpte1edulI',
      imageUrl:
          'https://img.youtube.com/vi/iZ03RYvjjmE/hqdefault.jpg',
    ),
    'tuck_planche_lean': ExerciseCoaching(
      howTo: [
        'Hold a deep planche lean with the arms locked.',
        'Lift one knee at a time toward the chest until both feet leave the floor.',
        'Hold with the shoulders forward and the arms straight.',
      ],
      formChecks: [
        'Lean first, then tuck',
        'Both feet leave the floor',
        'Arms stay straight',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=0l4TirVnK7M',
      imageUrl:
          'https://img.youtube.com/vi/0l4TirVnK7M/hqdefault.jpg',
    ),
    'tuck_planche_hold': ExerciseCoaching(
      howTo: [
        'Support on the floor or parallettes with straight arms and lean forward.',
        'Pull both knees to the chest and lift the hips to shoulder height.',
        'Hold with the upper back rounded, pushing the floor away.',
      ],
      formChecks: [
        'Hips up to shoulder height',
        'Knees tight to the chest',
        'Round the upper back and push down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=jAV7r2d8zQM',
      imageUrl:
          'https://img.youtube.com/vi/jAV7r2d8zQM/hqdefault.jpg',
    ),
    'advanced_tuck_planche_hold': ExerciseCoaching(
      howTo: [
        'From the tuck planche, open the knees so the thighs move away from the chest.',
        'Flatten the back and bring the hips level with the shoulders.',
        'Hold with the arms locked, still pushing the floor away.',
      ],
      formChecks: [
        'Open the tuck, flatten the back',
        'Hips level with the shoulders',
        'Keep pushing the floor away',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=LDa0pWuGQ5E',
      imageUrl:
          'https://img.youtube.com/vi/LDa0pWuGQ5E/hqdefault.jpg',
    ),
    'straddle_planche_wide': ExerciseCoaching(
      howTo: [
        'Hold the planche with straight legs opened as wide as they go.',
        'Keep the hips level with the shoulders — the wide legs shorten the lever.',
        'Hold with the arms locked and the toes pointed.',
      ],
      formChecks: [
        'Legs as wide as they go',
        'Hips level with the shoulders',
        'Point the toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=MV-Kgy8_50c',
      imageUrl:
          'https://img.youtube.com/vi/MV-Kgy8_50c/hqdefault.jpg',
    ),
    'straddle_planche_medium': ExerciseCoaching(
      howTo: [
        'Narrow the straddle so the legs sit at roughly forty five degrees.',
        'Hold the body flat and horizontal with the arms straight.',
        'Do not let the hips pike as the load increases.',
      ],
      formChecks: [
        'Narrower legs, more load',
        'Keep the body flat',
        'No piking at the hips',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Xo_OP5FYsp8',
      imageUrl:
          'https://img.youtube.com/vi/Xo_OP5FYsp8/hqdefault.jpg',
    ),
    'straddle_planche_narrow': ExerciseCoaching(
      howTo: [
        'Bring the legs close together while still keeping a small gap.',
        'Hold the horizontal position with locked arms.',
        'Keep the hips in line with the shoulders — this is almost full planche leverage.',
      ],
      formChecks: [
        'Almost full planche leverage',
        'Hold the line from head to toes',
        'Straight arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OP_hnYuFIjc',
      imageUrl:
          'https://img.youtube.com/vi/MV-Kgy8_50c/hqdefault.jpg',
    ),
    'full_planche_hold': ExerciseCoaching(
      howTo: [
        'Hold the body horizontal with the legs together and straight.',
        'Lock the arms and keep the whole body in one line parallel to the floor.',
        'Push down hard through the entire hold.',
      ],
      formChecks: [
        'Legs together and straight',
        'Body parallel to the floor',
        'Push down hard through the whole hold',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8FFZKmBM4k4',
      imageUrl:
          'https://img.youtube.com/vi/8FFZKmBM4k4/hqdefault.jpg',
    ),
    'assisted_squat': ExerciseCoaching(
      howTo: [
        'Hold a doorframe, pole or suspension strap for support.',
        'Sit back and down into a squat, heels flat.',
        'Use the hands for balance and only as much pull as you need to reach depth.',
      ],
      formChecks: [
        'Use the hands for balance',
        'Sit back and down',
        'Heels stay flat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=CcnyxSe_H9g',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Squat/0.jpg',
    ),
    'deep_assisted_squat': ExerciseCoaching(
      howTo: [
        'Using the same light support, lower all the way until the hamstrings meet the calves.',
        'Hold the bottom briefly with the heels down.',
        'Stand back up through the whole foot.',
      ],
      formChecks: [
        'Go to full depth',
        'Pause at the bottom',
        'Keep the heels down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=9ftu-x-sa1s',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Squat/0.jpg',
    ),
    'squat': ExerciseCoaching(
      howTo: [
        'Stand with the feet about shoulder width and the toes turned slightly out.',
        'Sit back and down until the thighs pass parallel, knees tracking over the toes.',
        'Drive through the whole foot to stand, chest up throughout.',
      ],
      formChecks: [
        'Knees track over the toes',
        'Thighs past parallel',
        'Chest stays up',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=l83R5PblSMA',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Squat/0.jpg',
    ),
    'deep_squat': ExerciseCoaching(
      howTo: [
        'Squat all the way to the bottom so the hamstrings rest on the calves.',
        'Hold there comfortably with a long spine and the heels down.',
        'Stand back up without letting the heels lift.',
      ],
      formChecks: [
        'Full depth, heels down',
        'Hold the bottom position',
        'Keep the spine long',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=QAMLqAjN9T0',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Bodyweight_Squat/0.jpg',
    ),
    'bulgarian_split_squat': ExerciseCoaching(
      howTo: [
        'Stand a stride in front of a bench and rest the top of the rear foot on it.',
        'Lower until the front thigh is parallel to the floor, front shin near vertical.',
        'Drive back up through the front heel.',
      ],
      formChecks: [
        'Front shin near vertical',
        'Rear foot on the bench',
        'Drive through the front heel',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aSJbKnDRIiQ',
      imageUrl:
          'https://img.youtube.com/vi/aSJbKnDRIiQ/hqdefault.jpg',
    ),
    'single_leg_rdl': ExerciseCoaching(
      howTo: [
        'Stand on one leg with a soft knee.',
        'Hinge at the hips, letting the free leg travel back as the chest lowers.',
        'Return by driving the hips forward, keeping the back flat and the hips level.',
      ],
      formChecks: [
        'Hinge at the hips, not the waist',
        'Back stays flat',
        'Hips stay level',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JQZqPsmeesc',
      imageUrl:
          'https://img.youtube.com/vi/JQZqPsmeesc/hqdefault.jpg',
    ),
    'barbell_squat': ExerciseCoaching(
      howTo: [
        'Set the bar just below shoulder height, step under it and rest it across the upper back.',
        'Unrack by driving through the legs, then step back to a shoulder-width stance, toes slightly out.',
        'Brace, then sit the hips back and bend the knees until the hamstrings meet the calves.',
        'Drive up through the mid-foot to standing, knees tracking over the toes.',
      ],
      formChecks: [
        'Head up, back flat throughout',
        'Brace before you descend',
        'Inhale down, exhale up',
        'Push the floor away through heel and mid-foot',
        'Knees track over the toes',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=rrJIyZGlK8c',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Barbell_Squat/0.jpg',
    ),
    'romanian_deadlift': ExerciseCoaching(
      howTo: [
        'Hold the bar at hip height with an overhand grip just wider than the shoulders.',
        'Soften the knees and keep the shins vertical — this is a hinge, not a squat.',
        'Push the hips back to lower the bar down the front of the legs until you feel a hamstring stretch.',
        'Drive the hips forward to stand tall, back flat and bar close throughout.',
      ],
      formChecks: [
        'Back and arms stay straight',
        'Move steady, not fast',
        'Chest up, bar close to the legs',
        'Slight knee bend only, this is a hinge not a squat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7j-2w4-P14I',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Romanian_Deadlift/0.jpg',
    ),
    'box_pistol_squat_knee_height': ExerciseCoaching(
      howTo: [
        'Stand on one leg in front of a knee-height box, the other leg held forward.',
        'Sit back to the box under control without resting on it.',
        'Stand back up on the same leg, free leg off the floor throughout.',
      ],
      formChecks: [
        'Touch the box, do not sit down',
        'Free leg stays off the floor',
        'Control the descent',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ECrpZpgi9f4',
      imageUrl:
          'https://img.youtube.com/vi/ECrpZpgi9f4/hqdefault.jpg',
    ),
    'nordic_curl': ExerciseCoaching(
      howTo: [
        'Anchor the heels under a bar or have a partner hold them.',
        'Keep the hips open and lower the body toward the floor as slowly as you can.',
        'Catch yourself with the hands and push back to the start.',
      ],
      formChecks: [
        'Hips stay open, not folded',
        'Lower as slowly as possible',
        'Catch with the hands',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=yilP4ns5gNc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Natural_Glute_Ham_Raise/0.jpg',
    ),
    'box_pistol_squat_mid_calf_height': ExerciseCoaching(
      howTo: [
        'Repeat the box pistol with a lower box at mid-calf height for a longer range.',
        'Keep the free leg straight out in front throughout.',
        'Stand back up without rocking.',
      ],
      formChecks: [
        'Lower box means more range',
        'Free leg stays straight',
        'Stand without rocking',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=URcoThD163Q',
      imageUrl:
          'https://img.youtube.com/vi/URcoThD163Q/hqdefault.jpg',
    ),
    'beginner_shrimp_squat': ExerciseCoaching(
      howTo: [
        'Hold one foot behind you with the same-side hand, torso upright.',
        'Lower on the other leg until the back knee touches a pad.',
        'Use a light support with the free hand to stand back up.',
      ],
      formChecks: [
        'Back knee touches a pad',
        'Free hand for balance',
        'Torso stays upright',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1x5iajDgE9I',
      imageUrl:
          'https://img.youtube.com/vi/1x5iajDgE9I/hqdefault.jpg',
    ),
    'assisted_pistol_squat': ExerciseCoaching(
      howTo: [
        'Hold a doorframe or strap for light assistance.',
        'Lower on one leg with the other held out in front, heel down.',
        'Use the hands only as much as needed to reach the bottom.',
      ],
      formChecks: [
        'Free leg stays off the floor',
        'Least assistance that works',
        'Heel stays down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YzLuiF4dsdY',
      imageUrl:
          'https://img.youtube.com/vi/YzLuiF4dsdY/hqdefault.jpg',
    ),
    'intermediate_shrimp_squat': ExerciseCoaching(
      howTo: [
        'Hold the rear foot with the same-side hand and take no hand support.',
        'Lower until the back knee taps the floor, chest tall.',
        'Stand back up on the working leg.',
      ],
      formChecks: [
        'No hand support',
        'Back knee taps the floor',
        'Keep the chest tall',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=hYIKLH6kznc',
      imageUrl:
          'https://img.youtube.com/vi/hYIKLH6kznc/hqdefault.jpg',
    ),
    'counter_weighted_pistol_squat': ExerciseCoaching(
      howTo: [
        'Hold a light plate or dumbbell out in front of the chest to balance the load.',
        'Lower on one leg to the bottom, free leg straight in front.',
        'Stand back up, and drop the counterweight as your balance improves.',
      ],
      formChecks: [
        'Counterweight helps balance',
        'Free leg straight in front',
        'Drop the weight as balance improves',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=5pl6zRmDYlc',
      imageUrl:
          'https://img.youtube.com/vi/6cjnGV7MEtM/hqdefault.jpg',
    ),
    'advanced_shrimp_squat': ExerciseCoaching(
      howTo: [
        'Hold the rear foot behind you with no assistance.',
        'Lower until the back knee touches, keeping the torso upright.',
        'Stand back up smoothly with no wobble at the bottom.',
      ],
      formChecks: [
        'Upright torso',
        'Smooth touch and stand',
        'No wobble at the bottom',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=1YNZ9l9WZnk',
      imageUrl:
          'https://img.youtube.com/vi/1YNZ9l9WZnk/hqdefault.jpg',
    ),
    'pistol_squat': ExerciseCoaching(
      howTo: [
        'Stand on one leg with the other held straight out in front.',
        'Lower all the way to the bottom with the heel flat.',
        'Stand back up with no support and no bouncing.',
      ],
      formChecks: [
        'Full depth on one leg',
        'Free leg never touches',
        'Heel stays flat',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=JUWeSv0RkLs',
      imageUrl:
          'https://img.youtube.com/vi/JUWeSv0RkLs/hqdefault.jpg',
    ),
    'lying_knee_raises': ExerciseCoaching(
      howTo: [
        'Lie on your back with the hands beside the hips and the lower back pressed into the floor.',
        'Draw the knees toward the chest.',
        'Lower them slowly, stopping before the back lifts.',
      ],
      formChecks: [
        'Low back stays flat',
        'Slow on the way down',
        'Stop before the back lifts',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=aK8Rm_tv3WM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Lying_Leg_Raise/0.jpg',
    ),
    'foot_supported_l_sit': ExerciseCoaching(
      howTo: [
        'Sit with straight legs and press the hands into the floor or parallettes beside the hips.',
        'Push the shoulders down and lift the body until the heels carry almost no weight.',
        'Hold with the arms straight and the heels light.',
      ],
      formChecks: [
        'Push the floor away',
        'Heels light, not loaded',
        'Straight arms throughout',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=cMNVkXW-2aI',
      imageUrl:
          'https://img.youtube.com/vi/cMNVkXW-2aI/hqdefault.jpg',
    ),
    'plank': ExerciseCoaching(
      howTo: [
        'Rest on the forearms and toes with the elbows directly under the shoulders.',
        'Squeeze the glutes and brace the abs so the hips neither sag nor pike.',
        'Hold the straight line from head to heels for 25 seconds, breathing steadily.',
      ],
      formChecks: [
        'Elbows under shoulders',
        'No sag and no pike',
        'Squeeze the glutes',
        'Breathe steadily',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pSHjTRCQxIw',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plank/0.jpg',
    ),
    'bent_leg_lying_leg_raises': ExerciseCoaching(
      howTo: [
        'Lie on your back and extend the shins so the legs are only slightly bent.',
        'Raise them until the hips are fully flexed.',
        'Lower under control with the lower back pinned down, shortening the range if it lifts.',
      ],
      formChecks: [
        'Longer lever, same flat back',
        'Control the lowering',
        'Shorten the range if the back lifts',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=3J9JKKDHhT4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Lying_Leg_Raise/0.jpg',
    ),
    'l_sit_tuck': ExerciseCoaching(
      howTo: [
        'Support yourself on parallettes or bars with straight arms.',
        'Pull both knees tightly to the chest and lift the hips clear of the floor.',
        'Hold with the shoulders pressed down — lift, do not hang.',
      ],
      formChecks: [
        'Knees tight to the chest',
        'Shoulders pressed down',
        'Lift the hips, do not hang',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=VhqEdeeAyvg',
      imageUrl:
          'https://img.youtube.com/vi/VhqEdeeAyvg/hqdefault.jpg',
    ),
    'plank_60s': ExerciseCoaching(
      howTo: [
        'Set the same forearm plank, elbows under the shoulders.',
        'Pull the ribs down and tuck the pelvis so the lower back stays flat.',
        'Hold the line for a full minute, ending the set if the hips drop.',
      ],
      formChecks: [
        'Ribs down and pelvis tucked',
        'Hold the line as fatigue builds',
        'End the set if the hips drop',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=pvIjsG5Svck',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plank/0.jpg',
    ),
    'straight_leg_lying_leg_raises': ExerciseCoaching(
      howTo: [
        'Lie flat with straight legs held together.',
        'Lift them until they point at the ceiling.',
        'Lower slowly until the heels hover just above the floor, back still flat.',
      ],
      formChecks: [
        'Straight knees',
        'Heels stop just off the floor',
        'Keep the back flat all set',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=Zr-PtqcpeWM',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Flat_Bench_Lying_Leg_Raise/0.jpg',
    ),
    'advanced_tuck_l_sit': ExerciseCoaching(
      howTo: [
        'From the tuck position, open the knees to roughly a right angle.',
        'Move the thighs away from the chest and flatten the back.',
        'Hold with the hips level with the shoulders.',
      ],
      formChecks: [
        'Open the tuck to ninety degrees',
        'Keep the back flat',
        'Hips level with the shoulders',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=dAUpPkDgYRg',
      imageUrl:
          'https://img.youtube.com/vi/dAUpPkDgYRg/hqdefault.jpg',
    ),
    'one_arm_one_leg_plank': ExerciseCoaching(
      howTo: [
        'Set a forearm plank with the hips square to the floor.',
        'Lift one arm and the opposite leg a few inches off the floor.',
        'Hold without letting the hips rotate, then set them down and switch sides.',
      ],
      formChecks: [
        'Lift opposite arm and leg',
        'Keep the hips square to the floor',
        'Short strict holds',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=8T_LhlSK8Po',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Plank/0.jpg',
    ),
    'hanging_knee_raises': ExerciseCoaching(
      howTo: [
        'Hang from a bar with straight arms and pull the shoulders down away from the ears.',
        'Lift the knees toward the chest without swinging.',
        'Lower slower than you lifted.',
      ],
      formChecks: [
        'Pull the shoulders down first',
        'No swing',
        'Lower slower than you lift',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=RD_A-Z15ER4',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Leg_Raise/0.jpg',
    ),
    'l_sit': ExerciseCoaching(
      howTo: [
        'Support on parallettes or bars with straight arms and the shoulders pushed down.',
        'Lift straight legs until they are parallel to the floor.',
        'Hold with the toes pointed and the knees locked.',
      ],
      formChecks: [
        'Legs straight and parallel to the floor',
        'Toes pointed',
        'Shoulders pushed down',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=6E5GGqlgX9U',
      imageUrl:
          'https://img.youtube.com/vi/6E5GGqlgX9U/hqdefault.jpg',
    ),
    'ab_wheel_kneeling': ExerciseCoaching(
      howTo: [
        'Kneel with the wheel under your shoulders and grip the handles.',
        'Tuck the pelvis, then roll out as far as you can keep a flat back.',
        'Pull yourself back with the abs rather than the arms.',
      ],
      formChecks: [
        'Tuck the pelvis before rolling',
        'Flat back, no arching',
        'Pull back with the abs not the arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=ep26hq1kHwY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ab_Roller/0.jpg',
    ),
    'bent_leg_hanging_leg_raises': ExerciseCoaching(
      howTo: [
        'Hang from the bar and straighten the legs a little.',
        'Lift the thighs above hip height and tuck the pelvis at the top.',
        'Lower with control and settle any swing before the next rep.',
      ],
      formChecks: [
        'Thighs above hip height',
        'Tuck the pelvis at the top',
        'Stay quiet on the bar',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=v3awfKOFa4M',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Leg_Raise/0.jpg',
    ),
    'straddle_l_sit': ExerciseCoaching(
      howTo: [
        'Hold an L-sit with the shoulders pressed down.',
        'Open the legs into a wide straddle with the knees straight.',
        'Keep both legs at hip height or higher for the whole hold.',
      ],
      formChecks: [
        'Open the legs wide',
        'Keep them level or higher',
        'Straight knees',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=YgEWVZ3DsM8',
      imageUrl:
          'https://img.youtube.com/vi/YgEWVZ3DsM8/hqdefault.jpg',
    ),
    'ab_wheel_eccentric': ExerciseCoaching(
      howTo: [
        'Roll out from the knees through a longer range than you can return from.',
        'Take three to five seconds on the way out.',
        'Lower to the floor at the end and reset for the next rep.',
      ],
      formChecks: [
        'Three to five seconds out',
        'Go past your normal range',
        'Reset from the floor each rep',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=4f3zHK6iwz8',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ab_Roller/0.jpg',
    ),
    'straight_leg_hanging_leg_raises': ExerciseCoaching(
      howTo: [
        'Hang with straight legs held together.',
        'Lift them until they are at least parallel to the floor.',
        'Lower slowly and let the swing settle before the next rep.',
      ],
      formChecks: [
        'Straight legs to horizontal or higher',
        'Lower with control',
        'Reset the swing between reps',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=7FwGZ8qY5OU',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Hanging_Leg_Raise/0.jpg',
    ),
    'v_sit': ExerciseCoaching(
      howTo: [
        'From an L-sit, compress the hips and lift the straight legs above horizontal.',
        'Lean the shoulders slightly back to balance the weight of the legs.',
        'Hold the V with the arms locked.',
      ],
      formChecks: [
        'Legs above horizontal',
        'Lean the shoulders back to balance',
        'Arms stay locked',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=I_mppMeo6vA',
      imageUrl:
          'https://img.youtube.com/vi/3tQuBuZLma4/hqdefault.jpg',
    ),
    'ab_wheel_standing': ExerciseCoaching(
      howTo: [
        'Start standing with the wheel on the floor in front of your feet.',
        'Roll out to full extension without letting the knees touch, back flat.',
        'Pull yourself all the way back to standing — use a wall as a stop while learning.',
      ],
      formChecks: [
        'Knees never touch the floor',
        'Flat back the whole way',
        'Use a wall as a stop while learning',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=L_2k97JeyzY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Ab_Roller/0.jpg',
    ),
    'false_grip_pull_ups': ExerciseCoaching(
      howTo: [
        'Hook the wrists over the rings or bar so the heel of the hand sits on top of the grip.',
        'Pull until the rings reach the lower chest.',
        'Hold that wrist position throughout — expect sore wrists at first.',
      ],
      formChecks: [
        'Heel of the hand on top of the ring',
        'Pull to the lower chest',
        'Expect sore wrists at first',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=59Kpdw7cqgY',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Muscle_Up/0.jpg',
    ),
    'muscle_up_negatives': ExerciseCoaching(
      howTo: [
        'Start at the top in a straight-arm support.',
        'Lower slowly through the transition, taking it as slowly as you can control.',
        'Finish in a full hang with the rings or bar kept close.',
      ],
      formChecks: [
        'Slowest through the transition',
        'Keep the rings or bar close',
        'Finish in a full hang',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OIKdQmjHsak',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Muscle_Up/0.jpg',
    ),
    'kipping_muscle_up': ExerciseCoaching(
      howTo: [
        'From a hang, swing the legs forward and drive the hips up.',
        'Time the hip drive with a hard pull toward the waist.',
        'Roll the shoulders over the top early and press out to a straight-arm support.',
      ],
      formChecks: [
        'Time the hip drive with the pull',
        'Roll the shoulders forward early',
        'Finish with straight arms',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=OCg3UXgzftc',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Kipping_Muscle_Up/0.jpg',
    ),
    'muscle_up': ExerciseCoaching(
      howTo: [
        'Pull explosively until the bar or rings reach the lower chest, not the chin.',
        'Lean the shoulders forward over the top at the transition.',
        'Press out to a locked support with no leg swing.',
      ],
      formChecks: [
        'Pull to the lower chest, not the chin',
        'Lean over the bar at the transition',
        'No kip',
      ],
      videoUrl:
          'https://www.youtube.com/watch?v=gryO72_xB8w',
      imageUrl:
          'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises/Muscle_Up/0.jpg',
    ),
  };

  /// Coaching for an exercise, or null for one the sheet does not cover yet.
  /// Callers fall back to the movement pattern's generic advice.
  static ExerciseCoaching? findById(String id) => _byId[id];

  /// Every exercise the sheet has coaching for.
  static Iterable<String> get coveredIds => _byId.keys;
}
