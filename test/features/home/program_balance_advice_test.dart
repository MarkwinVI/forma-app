import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/models/training_program_model.dart';
import 'package:forma_app/features/home/program_balance_advice.dart';
import 'package:forma_app/features/home/program_balance_view.dart';
import 'package:forma_app/features/home/program_day_items.dart';

void main() {
  group('weekly balance advice', () {
    test('a missing movement offers a tree, then a supporting exercise', () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
      ];
      final advice = _adviceFor(
        'Vertical pull',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
          hasGym: false,
        ),
      );

      expect(advice.first.title, 'Add a Pullups progression');
      expect(advice.last.title, 'Add a vertical pull exercise');
      // Bodyweight kit, so no lat pulldown.
      expect(advice.last.detail, contains('Chin-up'));
      // Adding days cannot fix a week with nothing to schedule.
      expect(
        advice.map((a) => a.title),
        isNot(contains('Add another training day')),
      );
    });

    test('a missing movement never suggests a tree already running', () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
      ];
      final advice = _adviceFor(
        'Vertical pull',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
          skillTracks: [_track(SkillCategoryCatalog.pullupsId, 'weighted')],
        ),
      );

      expect(
        advice.map((a) => a.title),
        isNot(contains('Add a Pullups progression')),
      );
      expect(advice.single.title, 'Add a vertical pull exercise');
    });

    test('a missing movement never suggests a locked tree', () {
      // Handstand pushups are the other vertical-push tree and stay locked
      // until diamond pushups are mastered, so dips must be the suggestion.
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('pullups', 'Pull Ups')]),
      ];
      final advice = _adviceFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(advice.first.title, 'Add a Dips progression');
    });

    test('a split that rarely revisits the movement is the split', () {
      // Three days of upper/lower is 1.5 upper days a week.
      final week = [
        _day(
            0, TrainingSessionType.upper, [_progression('dips', 'Bench Dips')]),
        _day(2, TrainingSessionType.lower, const []),
        _day(4, TrainingSessionType.upper, const []),
      ];
      final advice = _adviceFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.upperLower,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(advice.map((a) => a.title), [
        'Add another training day',
        'Change your split',
      ]);
      expect(
        advice.last.detail,
        'Choose a split that trains vertical push at least twice per week.',
      );
    });

    test('a full-body program is asked to train more often, not to re-split',
        () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
      ];
      final advice = _adviceFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 1,
        ),
      );

      expect(advice.single.title, 'Add another training day');
      expect(advice.single.detail,
          'Train your full-body program more frequently.');
    });

    test('empty applicable days reschedule the exercise already there', () {
      final week = [
        _day(0, TrainingSessionType.fullBody,
            [_progression('dips', 'Bench Dips')]),
        _day(2, TrainingSessionType.fullBody, const []),
        _day(4, TrainingSessionType.fullBody, const []),
      ];
      final advice = _adviceFor(
        'Vertical push',
        week: week,
        context: _context(
          programType: TrainingProgramType.fullBody,
          trainingDaysPerWeek: 3,
        ),
      );

      expect(advice.first.title, 'Add Bench Dips to another workout');
      expect(
        advice.first.detail,
        'Train vertical push on Wednesday to move towards 3 blocks a week.',
      );
      expect(advice.last.title, 'Add another vertical push exercise');
      // The split gives it three chances a week, so the split is not at fault.
      expect(
        advice.map((a) => a.title),
        isNot(contains('Change your split')),
      );
    });
  });

  group('weekly balance verdicts', () {
    test('weekly blocks read on the same scale for every movement', () {
      // 0 missing, 1 low, 2 good, 3 recommended, 4 and up high — checked on
      // a week wide enough that the split never decides the answer.
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
        BalanceVerdict.low,
        BalanceVerdict.good,
        BalanceVerdict.recommended,
        BalanceVerdict.high,
        BalanceVerdict.high,
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
      expect(entry.verdict, BalanceVerdict.good);
    });

    test('blocks stacked on one day still read on the block count', () {
      final week = [
        _day(0, TrainingSessionType.fullBody, [
          _progression('dips', 'Bench Dips'),
          _standalone('Barbell overhead press', 'dips_parallel_bar_dips'),
          _standalone(
              'Dumbbell shoulder press', 'handstand_pushups_pike_push_up'),
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
      expect(entry.verdict, BalanceVerdict.recommended);
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
      expect(squats.verdict, BalanceVerdict.recommended);
      expect(hinges.weeklyBlocks, 0);
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
        expect(entry.weeklyBlocks, 3, reason: label);
        expect(entry.verdict, BalanceVerdict.recommended, reason: label);
      }
    });
  });

  group('weekly balance status copy', () {
    test('each exposure level gets its own sentence', () {
      String copyFor(int blocks) {
        return balanceStatusCopy(
          _entryFor(
            'Vertical push',
            week: [
              for (var weekday = 0; weekday < 5; weekday++)
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
              trainingDaysPerWeek: 5,
            ),
          ),
        );
      }

      expect(
        copyFor(0),
        'You’re not currently training Vertical push. Add it to keep your '
        'program balanced.',
      );
      expect(
        copyFor(1),
        'You’re training Vertical push once per week. Increasing it to at '
        'least twice per week should support more consistent progress.',
      );
      expect(
        copyFor(2),
        'You’re training Vertical push twice per week. That’s enough to make '
        'solid progress, though training it 3 times per week may help you '
        'progress faster.',
      );
      expect(
        copyFor(3),
        'You’re training Vertical push 3 times per week — a strong frequency '
        'for progressing efficiently.',
      );
      expect(
        copyFor(4),
        'You’re training Vertical push frequently. This can work well, but '
        'make sure you’re recovering well and not overtraining.',
      );
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

List<BalanceAdvice> _adviceFor(
  String label, {
  required List<ProgramWeekDay> week,
  required BalanceProgramContext context,
}) {
  return balanceImprovementAdvice(
    entry: _entryFor(label, week: week, context: context),
    week: week,
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
