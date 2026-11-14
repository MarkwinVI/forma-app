/// Quick sessions: short extras offered under the day's program workout —
/// a wake-up, a stretch, a little core — for the days and moments between
/// program sessions. They sit beside the program and never replace it.
///
/// This is the catalogue and its copy only. Running a session (timers,
/// logging) is not built yet: the Train tab lists them and each has an
/// intro page, and that is where the flow ends for now.
library;

/// One step of a quick session: what to do, and for how long.
class QuickSessionMove {
  final String name;

  /// "45 S", "60 S / SIDE" — printed in the mono voice beside the name.
  final String amount;

  const QuickSessionMove(this.name, this.amount);
}

/// What a session is for, which is how the Sessions list is grouped.
enum QuickSessionGroup {
  shortOnTime('SHORT ON TIME'),
  recover('RECOVER');

  const QuickSessionGroup(this.label);

  final String label;
}

/// The filter chips above the Sessions list.
enum QuickSessionFilter {
  all('All'),
  underTenMinutes('Under 10 min'),
  stretch('Stretch'),
  mobility('Mobility'),
  core('Core');

  const QuickSessionFilter(this.label);

  final String label;
}

class QuickSession {
  final String id;
  final String name;
  final int minutes;

  /// The line under the name in the list: "Full body · no equipment".
  final String summary;
  final QuickSessionGroup group;

  /// The kinds this session answers to among the filter chips; "Under 10
  /// min" is read from [minutes] instead.
  final Set<QuickSessionFilter> kinds;

  /// The photo behind the tile and the intro, and where to hold it when it
  /// is cropped (-1 top … 1 bottom).
  final String image;
  final double imageFocusY;

  /// Two or three sentences on the intro page.
  final String description;

  /// How the moves run on: "NO REST", "20 S REST".
  final String pacing;

  /// "None", "Band, optional".
  final String equipment;
  final List<QuickSessionMove> moves;

  const QuickSession({
    required this.id,
    required this.name,
    required this.minutes,
    required this.summary,
    required this.group,
    required this.image,
    required this.description,
    required this.pacing,
    required this.equipment,
    required this.moves,
    this.kinds = const {},
    this.imageFocusY = 0,
  });

  /// "10 MIN" — the pill on a tile and a row.
  String get durationLabel => '$minutes MIN';

  bool matches(QuickSessionFilter filter) => switch (filter) {
        QuickSessionFilter.all => true,
        QuickSessionFilter.underTenMinutes => minutes < 10,
        _ => kinds.contains(filter),
      };
}

class QuickSessions {
  QuickSessions._();

  static const _bar = 'assets/quick_sessions/bar.jpg';
  static const _push = 'assets/quick_sessions/push.jpg';
  static const _blue = 'assets/quick_sessions/blue.jpg';
  static const _rail = 'assets/quick_sessions/rail.jpg';

  // The names, durations and list lines are the design's. Everything past
  // "Morning energy" — the descriptions and the moves — is stand-in copy
  // until the sessions themselves are written.
  static const morningEnergy = QuickSession(
    id: 'morning_energy',
    name: 'Morning energy',
    minutes: 10,
    summary: 'Full body · no equipment',
    group: QuickSessionGroup.shortOnTime,
    image: _bar,
    description: 'A short full-body wake-up. Light pushing, squatting and '
        'core work to get blood moving — easy enough to do before coffee.',
    pacing: 'NO REST',
    equipment: 'None',
    moves: [
      QuickSessionMove('Jumping Jacks', '45 S'),
      QuickSessionMove('Push-Up (Incline)', '45 S'),
      QuickSessionMove('Squat (Bodyweight)', '45 S'),
      QuickSessionMove('Mountain Climbers', '45 S'),
      QuickSessionMove('Plank', '45 S'),
    ],
  );

  static const pushUpPrimer = QuickSession(
    id: 'push_up_primer',
    name: 'Push-up primer',
    minutes: 8,
    summary: 'Chest, triceps · no equipment',
    group: QuickSessionGroup.shortOnTime,
    image: _push,
    description: 'Easy push-up variations to groove the pattern and warm '
        'the shoulders, well short of a hard set.',
    pacing: '20 S REST',
    equipment: 'None',
    moves: [
      QuickSessionMove('Push-Up (Incline)', '40 S'),
      QuickSessionMove('Push-Up (Knee)', '40 S'),
      QuickSessionMove('Plank Shoulder Taps', '40 S'),
      QuickSessionMove('Push-Up (Slow Lowering)', '40 S'),
    ],
  );

  static const core = QuickSession(
    id: 'core',
    name: 'Core',
    minutes: 10,
    summary: 'Hollow holds, planks',
    group: QuickSessionGroup.shortOnTime,
    kinds: {QuickSessionFilter.core},
    image: _rail,
    description: 'Holds and slow reps for the trunk: the hollow position, '
        'planks from the front and the side, and control between them.',
    pacing: '15 S REST',
    equipment: 'None',
    moves: [
      QuickSessionMove('Hollow Hold', '30 S'),
      QuickSessionMove('Plank', '45 S'),
      QuickSessionMove('Dead Bug', '45 S'),
      QuickSessionMove('Side Plank', '30 S / SIDE'),
      QuickSessionMove('Hollow Rocks', '30 S'),
    ],
  );

  static const fullBodyStretch = QuickSession(
    id: 'full_body_stretch',
    name: 'Full-body stretch',
    minutes: 8,
    summary: 'Wind down · no equipment',
    group: QuickSessionGroup.recover,
    kinds: {QuickSessionFilter.stretch},
    image: _blue,
    description: 'Long, unhurried holds from the hips to the shoulders. '
        'Good at the end of a day, or the day after a hard session.',
    pacing: 'NO REST',
    equipment: 'None',
    moves: [
      QuickSessionMove('Child’s Pose', '60 S'),
      QuickSessionMove('Cat-Cow', '60 S'),
      QuickSessionMove('World’s Greatest Stretch', '45 S / SIDE'),
      QuickSessionMove('Forward Fold', '60 S'),
      QuickSessionMove('Chest Opener', '60 S'),
    ],
  );

  static const shoulderMobility = QuickSession(
    id: 'shoulder_mobility',
    name: 'Shoulder mobility',
    minutes: 12,
    summary: 'Bands optional',
    group: QuickSessionGroup.recover,
    kinds: {QuickSessionFilter.mobility},
    image: _rail,
    imageFocusY: -0.4,
    description: 'Slow circles, slides and pulls that take the shoulders '
        'through their full range before or between pulling days.',
    pacing: 'NO REST',
    equipment: 'Band, optional',
    moves: [
      QuickSessionMove('Arm Circles', '60 S'),
      QuickSessionMove('Wall Slides', '60 S'),
      QuickSessionMove('Band Pull-Aparts', '60 S'),
      QuickSessionMove('Thread the Needle', '45 S / SIDE'),
      QuickSessionMove('Scapular Push-Up', '60 S'),
    ],
  );

  static const hipsAndHamstrings = QuickSession(
    id: 'hips_and_hamstrings',
    name: 'Hips & hamstrings',
    minutes: 10,
    summary: 'After leg days',
    group: QuickSessionGroup.recover,
    kinds: {QuickSessionFilter.stretch, QuickSessionFilter.mobility},
    image: _blue,
    imageFocusY: 0.4,
    description: 'Opens the hips and lengthens the back of the legs, for '
        'the day after squats and hinges.',
    pacing: 'NO REST',
    equipment: 'None',
    moves: [
      QuickSessionMove('90/90 Hip Switches', '60 S'),
      QuickSessionMove('Couch Stretch', '45 S / SIDE'),
      QuickSessionMove('Hamstring Fold', '60 S'),
      QuickSessionMove('Pigeon Pose', '45 S / SIDE'),
      QuickSessionMove('Deep Squat Hold', '60 S'),
    ],
  );

  /// Every session, in the order the list shows them inside their group.
  static const all = [
    morningEnergy,
    pushUpPrimer,
    core,
    fullBodyStretch,
    shoulderMobility,
    hipsAndHamstrings,
  ];

  /// The few the Train tab shows under the program card.
  static const featured = [morningEnergy, fullBodyStretch, shoulderMobility];
}
