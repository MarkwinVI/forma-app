import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_balance_view.dart';
import 'package:forma_app/features/home/program_day_items.dart';

void main() {
  group('weekly balance verdicts', () {
    test('a three-day full body program recommends three days a movement', () {
      expect(
        _scale(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
          session: TrainingSessionType.fullBody,
        ),
        const [
          BalanceVerdict.missing,
          BalanceVerdict.low,
          BalanceVerdict.adequate,
          BalanceVerdict.recommended,
          BalanceVerdict.high,
          BalanceVerdict.veryHigh,
        ],
      );
    });

    test('a four-day push/pull split recommends two, not three', () {
      // Push days come round twice a week, so twice is the whole of what the
      // split asks for — a third day is already past it.
      expect(
        _scale(
          programType: TrainingProgramType.pushPull,
          trainingDaysPerWeek: 4,
          session: TrainingSessionType.push,
        ),
        const [
          BalanceVerdict.missing,
          BalanceVerdict.low,
          BalanceVerdict.recommended,
          BalanceVerdict.high,
          BalanceVerdict.high,
          BalanceVerdict.veryHigh,
        ],
      );
    });

    test('a four-day upper/lower split reads the same as push/pull', () {
      expect(
        _scale(
          programType: TrainingProgramType.upperLower,
          trainingDaysPerWeek: 4,
          session: TrainingSessionType.upper,
        ),
        const [
          BalanceVerdict.missing,
          BalanceVerdict.low,
          BalanceVerdict.recommended,
          BalanceVerdict.high,
          BalanceVerdict.high,
          BalanceVerdict.veryHigh,
        ],
      );
    });

    test('the target never leaves two and three, wherever the split lands',
        () {
      int targetFor(TrainingProgramType programType, int days) {
        return _entryFor(
          'Vertical push',
          week: const [],
          context: _context(
            programType: programType,
            trainingDaysPerWeek: days,
          ),
        ).target;
      }

      // Three days of upper/lower is 1.5 upper days a week — still asked for
      // twice. Six days of full body could reach six — still asked for three,
      // and two days of it is asked for three all the same: the movement
      // needs what it needs, and the schedule is what falls short.
      expect(targetFor(TrainingProgramType.upperLower, 3), 2);
      expect(targetFor(TrainingProgramType.fullBody, 2), 3);
      expect(targetFor(TrainingProgramType.fullBody, 6), 3);
      expect(targetFor(TrainingProgramType.pushPull, 6), 3);
    });

    test('two days of full body is adequate, not the recommendation', () {
      // Full body asks for three whatever the week holds, so a two-day
      // program reads as short of it rather than as balanced.
      final entry = _entryFor(
        'Vertical push',
        week: _fullBodyWeek(const [0, 3]),
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 2,
        ),
      );

      expect(entry.target, 3);
      expect(entry.times, 2);
      expect(entry.verdict, BalanceVerdict.adequate);
    });

    test('two exercises of a movement in one session are one day', () {
      final week = [
        _day(0, TrainingSessionType.fullBody, [
          _progression('dips', 'Bench Dips'),
          _standalone('Barbell overhead press', 'dips_parallel_bar_dips'),
          _standalone(
              'Dumbbell shoulder press', 'handstand_pushups_pike_push_up'),
        ]),
        _day(2, TrainingSessionType.fullBody, const []),
        _day(4, TrainingSessionType.fullBody, const []),
      ];
      final entry = _entryFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      // Three exercises, one day — volume, not frequency.
      expect(entry.times, 1);
      expect(entry.verdict, BalanceVerdict.low);
    });

    test('core and skill work are not measured against the six categories',
        () {
      final categories = balanceFromWeek(
        const [],
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(categories.map((entry) => entry.label), const [
        'Horizontal push',
        'Vertical push',
        'Horizontal pull',
        'Vertical pull',
        'Squats & lunges',
        'Glutes & hamstrings',
      ]);
    });

    test('only missing, low and very high count the program unbalanced', () {
      expect(
        {
          for (final verdict in BalanceVerdict.values)
            verdict: verdict.onTarget,
        },
        const {
          BalanceVerdict.missing: false,
          BalanceVerdict.low: false,
          BalanceVerdict.adequate: true,
          BalanceVerdict.recommended: true,
          BalanceVerdict.high: true,
          BalanceVerdict.veryHigh: false,
        },
      );
    });

    test('squats and hinges are judged apart, never as one leg line', () {
      final week = [
        for (final weekday in [0, 2, 4])
          _day(weekday, TrainingSessionType.fullBody, [
            _progression(SkillCategoryCatalog.squatId, 'Box Pistol Squat'),
          ]),
      ];
      final categories = balanceFromWeek(
        week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      final squats =
          categories.firstWhere((entry) => entry.label == 'Squats & lunges');
      final hinges =
          categories.firstWhere((entry) => entry.label == 'Glutes & hamstrings');

      // Three squat days are three squat days — they say nothing about the
      // hinge line, which has nothing in it.
      expect(squats.times, 3);
      expect(squats.verdict, BalanceVerdict.recommended);
      expect(hinges.times, 0);
      expect(hinges.verdict, BalanceVerdict.missing);
    });

    test('a hinge added to every leg day settles that line on its own', () {
      final week = [
        for (final weekday in [0, 2, 4])
          _day(weekday, TrainingSessionType.fullBody, [
            _progression(SkillCategoryCatalog.squatId, 'Box Pistol Squat'),
            _standalone('Single Leg RDL', 'hinge_single_leg_rdl'),
          ]),
      ];
      final categories = balanceFromWeek(
        week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      for (final label in const ['Squats & lunges', 'Glutes & hamstrings']) {
        final entry = categories.firstWhere((entry) => entry.label == label);
        expect(entry.times, 3, reason: label);
        expect(entry.verdict, BalanceVerdict.recommended, reason: label);
      }
    });
  });

  group('weekly balance expected frequency', () {
    test('three days of push/pull expect push twice and pull once', () {
      final categories = balanceFromWeek(
        _pushPullWeek(const [0, 1, 2]),
        context: _context(
          programType: TrainingProgramType.pushPull,
          trainingDaysPerWeek: 3,
        ),
      );

      final push = categories.firstWhere((e) => e.label == 'Horizontal push');
      final pull = categories.firstWhere((e) => e.label == 'Horizontal pull');

      expect(push.expected, 2);
      expect(pull.expected, 1);
      // Both are trained as often as the program can — the pull line is
      // still short of what it should get.
      expect(pull.times, 1);
      expect(pull.shortOfProgram, isFalse);
      expect(pull.shortOfSplit, isTrue);
    });

    test('a full body week expects every movement on every day', () {
      final categories = balanceFromWeek(
        _fullBodyWeek(const [0, 2, 4]),
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      for (final entry in categories) {
        expect(entry.expected, 3, reason: entry.label);
        expect(entry.shortOfSplit, isFalse, reason: entry.label);
      }
    });
  });

  group('weekly balance banner', () {
    test('a week that meets its target reads as balanced', () {
      final banner = _bannerFor(
        _fullBodyWeek(const [0, 2, 4]),
        programType: TrainingProgramType.fullBody,
        trainingDaysPerWeek: 3,
      );

      expect(banner.cause, BalanceCause.balanced);
      expect(banner.headline, 'Your weekly balance looks good.');
      expect(
        banner.detail,
        'Your main movement patterns are being trained at the recommended '
        'frequency for your program.',
      );
    });

    test('three days of push/pull blames the schedule, not the workouts', () {
      final banner = _bannerFor(
        _pushPullWeek(const [0, 1, 2]),
        programType: TrainingProgramType.pushPull,
        trainingDaysPerWeek: 3,
      );

      expect(banner.cause, BalanceCause.schedule);
      expect(
        banner.headline,
        'Your weekly balance is uneven because you’re training a Push / Pull '
        'routine 3 days per week.',
      );
      expect(
        banner.detail,
        'Increase to 4 training days, switch to Full Body, or add standalone '
        'exercises to the low-frequency areas below.',
      );
    });

    test('an upper/lower week names its own split', () {
      final banner = _bannerFor(
        _upperLowerWeek(const [0, 1, 2]),
        programType: TrainingProgramType.upperLower,
        trainingDaysPerWeek: 3,
      );

      expect(banner.cause, BalanceCause.schedule);
      expect(
        banner.headline,
        'Your weekly balance is uneven because you’re training an Upper / '
        'Lower routine 3 days per week.',
      );
    });

    test('rows pulled out of a full body week blames the workouts', () {
      // The split would have covered horizontal pull three times; two of the
      // three rows were deleted, so adding a training day fixes nothing.
      final week = [
        for (final weekday in const [0, 2, 4])
          _day(
            weekday,
            TrainingSessionType.fullBody,
            weekday == 0
                ? _fullBodyItems()
                : [
                    for (final item in _fullBodyItems())
                      if (!item.id.contains(SkillCategoryCatalog.rowsId)) item,
                  ],
          ),
      ];
      final categories = balanceFromWeek(
        week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );
      final pull = categories.firstWhere((e) => e.label == 'Horizontal pull');

      expect(pull.expected, 3);
      expect(pull.times, 1);
      expect(pull.shortOfProgram, isTrue);
      expect(pull.shortOfSplit, isFalse);

      final banner = balanceBannerFor(
        categories,
        _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );
      expect(banner.cause, BalanceCause.workoutEdits);
      expect(
        banner.headline,
        'Some movement patterns are missing or trained less often because of '
        'changes to your workouts.',
      );
    });

    test('a thin split plus a deleted exercise reads as both', () {
      // Three days of push/pull already leaves the pull day short, and the
      // rows are gone from it too.
      final week = [
        for (final weekday in const [0, 1, 2])
          _day(
            weekday,
            weekday == 1 ? TrainingSessionType.pull : TrainingSessionType.push,
            weekday == 1
                ? [
                    for (final item in _pullItems())
                      if (!item.id.contains(SkillCategoryCatalog.rowsId)) item,
                  ]
                : _pushItems(),
          ),
      ];
      final banner = balanceBannerFor(
        balanceFromWeek(
          week,
          context: _context(
            programType: TrainingProgramType.pushPull,
            trainingDaysPerWeek: 3,
          ),
        ),
        _context(
          programType: TrainingProgramType.pushPull,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(banner.cause, BalanceCause.mixed);
      expect(
        banner.detail,
        'Restore the missing movement patterns first. You can then adjust '
        'your training days or split to improve the remaining low-frequency '
        'areas.',
      );
    });

    test('a movement added back by hand settles the week', () {
      // The split would only reach horizontal pull once; the user put a row
      // on a push day, so nothing is short and nothing needs saying.
      final week = [
        for (final weekday in const [0, 1, 2])
          _day(
            weekday,
            weekday == 1 ? TrainingSessionType.pull : TrainingSessionType.push,
            weekday == 1 ? _pullItems() : _pushItems(),
          ),
      ];
      final patched = [
        for (final day in week)
          if (day.weekday == 0)
            _day(day.weekday, day.sessionType, [
              ...day.items,
              _progression(SkillCategoryCatalog.rowsId, 'Australian Row'),
              _progression(SkillCategoryCatalog.pullupsId, 'Pull Ups'),
              _progression(SkillCategoryCatalog.hingeId, 'Single Leg RDL'),
            ])
          else
            day,
      ];
      final banner = _bannerFor(
        patched,
        programType: TrainingProgramType.pushPull,
        trainingDaysPerWeek: 3,
      );

      expect(banner.cause, BalanceCause.balanced);
    });

    test('a week trained near daily warns about recovery instead', () {
      final banner = _bannerFor(
        _fullBodyWeek(const [0, 1, 2, 3, 4]),
        programType: TrainingProgramType.fullBody,
        trainingDaysPerWeek: 5,
      );

      expect(banner.cause, BalanceCause.veryHigh);
      expect(
        banner.headline,
        'Some movement patterns are being trained very frequently.',
      );
      expect(
        banner.detail,
        'Review the areas below and reduce training frequency if recovery or '
        'performance becomes an issue.',
      );
    });
  });

  group('weekly balance page', () {
    testWidgets('the banner sits above the movement rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProgramBalanceView(
            week: _pushPullWeek(const [0, 1, 2]),
            program: _context(
              programType: TrainingProgramType.pushPull,
              trainingDaysPerWeek: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final banner = find.text(
        'Your weekly balance is uneven because you\u2019re training a Push / '
        'Pull routine 3 days per week.',
      );
      expect(banner, findsOneWidget);
      expect(find.text('Horizontal pull'), findsOneWidget);
      expect(
        tester.getCenter(banner).dy,
        lessThan(tester.getCenter(find.text('Horizontal pull')).dy),
      );
    });

    testWidgets('a movement page separates its volume from its frequency',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProgramBalanceView(
            week: [
              _day(0, TrainingSessionType.fullBody, [
                ..._fullBodyItems(),
                _progression(SkillCategoryCatalog.rowsId, 'Ring Row'),
              ]),
              _day(2, TrainingSessionType.fullBody, _fullBodyItems()),
              _day(4, TrainingSessionType.fullBody, _fullBodyItems()),
            ],
            program: _context(
              programType: TrainingProgramType.fullBody,
              trainingDaysPerWeek: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Horizontal pull'));
      await tester.pumpAndSettle();

      // Four rows across three days: the fourth is volume, and the week is
      // still trained at the recommended frequency.
      expect(find.textContaining('4 blocks across 3 days'), findsOneWidget);
      expect(find.textContaining('Recommended'), findsWidgets);
    });
  });

  group('weekly balance status copy', () {
    String copyFor(int days) {
      return balanceStatusCopy(
        _entryFor(
          'Vertical push',
          week: [
            for (var weekday = 0; weekday < 6; weekday++)
              _day(
                weekday,
                TrainingSessionType.fullBody,
                weekday < days
                    ? [_progression('dips', 'Bench Dips')]
                    : const [],
              ),
          ],
          context: _context(
            programType: TrainingProgramType.fullBody,
            trainingDaysPerWeek: 3,
          ),
        ),
      );
    }

    test('each exposure level gets its own sentence', () {
      expect(
        copyFor(0),
        'You’re not currently training vertical push. Add a vertical push '
        'exercise to one of your workouts.',
      );
      expect(
        copyFor(1),
        'You’re training vertical push once per week. Add a vertical push '
        'exercise to another workout to train it more consistently.',
      );
      expect(
        copyFor(2),
        'You’re training vertical push twice per week. That’s enough to make '
        'solid progress, but adding it to one more workout would match the '
        'recommended frequency for your program.',
      );
      expect(
        copyFor(3),
        'You’re training vertical push at the recommended frequency for your '
        'program.',
      );
      expect(
        copyFor(4),
        'You’re training vertical push more often than your program requires. '
        'This can work well if your training volume and recovery are '
        'appropriate.',
      );
      expect(
        copyFor(5),
        'You’re training vertical push very frequently. Consider removing it '
        'from one or more workout days if recovery or performance becomes an '
        'issue.',
      );
    });
  });
}

BalanceBanner _bannerFor(
  List<ProgramWeekDay> week, {
  required TrainingProgramType programType,
  required int trainingDaysPerWeek,
}) {
  final context = _context(
    programType: programType,
    trainingDaysPerWeek: trainingDaysPerWeek,
  );
  return balanceBannerFor(
    balanceFromWeek(week, context: context),
    context,
  );
}

/// One exercise per movement pattern the session trains — the shape of a
/// generated workout, before anything is added or taken away.
List<ProgramDayItem> _fullBodyItems() => [
      _progression(SkillCategoryCatalog.pushupsId, 'Push Ups'),
      _progression(SkillCategoryCatalog.dipsId, 'Bench Dips'),
      _progression(SkillCategoryCatalog.rowsId, 'Australian Row'),
      _progression(SkillCategoryCatalog.pullupsId, 'Pull Ups'),
      _progression(SkillCategoryCatalog.squatId, 'Box Pistol Squat'),
      _progression(SkillCategoryCatalog.hingeId, 'Single Leg RDL'),
    ];

List<ProgramDayItem> _pushItems() => [
      _progression(SkillCategoryCatalog.pushupsId, 'Push Ups'),
      _progression(SkillCategoryCatalog.dipsId, 'Bench Dips'),
      _progression(SkillCategoryCatalog.squatId, 'Box Pistol Squat'),
    ];

List<ProgramDayItem> _pullItems() => [
      _progression(SkillCategoryCatalog.rowsId, 'Australian Row'),
      _progression(SkillCategoryCatalog.pullupsId, 'Pull Ups'),
      _progression(SkillCategoryCatalog.hingeId, 'Single Leg RDL'),
    ];

List<ProgramWeekDay> _fullBodyWeek(List<int> weekdays) => [
      for (final weekday in weekdays)
        _day(weekday, TrainingSessionType.fullBody, _fullBodyItems()),
    ];

/// Push, pull, push — the rotation a three-day push/pull program runs, and
/// the reason its pull movements come up once.
List<ProgramWeekDay> _pushPullWeek(List<int> weekdays) => [
      for (var i = 0; i < weekdays.length; i++)
        _day(
          weekdays[i],
          i.isEven ? TrainingSessionType.push : TrainingSessionType.pull,
          i.isEven ? _pushItems() : _pullItems(),
        ),
    ];

List<ProgramWeekDay> _upperLowerWeek(List<int> weekdays) => [
      for (var i = 0; i < weekdays.length; i++)
        _day(
          weekdays[i],
          i.isEven ? TrainingSessionType.upper : TrainingSessionType.lower,
          i.isEven
              ? [
                  _progression(SkillCategoryCatalog.pushupsId, 'Push Ups'),
                  _progression(SkillCategoryCatalog.dipsId, 'Bench Dips'),
                  _progression(SkillCategoryCatalog.rowsId, 'Australian Row'),
                  _progression(SkillCategoryCatalog.pullupsId, 'Pull Ups'),
                ]
              : [
                  _progression(SkillCategoryCatalog.squatId, 'Box Pistol Squat'),
                  _progression(SkillCategoryCatalog.hingeId, 'Single Leg RDL'),
                ],
        ),
    ];

/// The verdict at each exposure from none to five days, for one split.
List<BalanceVerdict> _scale({
  required TrainingProgramType programType,
  required int trainingDaysPerWeek,
  required TrainingSessionType session,
}) {
  return [
    for (var days = 0; days <= 5; days++)
      _entryFor(
        'Vertical push',
        week: [
          for (var weekday = 0; weekday < 6; weekday++)
            _day(
              weekday,
              session,
              weekday < days
                  ? [_progression('dips', 'Bench Dips')]
                  : const [],
            ),
        ],
        context: _context(
          programType: programType,
          trainingDaysPerWeek: trainingDaysPerWeek,
        ),
      ).verdict,
  ];
}

BalanceCategory _entryFor(
  String label, {
  required List<ProgramWeekDay> week,
  required BalanceProgramContext context,
}) {
  return balanceFromWeek(week, context: context)
      .firstWhere((entry) => entry.label == label);
}

BalanceProgramContext _context({
  required TrainingProgramType programType,
  required int trainingDaysPerWeek,
}) {
  return BalanceProgramContext(
    programType: programType,
    trainingDaysPerWeek: trainingDaysPerWeek,
  );
}

ProgramWeekDay _day(
  int weekday,
  TrainingSessionType sessionType,
  List<ProgramDayItem> items,
) {
  return ProgramWeekDay(
    weekday: weekday,
    sessionType: sessionType,
    items: items,
  );
}

ProgramDayItem _progression(String skillCategoryId, String name) {
  return ProgramDayItem(
    id: 'track-$skillCategoryId-$name',
    kind: ProgramDayItemKind.progression,
    name: name,
    skillCategoryId: skillCategoryId,
  );
}

/// A supporting exercise. [exerciseId] is what decides its movement pattern,
/// exactly as it does for a real standalone item.
ProgramDayItem _standalone(String name, String exerciseId) {
  return ProgramDayItem(
    id: 'custom-$name',
    kind: ProgramDayItemKind.exercise,
    name: name,
    exerciseId: exerciseId,
  );
}
