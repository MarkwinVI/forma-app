/// Quick sessions: short extras offered under the day's program workout —
/// a wake-up, a stretch, a little core — for the days and moments between
/// program sessions. They sit beside the program and never replace it.
///
/// This is the catalogue and its copy. The player that runs a session
/// reads the same moves (quick_session_player.dart); nothing a quick
/// session does is logged or feeds the program.
library;

/// One step of a quick session: what to do, and for how long or how many.
///
/// A move is either timed — the player counts it down and moves on by
/// itself — or counted, where the player waits to be told it is done. A
/// hold is timed; a push-up is counted, since a clock on a strength move
/// only hurries the reps.
class QuickSessionMove {
  final String name;

  /// Seconds of work for a timed move (each side's, when [perSide]); null
  /// for a counted one.
  final int? seconds;

  /// The reps to aim for on a counted move; null for a timed one.
  final int? reps;

  /// Done once on the left and once on the right.
  final bool perSide;

  const QuickSessionMove.timed(this.name, int this.seconds,
      {this.perSide = false})
      : reps = null;

  const QuickSessionMove.reps(this.name, int this.reps)
      : seconds = null,
        perSide = false;

  bool get isTimed => seconds != null;

  /// "45 S", "60 S / SIDE", "10×" — printed in the mono voice beside the
  /// name.
  String get amount => isTimed
      ? '$seconds S${perSide ? ' / SIDE' : ''}'
      : '$reps×';
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

  /// Seconds of rest between two moves; 0 when they run on.
  final int restSeconds;

  /// How many times the list of moves is gone through.
  final int rounds;

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
    required this.equipment,
    required this.moves,
    this.kinds = const {},
    this.imageFocusY = 0,
    this.restSeconds = 0,
    this.rounds = 1,
  });

  /// How the moves run on: "NO REST", "20 S REST".
  String get pacing => restSeconds == 0 ? 'NO REST' : '$restSeconds S REST';

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
    equipment: 'None',
    rounds: 2,
    moves: [
      QuickSessionMove.timed('Jumping Jacks', 45),
      QuickSessionMove.timed('Push-Up (Incline)', 45),
      QuickSessionMove.timed('Squat (Bodyweight)', 45),
      QuickSessionMove.timed('Mountain Climbers', 45),
      QuickSessionMove.timed('Plank', 45),
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
    restSeconds: 20,
    rounds: 2,
    equipment: 'None',
    moves: [
      QuickSessionMove.reps('Push-Up (Incline)', 10),
      QuickSessionMove.reps('Push-Up (Knee)', 8),
      QuickSessionMove.timed('Plank Shoulder Taps', 40),
      QuickSessionMove.reps('Push-Up (Slow Lowering)', 5),
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
    restSeconds: 15,
    rounds: 2,
    equipment: 'None',
    moves: [
      QuickSessionMove.timed('Hollow Hold', 30),
      QuickSessionMove.timed('Plank', 45),
      QuickSessionMove.timed('Dead Bug', 45),
      QuickSessionMove.timed('Side Plank', 30, perSide: true),
      QuickSessionMove.timed('Hollow Rocks', 30),
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
    equipment: 'None',
    moves: [
      QuickSessionMove.timed('Child’s Pose', 60),
      QuickSessionMove.timed('Cat-Cow', 60),
      QuickSessionMove.timed('World’s Greatest Stretch', 45, perSide: true),
      QuickSessionMove.timed('Forward Fold', 60),
      QuickSessionMove.timed('Chest Opener', 60),
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
    equipment: 'Band, optional',
    moves: [
      QuickSessionMove.timed('Arm Circles', 60),
      QuickSessionMove.timed('Wall Slides', 60),
      QuickSessionMove.timed('Band Pull-Aparts', 60),
      QuickSessionMove.timed('Thread the Needle', 45, perSide: true),
      QuickSessionMove.timed('Scapular Push-Up', 60),
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
    equipment: 'None',
    moves: [
      QuickSessionMove.timed('90/90 Hip Switches', 60),
      QuickSessionMove.timed('Couch Stretch', 45, perSide: true),
      QuickSessionMove.timed('Hamstring Fold', 60),
      QuickSessionMove.timed('Pigeon Pose', 45, perSide: true),
      QuickSessionMove.timed('Deep Squat Hold', 60),
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
