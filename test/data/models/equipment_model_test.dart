import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/equipment_model.dart';

void main() {
  group('EquipmentAnswer.fromSetupAnswers', () {
    test('reads the presets', () {
      expect(
        EquipmentAnswer.fromSetupAnswers({'equipment': 'gym'}),
        EquipmentAnswer.fullGym,
      );
      expect(
        EquipmentAnswer.fromSetupAnswers({'equipment': 'none'}),
        EquipmentAnswer.none,
      );
    });

    test('reads the ticked items in display order, dropping unknown ids', () {
      final answer = EquipmentAnswer.fromSetupAnswers({
        'equipment': 'some',
        'equipment_items': ['barbell', 'rings', 'treadmill'],
      });
      expect(answer.kind, SetupEquipment.some);
      expect(answer.itemIds, ['rings', 'barbell']);
      expect(answer.summary, 'Rings, Barbell');
      expect(answer.shortLabel, '2 items');
    });

    test('the retired barbell preset becomes barbell and dumbbells', () {
      final answer = EquipmentAnswer.fromSetupAnswers({
        'equipment': 'barbell',
        'has_gym': true,
      });
      expect(answer.kind, SetupEquipment.some);
      expect(answer.items, {EquipmentItem.barbell, EquipmentItem.dumbbells});
      expect(answer.hasWeights, isTrue);
      expect(answer.hasPullUpBar, isFalse);
    });

    test('a program from before the question follows its has_gym flag', () {
      expect(
        EquipmentAnswer.fromSetupAnswers({'has_gym': false}),
        EquipmentAnswer.none,
      );
      expect(EquipmentAnswer.fromSetupAnswers({}), EquipmentAnswer.fullGym);
    });
  });

  group('EquipmentAnswer.toSetupAnswers', () {
    test('a full gym and a barbell both mean a bar to load', () {
      expect(EquipmentAnswer.fullGym.toSetupAnswers(), {
        'equipment': 'gym',
        'equipment_items': <String>[],
        'has_gym': true,
      });
      expect(
        EquipmentAnswer.some({EquipmentItem.barbell, EquipmentItem.pullUpBar})
            .toSetupAnswers(),
        {
          'equipment': 'some',
          'equipment_items': ['pull_up_bar', 'barbell'],
          'has_gym': true,
        },
      );
    });

    test('items without a barbell do not', () {
      expect(
        EquipmentAnswer.some(
                {EquipmentItem.dumbbells, EquipmentItem.kettlebell})
            .toSetupAnswers()['has_gym'],
        isFalse,
      );
      expect(EquipmentAnswer.none.toSetupAnswers()['has_gym'], isFalse);
    });
  });

  test('a full gym or a vest can add weight to a bodyweight movement', () {
    expect(EquipmentAnswer.fullGym.canAddWeight, isTrue);
    expect(EquipmentAnswer.none.canAddWeight, isFalse);
    expect(
      EquipmentAnswer.some({EquipmentItem.weightVest}).canAddWeight,
      isTrue,
    );
    expect(
      EquipmentAnswer.some({EquipmentItem.barbell, EquipmentItem.dumbbells})
          .canAddWeight,
      isFalse,
    );
    expect(
      EquipmentAnswer.fromSetupAnswers({
        'equipment': 'some',
        'equipment_items': ['weight_vest'],
      }).itemIds,
      ['weight_vest'],
    );
  });

  test('dip bars come with a gym or the tile, nothing else', () {
    expect(EquipmentAnswer.fullGym.hasDipBars, isTrue);
    expect(EquipmentAnswer.none.hasDipBars, isFalse);
    expect(EquipmentAnswer.some({EquipmentItem.dipBars}).hasDipBars, isTrue);
    expect(
      EquipmentAnswer.some({EquipmentItem.rings, EquipmentItem.parallettes})
          .hasDipBars,
      isFalse,
    );
  });

  group('canDo', () {
    const ringsOrBar =
        EquipmentNeed({EquipmentItem.pullUpBar, EquipmentItem.rings});
    const vest = EquipmentNeed({EquipmentItem.weightVest});

    test('a full gym does everything, including what only a gym has', () {
      expect(EquipmentAnswer.fullGym.canDo([ringsOrBar, vest]), isTrue);
      expect(EquipmentAnswer.fullGym.canDo([EquipmentNeed.gym]), isTrue);
    });

    test('no equipment does only bodyweight', () {
      expect(EquipmentAnswer.none.canDo(const []), isTrue);
      expect(EquipmentAnswer.none.canDo([ringsOrBar]), isFalse);
    });

    test('a list meets a need with any one of its items, and every need', () {
      final rings = EquipmentAnswer.some({EquipmentItem.rings});
      expect(rings.canDo([ringsOrBar]), isTrue);
      expect(rings.canDo([ringsOrBar, vest]), isFalse);
      expect(
        EquipmentAnswer.some({EquipmentItem.rings, EquipmentItem.weightVest})
            .canDo([ringsOrBar, vest]),
        isTrue,
      );
      expect(rings.canDo([EquipmentNeed.gym]), isFalse);
    });
  });

  test('summary names three items and counts the rest', () {
    expect(
      EquipmentAnswer.summarizeItems({
        EquipmentItem.barbell,
        EquipmentItem.rings,
        EquipmentItem.bands,
        EquipmentItem.pullUpBar,
      }),
      'Pull-up bar, Rings, Resistance bands +1 more',
    );
    expect(
      EquipmentAnswer.summarizeItems({}),
      'Pick everything you can train with',
    );
  });

  test('equality ignores item order', () {
    expect(
      EquipmentAnswer.some({EquipmentItem.rings, EquipmentItem.barbell}),
      EquipmentAnswer.some({EquipmentItem.barbell, EquipmentItem.rings}),
    );
    expect(
      EquipmentAnswer.some({EquipmentItem.rings}),
      isNot(EquipmentAnswer.some({EquipmentItem.barbell})),
    );
    expect(EquipmentAnswer.fullGym, isNot(EquipmentAnswer.none));
  });
}
