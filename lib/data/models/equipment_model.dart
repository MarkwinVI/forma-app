/// What the user trains with, asked once during setup and revisable from
/// the Program tab. Three presets: a full gym, nothing at all, or a specific
/// list of what they have ([EquipmentItem]).
enum SetupEquipment { fullGym, some, none }

extension SetupEquipmentX on SetupEquipment {
  String get dbValue => switch (this) {
        SetupEquipment.fullGym => 'gym',
        SetupEquipment.some => 'some',
        SetupEquipment.none => 'none',
      };

  /// The value as stored, or null for anything unknown. The retired
  /// "barbell and dumbbells" answer is not a preset any more: it reads as
  /// [SetupEquipment.some] with those two items — see
  /// [EquipmentAnswer.fromSetupAnswers].
  static SetupEquipment? fromDbValue(Object? value) => switch (value) {
        'gym' => SetupEquipment.fullGym,
        'some' || 'barbell' => SetupEquipment.some,
        'none' => SetupEquipment.none,
        _ => null,
      };
}

/// One piece of equipment the "Some equipment" answer can tick. Declared in
/// display order — the picker grid and every summary follow it.
enum EquipmentItem {
  pullUpBar,
  rings,
  parallettes,
  dipBars,
  bands,
  kettlebell,
  dumbbells,
  barbell,
}

extension EquipmentItemX on EquipmentItem {
  /// The id stored in `program_setup_v1.equipment_items`.
  String get id => switch (this) {
        EquipmentItem.pullUpBar => 'pull_up_bar',
        EquipmentItem.rings => 'rings',
        EquipmentItem.parallettes => 'parallettes',
        EquipmentItem.dipBars => 'dip_bars',
        EquipmentItem.bands => 'bands',
        EquipmentItem.kettlebell => 'kettlebell',
        EquipmentItem.dumbbells => 'dumbbells',
        EquipmentItem.barbell => 'barbell',
      };

  String get label => switch (this) {
        EquipmentItem.pullUpBar => 'Pull-up bar',
        EquipmentItem.rings => 'Rings',
        EquipmentItem.parallettes => 'Parallettes',
        EquipmentItem.dipBars => 'Dip bars',
        EquipmentItem.bands => 'Resistance bands',
        EquipmentItem.kettlebell => 'Kettlebell',
        EquipmentItem.dumbbells => 'Dumbbells',
        EquipmentItem.barbell => 'Barbell',
      };

  String get asset => 'assets/equipment/$id.png';

  static EquipmentItem? fromId(Object? id) {
    for (final item in EquipmentItem.values) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// The equipment answer as a whole: the preset, and for "Some equipment"
/// the items ticked. Immutable; the pickers build a new one per change.
class EquipmentAnswer {
  static const EquipmentAnswer fullGym =
      EquipmentAnswer(SetupEquipment.fullGym);
  static const EquipmentAnswer none = EquipmentAnswer(SetupEquipment.none);

  /// What the retired "Barbell and dumbbells" preset stood for.
  static const Set<EquipmentItem> legacyFreeWeights = {
    EquipmentItem.barbell,
    EquipmentItem.dumbbells,
  };

  final SetupEquipment kind;

  /// Only meaningful for [SetupEquipment.some]; empty for the presets.
  final Set<EquipmentItem> items;

  const EquipmentAnswer(this.kind, [this.items = const {}]);

  EquipmentAnswer.some(Set<EquipmentItem> items)
      : this(SetupEquipment.some, _ordered(items));

  bool get isSome => kind == SetupEquipment.some;

  /// Whether there is a bar to load: the loaded squat and hinge ladders,
  /// the weighted skill progressions and the gym accessories all hang off
  /// this one flag, stored as `has_gym` for every planner that reads it.
  bool get hasWeights => switch (kind) {
        SetupEquipment.fullGym => true,
        SetupEquipment.some => items.contains(EquipmentItem.barbell),
        SetupEquipment.none => false,
      };

  /// Most of Forma's pulling work hangs from a bar, so every answer short of
  /// one earns a reminder.
  bool get hasPullUpBar => switch (kind) {
        SetupEquipment.fullGym => true,
        SetupEquipment.some => items.contains(EquipmentItem.pullUpBar),
        SetupEquipment.none => false,
      };

  /// The item ids in display order.
  List<String> get itemIds => [for (final item in items) item.id];

  /// The keys this answer writes into `program_setup_v1`. `has_gym` travels
  /// with the answer itself so the planners never re-derive it.
  Map<String, dynamic> toSetupAnswers() => {
        'equipment': kind.dbValue,
        'equipment_items': itemIds,
        'has_gym': hasWeights,
      };

  /// Reads the answer out of `program_setup_v1`. Programs from before the
  /// question map their `has_gym` boolean onto the two presets; the retired
  /// "barbell" preset becomes "Some equipment" with a barbell and dumbbells.
  factory EquipmentAnswer.fromSetupAnswers(Map<String, dynamic> answers) {
    final raw = answers['equipment'];
    final kind = SetupEquipmentX.fromDbValue(raw);
    if (kind == null) {
      return (answers['has_gym'] as bool? ?? true) ? fullGym : none;
    }
    if (kind != SetupEquipment.some) return EquipmentAnswer(kind);

    final rawItems = answers['equipment_items'];
    final items = <EquipmentItem>{
      if (rawItems is List)
        for (final id in rawItems)
          if (EquipmentItemX.fromId(id) case final item?) item,
    };
    if (items.isEmpty && raw == 'barbell') {
      return EquipmentAnswer.some(legacyFreeWeights);
    }
    return EquipmentAnswer.some(items);
  }

  /// "Full gym", "No equipment", or the ticked items — the first three by
  /// name, the rest as a count.
  String get summary => switch (kind) {
        SetupEquipment.fullGym => 'Full gym',
        SetupEquipment.none => 'No equipment',
        SetupEquipment.some => summarizeItems(items),
      };

  /// "Full gym", "No equipment", or "3 items" — for a row with no room.
  String get shortLabel => switch (kind) {
        SetupEquipment.fullGym => 'Full gym',
        SetupEquipment.none => 'No equipment',
        SetupEquipment.some =>
          '${items.length} item${items.length == 1 ? '' : 's'}',
      };

  static String summarizeItems(Set<EquipmentItem> items) {
    if (items.isEmpty) return 'Pick everything you can train with';
    final names = [for (final item in _ordered(items)) item.label];
    final shown = names.take(3).join(', ');
    final more = names.length - 3;
    return more > 0 ? '$shown +$more more' : shown;
  }

  static Set<EquipmentItem> _ordered(Set<EquipmentItem> items) => {
        for (final item in EquipmentItem.values)
          if (items.contains(item)) item,
      };

  @override
  bool operator ==(Object other) =>
      other is EquipmentAnswer &&
      other.kind == kind &&
      other.items.length == items.length &&
      other.items.containsAll(items);

  @override
  int get hashCode => Object.hash(kind, Object.hashAllUnordered(items));

  @override
  String toString() => 'EquipmentAnswer($kind, $itemIds)';
}
