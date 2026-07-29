import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_balance_advice.dart';
import 'package:forma_app/features/home/program_balance_view.dart';
import 'package:forma_app/features/home/program_day_items.dart';

void main() {
  group('weekly balance copy', () {
    test('a missing movement offers a tree, then a supporting exercise', () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
      ];
      final report = _reportFor(
        'Vertical pull',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
          hasGym: false,
        ),
      );

      expect(report.headline, 'Needs more work');
      expect(report.explanation, contains('has 0 blocks this week'));
      expect(report.actionsLabel, 'WAYS TO IMPROVE IT');
      expect(report.advice.first.title, 'Add a Pullups progression');
      expect(report.advice.last.title, 'Add a vertical pull exercise');
      // Bodyweight kit, so no lat pulldown.
      expect(report.advice.last.detail, contains('Chin-up'));
      // Adding days cannot fix a week with nothing to schedule.
      expect(
        report.advice.map((a) => a.title),
        isNot(contains('Add another training day')),
      );
    });

    test('a missing movement never suggests a tree already running', () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
      ];
      final report = _reportFor(
        'Vertical pull',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
          skillTracks: [_track(SkillCategoryCatalog.pullupsId, 'weighted')],
        ),
      );

      expect(
        report.advice.map((a) => a.title),
        isNot(contains('Add a Pullups progression')),
      );
      expect(report.advice.single.title, 'Add a vertical pull exercise');
    });

    test('a missing movement never suggests a locked tree', () {
      // Handstand pushups are the other vertical-push tree and stay locked
      // until diamond pushups are mastered, so dips must be the suggestion.
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('pullups', 'Pull Ups')]),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(report.advice.first.title, 'Add a Dips progression');
    });

    test('a split that rarely revisits the movement is the split', () {
      // Three days of upper/lower is 1.5 upper days a week.
      final week = [
        _day(
            0, TrainingSessionType.upper, [_progression('dips', 'Bench Dips')]),
        _day(2, TrainingSessionType.lower, const []),
        _day(4, TrainingSessionType.upper, const []),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.upperLower,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(report.explanation, contains('Aim for 3–4 blocks a week'));
      expect(report.advice.map((a) => a.title), [
        'Add another training day',
        'Change your split',
      ]);
      expect(
        report.advice.last.detail,
        'Choose a split that trains vertical push at least twice per week.',
      );
    });

    test('a full-body program is asked to train more often, not to re-split',
        () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 1,
        ),
      );

      expect(report.advice.single.title, 'Add another training day');
      expect(report.advice.single.detail,
          'Train your full-body program more frequently.');
    });

    test('empty applicable days reschedule the exercise already there', () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
        _day(2, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
        _day(4, TrainingSessionType.fullBody, const []),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(report.advice.first.title, 'Add Bench Dips to another workout');
      expect(
        report.advice.first.detail,
        'Train vertical push on Friday to move towards 3–4 blocks a week.',
      );
      expect(report.advice.last.title, 'Add another vertical push exercise');
      // The split gives it three chances a week, so the split is not at fault.
      expect(
        report.advice.map((a) => a.title),
        isNot(contains('Change your split')),
      );
    });

    test('too many days thins the movement out before touching the schedule',
        () {
      final week = [
        for (final weekday in [0, 1, 2, 3, 4])
          _day(weekday, TrainingSessionType.fullBody,
              [_progression('dips', 'Bench Dips')]),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 5,
        ),
      );

      expect(report.headline, 'Too much work');
      expect(report.explanation, contains('has 5 blocks this week'));
      expect(report.explanation, contains('recommends 3–4 blocks a week'));
      expect(report.actionsLabel, 'WAYS TO REDUCE IT');
      expect(report.advice.first.title, 'Reduce vertical push frequency');
      expect(report.advice.first.detail, contains('Bench Dips'));
      expect(
        report.advice.map((a) => a.title),
        isNot(contains('Reduce your training days')),
      );
    });

    test('the schedule is only blamed when several movements are over', () {
      final week = [
        for (final weekday in [0, 1, 2, 3, 4])
          _day(weekday, TrainingSessionType.fullBody, [
            _progression('dips', 'Bench Dips'),
            _progression('pullups', 'Pull Ups'),
          ]),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 5,
        ),
      );

      expect(
          report.advice.map((a) => a.title),
          containsAll(const [
            'Reduce vertical push frequency',
            'Reduce your training days',
            'Change your split',
          ]));
    });

    test('doubled-up days drop the supporting exercise, not the progression',
        () {
      final week = [
        _day(0, TrainingSessionType.fullBody, [
          _progression('dips', 'Bench Dips'),
          _standalone('Barbell overhead press', 'parallel_bar_dips'),
        ]),
        for (final weekday in [2, 4, 6])
          _day(weekday, TrainingSessionType.fullBody,
              [_progression('dips', 'Bench Dips')]),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 4,
        ),
      );

      // Four days is within what the ceiling allows, so this is a volume
      // problem, not a frequency one — no "reduce frequency" line.
      expect(report.advice.map((a) => a.title), const [
        'Remove Barbell overhead press',
        'Replace Barbell overhead press',
      ]);
    });

    test('two trees on one movement pause the one behind no goal', () {
      final week = [
        for (final weekday in [0, 2, 4])
          _day(weekday, TrainingSessionType.fullBody, [
            _progression('dips', 'Bench Dips'),
            _progression('handstand_pushups', 'Pike Pushup'),
          ]),
      ];
      final report = _reportFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
          skillTracks: [
            _track(SkillCategoryCatalog.dipsId, 'weighted'),
            _track(SkillCategoryCatalog.handstandPushupsId, 'main'),
          ],
          goalSkillCategoryIds: {SkillCategoryCatalog.handstandPushupsId},
        ),
      );

      expect(
        report.advice.map((a) => a.title),
        contains('Pause Dips'),
      );
      expect(
        report.advice.map((a) => a.title),
        isNot(contains('Pause Handstand Pushups')),
      );
    });
  });

  group('weekly balance verdicts', () {
    test('weekly blocks read on the same scale for every movement', () {
      // 0–2 short, 3–4 balanced, 5 and up too much — checked on a week wide
      // enough that frequency never decides the answer.
      final verdicts = [
        for (var blocks = 0; blocks <= 5; blocks++)
          _entryFor(
            'Vertical push',
            week: [
              for (var weekday = 0; weekday < 6; weekday++)
                _day(
                  weekday,
                  TrainingSessionType.fullBody,
                  weekday < blocks
                      ? [_progression('dips', 'Bench Dips')]
                      : const [],
                ),
            ],
            context: _context(
              programType: TrainingProgramType.fullBody,
              trainingDaysPerWeek: 6,
            ),
          ).verdict,
      ];

      expect(verdicts, const [
        BalanceVerdict.missing,
        BalanceVerdict.needsWork,
        BalanceVerdict.needsWork,
        BalanceVerdict.balanced,
        BalanceVerdict.balanced,
        BalanceVerdict.tooMuch,
      ]);
    });

    test('the benchmark does not move with the split', () {
      // Four days of upper/lower: horizontal pull gets both upper days, so
      // the split has nothing more to give it — and two blocks is still two.
      final week = [
        for (final weekday in [0, 2])
          _day(weekday, TrainingSessionType.upper,
              [_progression(SkillCategoryCatalog.rowsId, 'Australian Row')]),
        for (final weekday in [1, 3])
          _day(weekday, TrainingSessionType.lower, const []),
      ];
      final context = _context(
        programType: TrainingProgramType.upperLower,
        trainingDaysPerWeek: 4,
      );
      final entry = _entryFor('Horizontal pull', week: week, context: context);

      expect(entry.opportunities, 2);
      expect(entry.weeklyBlocks, 2);
      expect(entry.verdict, BalanceVerdict.needsWork);

      // Nothing left to schedule, so the schedule itself is on the list.
      final report = _reportFor('Horizontal pull', week: week, context: context);
      expect(report.headline, 'Needs more work');
      expect(report.advice.map((a) => a.title), const [
        'Add another horizontal pull exercise',
        'Add another training day',
        'Change your split',
      ]);
    });

    test('enough work stacked on one day is a note, not a fault', () {
      final week = [
        _day(0, TrainingSessionType.fullBody, [
          _progression('dips', 'Bench Dips'),
          _standalone('Barbell overhead press', 'parallel_bar_dips'),
          _standalone('Dumbbell shoulder press', 'pike_push_up'),
        ]),
        _day(2, TrainingSessionType.fullBody, const []),
      ];
      final context = _context(
        programType: TrainingProgramType.fullBody,
        trainingDaysPerWeek: 2,
      );
      final entry = _entryFor('Vertical push', week: week, context: context);

      expect(entry.weeklyBlocks, 3);
      expect(entry.times, 1);
      expect(entry.verdict, BalanceVerdict.concentrated);

      final report = _reportFor('Vertical push', week: week, context: context);
      expect(report.headline, 'Concentrated in one workout');
      expect(
        report.explanation,
        startsWith('Vertical push has enough weekly work, but most of it is '
            'concentrated in one workout.'),
      );
      // The volume is already there, so nothing here adds any.
      expect(report.advice.single.title, 'Move Bench Dips to Wednesday');
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

      expect(
        categories.map((entry) => entry.label),
        containsAllInOrder(const ['Squats & lunges', 'Glutes & hamstrings']),
      );
      expect(categories.map((entry) => entry.label), isNot(contains('Legs')));

      final squats =
          categories.firstWhere((entry) => entry.label == 'Squats & lunges');
      final hinges =
          categories.firstWhere((entry) => entry.label == 'Glutes & hamstrings');

      // Three squat blocks are three squat blocks — they say nothing about
      // the hinge line, which has nothing in it.
      expect(squats.weeklyBlocks, 3);
      expect(squats.verdict, BalanceVerdict.balanced);
      expect(hinges.weeklyBlocks, 0);
      expect(hinges.verdict, BalanceVerdict.missing);
    });

    test('a hinge added to every leg day settles that line on its own', () {
      final week = [
        for (final weekday in [0, 2, 4])
          _day(weekday, TrainingSessionType.fullBody, [
            _progression(SkillCategoryCatalog.squatId, 'Box Pistol Squat'),
            _standalone('Single Leg RDL', 'single_leg_rdl'),
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
        expect(entry.weeklyBlocks, 3, reason: label);
        expect(entry.verdict, BalanceVerdict.balanced, reason: label);
      }
    });
  });
}

BalanceCategory _entryFor(
  String label, {
  required List<ProgramWeekDay> week,
  required BalanceProgramContext context,
}) {
  return balanceFromWeek(week, context: context)
      .firstWhere((entry) => entry.label == label);
}

BalanceReport _reportFor(
  String label, {
  required List<ProgramWeekDay> week,
  required BalanceProgramContext context,
}) {
  final categories = balanceFromWeek(week, context: context);
  return balanceReportFor(
    entry: categories.firstWhere((entry) => entry.label == label),
    week: week,
    allCategories: categories,
    context: context,
  );
}

BalanceProgramContext _context({
  required TrainingProgramType programType,
  required int trainingDaysPerWeek,
  bool hasGym = true,
  List<SkillTrack> skillTracks = const [],
  Set<String> goalSkillCategoryIds = const {},
}) {
  return BalanceProgramContext(
    programType: programType,
    trainingDaysPerWeek: trainingDaysPerWeek,
    hasGym: hasGym,
    skillTracks: skillTracks,
    goalSkillCategoryIds: goalSkillCategoryIds,
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

SkillTrack _track(String skillCategoryId, String branchId) {
  return SkillTrack(
    skillCategoryId: skillCategoryId,
    branchId: branchId,
    included: true,
    updatedAt: DateTime(2026, 6, 19),
  );
}
