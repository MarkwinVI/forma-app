import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/weight_entry.dart';
import '../../data/models/equipment_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/weight_unit_service.dart';
import '../home/equipment_picker.dart';

/// Answers to the program questions that end onboarding.
class ProgramSetupResult {
  final int daysPerWeek;
  final TrainingProgramType split;

  /// What the user trains with: a preset, or the items they ticked.
  final EquipmentAnswer equipment;
  final double bodyweightKg;

  /// exercise id -> reps (or squat kg), null when the user left it blank.
  final Map<String, int?> startingStrength;

  const ProgramSetupResult({
    required this.daysPerWeek,
    required this.split,
    required this.equipment,
    required this.bodyweightKg,
    required this.startingStrength,
  });

  /// Whether loaded progressions (barbell squat, weighted skills) are on the
  /// table — a full gym, or a barbell among the items.
  bool get hasWeights => equipment.hasWeights;

  Map<String, dynamic> toMap() {
    return {
      'days_per_week': daysPerWeek,
      'split': split.dbValue,
      // 'equipment', 'equipment_items' and the derived 'has_gym' flag every
      // planner reads.
      ...equipment.toSetupAnswers(),
      'bodyweight_kg': bodyweightKg,
      'starting_strength': startingStrength,
    };
  }
}

// ── Question data ───────────────────────────────────────────

const _days = [2, 3, 4, 5, 6];

class _DayHint {
  final String tag;
  final String desc;

  const _DayHint(this.tag, this.desc);
}

/// What each weekly frequency means for the person picking it.
const _dayHints = {
  2: _DayHint(
    'Light',
    'Two focused sessions can cover the minimum.',
  ),
  3: _DayHint(
    'Recommended',
    'Ideal for most beginners and intermediates. Enough training frequency '
        'to progress while leaving plenty of time to recover.',
  ),
  4: _DayHint(
    'More training',
    'Four days is room to train everything evenly.',
  ),
  5: _DayHint(
    'High frequency',
    'Best suited to a split routine and people who want to train most days '
        'of the week.',
  ),
  6: _DayHint(
    'Advanced',
    'Best for experienced trainees using a split who can recover well from '
        'frequent training.',
  ),
};

/// The split is no longer a question: 2–3 days runs full body, 4–6 days a
/// push/pull rotation.
TrainingProgramType splitForDays(int days) =>
    days <= 3 ? TrainingProgramType.fullBody : TrainingProgramType.pushPull;

class _StrengthExercise {
  final String id;
  final String label;
  final IconData icon;

  /// Whether the answer is a load (kg/lbs) rather than a rep count.
  final bool isWeight;
  final int step;
  final int max;

  const _StrengthExercise({
    required this.id,
    required this.label,
    required this.icon,
    this.isWeight = false,
    this.step = 1,
    required this.max,
  });
}

const _repStrengthExercises = [
  _StrengthExercise(
    id: 'pushups',
    label: 'Push-ups',
    icon: Icons.trending_flat_rounded,
    max: 100,
  ),
  _StrengthExercise(
    id: 'pullups',
    label: 'Pull-ups',
    icon: Icons.arrow_upward_rounded,
    max: 50,
  ),
  _StrengthExercise(
    id: 'dips',
    label: 'Dips',
    icon: Icons.north_rounded,
    max: 50,
  ),
];

/// Asked with access to weights: the heaviest bar weight squatted for a
/// single rep, in the display unit the questions are running in. The planner
/// starts the weighted squat branch at 80% of it.
_StrengthExercise _barbellSquatFor(WeightUnit unit) => _StrengthExercise(
      id: 'squat',
      label: 'Barbell squat',
      icon: Icons.accessibility_new_rounded,
      isWeight: true,
      step: 5,
      max: unit == WeightUnit.lb ? 660 : 300,
    );

/// Asked without weights: bodyweight squats measured in reps instead.
const _bodyweightSquat = _StrengthExercise(
  id: 'squat_bw',
  label: 'Bodyweight squats',
  icon: Icons.accessibility_new_rounded,
  max: 100,
);

// ── Questions ───────────────────────────────────────────────

/// The program questions at the end of onboarding, in the order they come.
enum ProgramSetupQuestion { schedule, equipment, bodyweight, strength }

/// The answers to the program questions, and the rules for moving between
/// them. Onboarding owns the flow — the header, the button, the steps — and
/// asks this what each question needs; [ProgramSetupStep] draws one.
class ProgramSetupController extends ChangeNotifier {
  /// Schedule and equipment start unanswered — the button holds until a
  /// pick.
  int? _days;
  EquipmentAnswer? _equipment;

  /// The two-chairs tip is up: shown between the equipment question and the
  /// bodyweight question when the pick has nothing to dip on.
  bool _dipTip = false;

  /// Bodyweight is kept in the unit being displayed; only [result] converts
  /// to canonical kilograms.
  WeightUnit _unit = WeightUnitService.unit;
  double _bw = 0;
  String _bwEdit = '';
  bool _bwEditing = false;

  /// Whether the user has typed a bodyweight of their own. The question
  /// opens with the keypad up and a dimmed 0 in the field, and the button
  /// holds until a real number is in it.
  bool _bwEntered = false;

  /// The "Minimum 30 kg" note is up: Continue was pressed on a number under
  /// the floor. It never shows while the number is still being typed — the
  /// next key takes it down again.
  bool _bwMinimumNoted = false;

  /// Starting-strength answers, null until the user gives one. The squat
  /// load lives in the display unit while the questions run.
  final Map<String, int?> _strength = {
    'pushups': null,
    'pullups': null,
    'dips': null,
    'squat': null,
    'squat_bw': null,
  };

  bool get showingDipTip => _dipTip;

  double get _bwMin => _unit == WeightUnit.lb ? 66 : 30;
  double get _bwMax => _unit == WeightUnit.lb ? 550 : 250;

  /// Whether [question] has an answer the flow can move on from. The dip
  /// tip is read, not answered, so it never holds.
  bool answered(ProgramSetupQuestion question) {
    if (_dipTip) return true;
    return switch (question) {
      ProgramSetupQuestion.schedule => _days != null,
      ProgramSetupQuestion.equipment => _equipmentAnswered,
      // Any number of the user's own lets Continue be pressed; one under
      // the floor is turned back there, with the reason (see continueFrom).
      ProgramSetupQuestion.bodyweight => _bwEntered,
      ProgramSetupQuestion.strength => true,
    };
  }

  /// What the button says while [question] holds.
  String holdLabel(ProgramSetupQuestion question) =>
      question == ProgramSetupQuestion.bodyweight
          ? 'Enter your bodyweight to continue'
          : 'Pick one to continue';

  /// The heading over [question] — the tip's own while it is up.
  ({String title, String sub}) headFor(ProgramSetupQuestion question) {
    if (_dipTip) {
      return (
        title: 'No dip bars? Two chairs will do.',
        sub: 'Set two sturdy chairs shoulder-width apart with the backs '
            'facing out, and dip with a hand on each. If they feel tippy, '
            'weigh the seats down with something heavy.',
      );
    }
    return switch (question) {
      ProgramSetupQuestion.schedule => (
          title: 'Your training schedule',
          sub: 'Choose how many days a week you want to train.',
        ),
      ProgramSetupQuestion.equipment => (
          title: 'Your equipment',
          sub: 'What do you have access to?',
        ),
      ProgramSetupQuestion.bodyweight => (
          title: 'Your bodyweight',
          sub: 'Skills like weighted pull-ups use your bodyweight to set the '
              'weight. A close guess is fine. You can update it anytime from '
              'your profile.',
        ),
      ProgramSetupQuestion.strength => (
          title: 'Where are you starting?',
          sub: 'What’s your best for each exercise? Enter your max reps or '
              'one-rep max. A rough estimate is fine.',
        ),
    };
  }

  /// [question] has come up. The bodyweight question opens ready to type
  /// into.
  void arrive(ProgramSetupQuestion question) {
    if (question != ProgramSetupQuestion.bodyweight) return;
    _openBodyweightEntry();
    notifyListeners();
  }

  /// [question] is being left, in either direction. Whatever was typed into
  /// the bodyweight is folded in and the keypad closes.
  void depart(ProgramSetupQuestion question) {
    if (question == ProgramSetupQuestion.bodyweight) _commitBodyweight();
  }

  /// Continue on [question]. True when it was handled in place — the dip
  /// tip coming up, or a bodyweight under the floor being turned back —
  /// and the flow should stay where it is.
  bool continueFrom(ProgramSetupQuestion question) {
    if (_dipTip) {
      _dipTip = false;
      return false;
    }
    if (question == ProgramSetupQuestion.bodyweight && _bw < _bwMin) {
      _bwMinimumNoted = true;
      notifyListeners();
      return true;
    }
    if (question == ProgramSetupQuestion.equipment &&
        !(_equipment?.hasDipBars ?? true)) {
      _dipTip = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Back on [question]. True when it was handled in place — closing the
  /// dip tip, which returns to the pick.
  bool backFrom(ProgramSetupQuestion question) {
    if (!_dipTip) return false;
    _dipTip = false;
    notifyListeners();
    return true;
  }

  /// The answers, in canonical units.
  ProgramSetupResult result() {
    final equipment = _equipment ?? EquipmentAnswer.fullGym;
    final bodyweightKg = _clampBw(_bw) *
        (_unit == WeightUnit.lb ? WeightUnitService.kgPerLb : 1);
    final days = _days ?? 3;
    return ProgramSetupResult(
      daysPerWeek: days,
      split: splitForDays(days),
      equipment: equipment,
      bodyweightKg: bodyweightKg,
      // Only the leg questions matching the equipment answer are recorded,
      // and the loads are converted back to canonical kilograms.
      startingStrength: {
        'pushups': _strength['pushups'],
        'pullups': _strength['pullups'],
        'dips': _strength['dips'],
        // The hinge is not asked about: with weights it opens on the
        // ladder's first loaded rung, without them on the tree's first step.
        if (equipment.hasWeights)
          'squat': _strengthKg('squat')
        else
          'squat_bw': _strength['squat_bw'],
      },
    );
  }

  void _setDays(int days) {
    _days = days;
    notifyListeners();
  }

  void _setEquipment(EquipmentAnswer? equipment) {
    _equipment = equipment;
    notifyListeners();
  }

  void _strengthChanged() => notifyListeners();

  /// A preset, or "Some equipment" with at least one item ticked. The list
  /// is only empty while its sheet is up — closing it empty clears the pick.
  bool get _equipmentAnswered {
    final equipment = _equipment;
    return equipment != null &&
        (!equipment.isSome || equipment.items.isNotEmpty);
  }

  /// The unit toggle is the app-wide choice: picking lbs here flips every
  /// weight the app shows from now on.
  void _setUnit(WeightUnit unit) {
    if (unit == _unit) return;
    // Whatever is in the field right now travels with the unit — a number
    // half typed included, so flipping mid-entry converts it rather than
    // rounding it up to the floor first.
    final shown = double.tryParse(_bwEdit) ?? _bw;
    final kg =
        _unit == WeightUnit.lb ? shown * WeightUnitService.kgPerLb : shown;
    // The barbell answer is a load, so it travels with the unit — rounded
    // to something loadable rather than a raw conversion.
    for (final barbell in [_barbellSquatFor(unit)]) {
      final value = _strength[barbell.id];
      // A 0 answer stays 0 — the loadable floor below would turn it into a
      // phantom 5 on a unit flip.
      if (value == null || value == 0) continue;
      final converted = unit == WeightUnit.lb
          ? value / WeightUnitService.kgPerLb
          : value * WeightUnitService.kgPerLb;
      _strength[barbell.id] =
          ((converted / 5).round() * 5).clamp(5, barbell.max).toInt();
    }
    _unit = unit;
    final converted = unit == WeightUnit.lb
        ? (kg / WeightUnitService.kgPerLb).roundToDouble()
        : kg.roundToDouble();
    // The placeholder stays 0 in either unit; a typed number is only
    // capped, and the button holds until it clears the floor.
    _bw = _bwEntered ? converted.clamp(0, _bwMax).toDouble() : 0;
    _bwEdit = '';
    _bwMinimumNoted = false;
    // Flipping the unit converts the number; it does not close the entry.
    if (_bwEditing) _openBodyweightEntry();
    WeightUnitService.set(unit);
    notifyListeners();
  }

  double _clampBw(double value) => value.clamp(_bwMin, _bwMax);

  void _commitBodyweight() {
    if (!_bwEditing && _bwEdit.isEmpty) return;
    final parsed = double.tryParse(_bwEdit);
    // Capped, never raised: a number under the floor stays what was typed,
    // and Continue is what says so.
    if (parsed != null && parsed > 0) {
      _bw = parsed.clamp(0, _bwMax).toDouble();
    }
    _bwEdit = '';
    _bwEditing = false;
    _bwMinimumNoted = false;
    notifyListeners();
  }

  void _pressBwKey(String key) {
    _bwEdit = weightEntryPress(_bwEdit, key);
    _bwMinimumNoted = false;
    final parsed = double.tryParse(_bwEdit);
    // An emptied field falls back to the placeholder, 0.
    _bw = parsed == null ? 0 : parsed.clamp(0, _bwMax).toDouble();
    _bwEntered = parsed != null && parsed > 0;
    notifyListeners();
  }

  void _tapBwValue() {
    _bwEditing = true;
    _bwEdit = '';
    notifyListeners();
  }

  /// The field shows what the user has already given — or the placeholder,
  /// dimmed, while they have given nothing.
  void _openBodyweightEntry() {
    _bwEditing = true;
    _bwEdit = _bwEntered ? _bwText : '';
  }

  String get _bwText => _bw == _bw.roundToDouble()
      ? _bw.round().toString()
      : _bw.toStringAsFixed(1);

  /// A barbell answer in canonical kilograms, whatever unit it was typed in.
  int? _strengthKg(String id) {
    final value = _strength[id];
    if (value == null) return null;
    return (_unit == WeightUnit.lb
            ? value * WeightUnitService.kgPerLb
            : value.toDouble())
        .round();
  }
}

/// The body of one program question — everything under its heading, which
/// the host draws so the questions read like the rest of onboarding.
///
/// It follows the controller only while [isCurrent] says it is the page
/// being shown. A page on its way out — still on screen for the length of
/// the host's transition — keeps what it last drew, so it leaves as itself
/// rather than redrawing into whatever the answers say next.
class ProgramSetupStep extends StatefulWidget {
  final ProgramSetupController controller;
  final ProgramSetupQuestion question;

  /// Whether to draw the dip-bars tip in the question's place. Decided by
  /// the host when it builds the page, and fixed for that page from then on.
  final bool showDipTip;

  /// Whether this page is still the one being shown.
  final ValueGetter<bool> isCurrent;

  const ProgramSetupStep({
    super.key,
    required this.controller,
    required this.question,
    required this.showDipTip,
    required this.isCurrent,
  });

  @override
  State<ProgramSetupStep> createState() => _ProgramSetupStepState();
}

class _ProgramSetupStepState extends State<ProgramSetupStep> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant ProgramSetupStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted && widget.isCurrent()) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (widget.showDipTip) return const _DipBarsTip();
    return switch (widget.question) {
      ProgramSetupQuestion.schedule => _ScheduleStep(
          days: c._days,
          onChanged: c._setDays,
        ),
      ProgramSetupQuestion.equipment => _EquipmentStep(
          equipment: c._equipment,
          onChanged: c._setEquipment,
        ),
      ProgramSetupQuestion.bodyweight => _WeightStep(
          bw: c._bw,
          edit: c._bwEdit,
          editing: c._bwEditing,
          unit: c._unit,
          min: c._bwMin,
          showMinimum: c._bwMinimumNoted,
          onUnitChanged: c._setUnit,
          onTapValue: c._tapBwValue,
          onKey: c._pressBwKey,
        ),
      ProgramSetupQuestion.strength => _StrengthStep(
          strength: c._strength,
          hasWeights: c._equipment?.hasWeights ?? true,
          unit: c._unit,
          onChanged: c._strengthChanged,
        ),
    };
  }
}

class _InfoNote extends StatelessWidget {
  final InlineSpan message;

  const _InfoNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text.rich(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _RadioRow({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.accentPrimary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: selected
                      ? AppColors.accentPrimary
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: schedule ────────────────────────────────────────

class _ScheduleStep extends StatelessWidget {
  final int? days;
  final ValueChanged<int> onChanged;

  const _ScheduleStep({
    required this.days,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hint = days == null ? null : _dayHints[days];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 0; index < _days.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _DayCell(
                  day: _days[index],
                  selected: _days[index] == days,
                  onTap: () => onChanged(_days[index]),
                ),
              ),
            ],
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 16),
          _InfoNote(
            message: TextSpan(
              children: [
                TextSpan(
                  text: '$days days — ${hint.tag}. ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: days == 3 ? AppColors.green : AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: hint.desc),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool selected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'days',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: equipment ───────────────────────────────────────

/// Three presets, each a bare name. "Some equipment" slides up the
/// tile-grid sheet; Done writes a summary of the ticks back onto its card, and closing the sheet
/// with nothing ticked clears the radio again.
class _EquipmentStep extends StatelessWidget {
  final EquipmentAnswer? equipment;
  final ValueChanged<EquipmentAnswer?> onChanged;

  const _EquipmentStep({
    required this.equipment,
    required this.onChanged,
  });

  Future<void> _pickItems(BuildContext context) async {
    final current = equipment;
    var items = current != null && current.isSome
        ? current.items
        : const <EquipmentItem>{};
    onChanged(EquipmentAnswer.some(items));
    await EquipmentPickerSheet.show(
      context,
      initial: items,
      onChanged: (picked) {
        items = picked;
        onChanged(EquipmentAnswer.some(picked));
      },
    );
    if (items.isEmpty) onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final equipment = this.equipment;
    final some = equipment != null && equipment.isSome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RadioRow(
          selected: equipment?.kind == SetupEquipment.fullGym,
          label: 'Full gym',
          onTap: () => onChanged(EquipmentAnswer.fullGym),
        ),
        const SizedBox(height: 10),
        _RadioRow(
          selected: equipment?.kind == SetupEquipment.none,
          label: 'No equipment',
          onTap: () => onChanged(EquipmentAnswer.none),
        ),
        const SizedBox(height: 10),
        SomeEquipmentRow(
          selected: some,
          items: some ? equipment.items : const {},
          showHints: false,
          onTap: () => _pickItems(context),
        ),
        if (equipmentNeedsBarNote(equipment)) ...[
          const SizedBox(height: 14),
          const EquipmentBarNote(),
        ],
      ],
    );
  }
}

/// Shown after the equipment question when nothing in the pick can be
/// dipped on: the dips tree still runs, on two chairs. It holds the
/// equipment question's place; Got it moves on, back returns to the pick.
class _DipBarsTip extends StatelessWidget {
  const _DipBarsTip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Image.asset(
            'assets/equipment/chairs.png',
            semanticLabel:
                'Two chairs placed back-rests out, shoulder-width apart',
          ),
        ),
      ),
    );
  }
}

// ── Step 3: bodyweight — tap the number, type on a keypad ───

class _WeightStep extends StatelessWidget {
  final double bw;
  final String edit;
  final bool editing;
  final WeightUnit unit;
  final double min;

  /// Whether to say what the minimum is — only after Continue was pressed
  /// on a number under it, never while the number is being typed.
  final bool showMinimum;
  final ValueChanged<WeightUnit> onUnitChanged;
  final VoidCallback onTapValue;
  final ValueChanged<String> onKey;

  const _WeightStep({
    required this.bw,
    required this.edit,
    required this.editing,
    required this.unit,
    required this.min,
    required this.showMinimum,
    required this.onUnitChanged,
    required this.onTapValue,
    required this.onKey,
  });

  String get _valueText {
    if (edit.isNotEmpty) return edit;
    return bw == bw.roundToDouble()
        ? bw.round().toString()
        : bw.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: WeightUnitToggle(unit: unit, onChanged: onUnitChanged)),
        const SizedBox(height: 22),
        WeightValueDisplay(
          text: _valueText,
          dim: editing && edit.isEmpty,
          unit: unit,
          editing: editing,
          onTap: onTapValue,
        ),
        const SizedBox(height: 4),
        if (!editing)
          const Center(
            child: Text(
              'Tap the number to change it',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          )
        else if (showMinimum)
          Center(
            child: Text(
              'Minimum ${min.round()} ${unit.suffix}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.amber),
            ),
          ),
        if (editing) ...[
          const SizedBox(height: 16),
          WeightKeypad(onKey: onKey),
        ],
      ],
    );
  }
}

// ── Step 4: starting strength ───────────────────────────────

class _StrengthStep extends StatelessWidget {
  final Map<String, int?> strength;
  final bool hasWeights;
  final WeightUnit unit;
  final VoidCallback onChanged;

  const _StrengthStep({
    required this.strength,
    required this.hasWeights,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = [
      ..._repStrengthExercises,
      if (hasWeights) _barbellSquatFor(unit) else _bodyweightSquat,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < exercises.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _StrengthCard(
            exercise: exercises[index],
            value: strength[exercises[index].id],
            unit: unit,
            onChanged: (value) {
              strength[exercises[index].id] = value;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final _StrengthExercise exercise;
  final int? value;
  final WeightUnit unit;
  final ValueChanged<int?> onChanged;

  const _StrengthCard({
    required this.exercise,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // The stepper's discs sit in 44pt hit boxes (6pt around a 32pt disc),
      // so the card gives up that 6 on the right and 2 top and bottom to
      // keep the discs, and the card's height, where they were.
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconTile(icon: exercise.icon, tint: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.16,
                  ),
                ),
              ],
            ),
          ),
          _StrengthStepper(
            label: exercise.label,
            value: value,
            step: exercise.step,
            max: exercise.max,
            unitSuffix: exercise.isWeight ? unit.suffix : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Starts at 0 — "+" steps up from there, a rep or five of the weight
/// unit at a time, and "−" steps back down to 0. The number itself opens
/// direct entry, and holding a button keeps stepping.
///
/// A null [value] is an answer nobody touched. It reads as 0 here and
/// places the user exactly as a 0 does, but stays null in what is saved,
/// so "left alone" and "can't do one yet" remain two different answers.
class _StrengthStepper extends StatelessWidget {
  final String label;
  final int? value;
  final int step;
  final int max;
  final String? unitSuffix;
  final ValueChanged<int?> onChanged;

  const _StrengthStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.max,
    required this.unitSuffix,
    required this.onChanged,
  });

  Future<void> _openEntry(BuildContext context) async {
    final entered = await showModalBottomSheet<int?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StrengthEntrySheet(
        label: label,
        initial: value,
        max: max,
        unitSuffix: unitSuffix ?? 'reps',
      ),
    );
    if (entered == null) return;
    onChanged(entered);
  }

  @override
  Widget build(BuildContext context) {
    final shown = value ?? 0;
    final unitWord = unitSuffix ?? 'reps';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          semanticLabel: 'Decrease $label',
          enabled: shown > 0,
          onTap: () => onChanged((shown - step).clamp(0, max)),
        ),
        Pressable(
          semanticLabel: '$label, $shown $unitWord. Tap to enter a value',
          onTap: () => _openEntry(context),
          child: Container(
            constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
            alignment: Alignment.center,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$shown',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.42,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unitSuffix != null)
                    TextSpan(
                      text: ' $unitSuffix',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          semanticLabel: 'Increase $label',
          enabled: shown < max,
          onTap: () => onChanged((shown + step).clamp(0, max)),
        ),
      ],
    );
  }
}

/// A 32pt disc inside a 44pt hit area. Tap steps once; press and hold keeps
/// stepping, slowly at first and then faster, until the finger lifts or the
/// button runs out of range.
class _StepperButton extends StatefulWidget {
  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  Timer? _repeat;
  int _ticks = 0;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _startRepeat() {
    _repeat?.cancel();
    _ticks = 0;
    widget.onTap();
    _repeat = Timer.periodic(const Duration(milliseconds: 110), (_) {
      if (!widget.enabled) {
        _stopRepeat();
        return;
      }
      _ticks++;
      // Every other tick for the first second, then every tick.
      if (_ticks < 9 && _ticks.isOdd) return;
      widget.onTap();
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    // One node: the Pressable supplies the button trait and name, the
    // long-press repeat folds into it instead of sitting beside it.
    return MergeSemantics(
      child: GestureDetector(
        onLongPressStart: enabled ? (_) => _startRepeat() : null,
        onLongPressEnd: enabled ? (_) => _stopRepeat() : null,
        onLongPressCancel: enabled ? _stopRepeat : null,
        child: Pressable(
          onTap: enabled ? widget.onTap : null,
          semanticLabel: widget.semanticLabel,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Opacity(
              opacity: enabled ? 1 : 0.35,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child:
                    Icon(widget.icon, size: 16, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Direct entry for one starting-strength value: the number, big and
/// tappable-looking, over the bare keypad, and Done. Resolves the typed
/// integer, or null when dismissed without a change.
///
/// Public for its tests.
class StrengthEntrySheet extends StatefulWidget {
  final String label;
  final int? initial;
  final int max;
  final String unitSuffix;

  const StrengthEntrySheet({
    super.key,
    required this.label,
    required this.initial,
    required this.max,
    required this.unitSuffix,
  });

  @override
  State<StrengthEntrySheet> createState() => _StrengthEntrySheetState();
}

class _StrengthEntrySheetState extends State<StrengthEntrySheet> {
  String _edit = '';

  int? get _typed => int.tryParse(_edit);

  void _press(String key) {
    setState(() {
      if (key == 'del') {
        if (_edit.isNotEmpty) _edit = _edit.substring(0, _edit.length - 1);
        return;
      }
      // Whole numbers only — the decimal key is a no-op here.
      if (key == '.') return;
      if (_edit.length >= 3) return;
      _edit = _edit == '0' ? key : '$_edit$key';
    });
  }

  void _done() {
    final typed = _typed;
    if (typed == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(typed.clamp(0, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.initial == null ? '0' : '${widget.initial}';
    final showing = _edit.isEmpty ? placeholder : _edit;
    final overMax = (_typed ?? 0) > widget.max;

    return SheetShell(
      title: widget.label,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  showing,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1.7,
                    color: _edit.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.unitSuffix,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Empty unless the number runs over the top — the line keeps
            // its height either way, so the keypad never shifts under a
            // thumb.
            Center(
              child: Text(
                overMax ? 'Maximum ${widget.max} ${widget.unitSuffix}' : '',
                style: const TextStyle(fontSize: 12.5, color: AppColors.amber),
              ),
            ),
            const SizedBox(height: 16),
            WeightKeypad(onKey: _press),
            const SizedBox(height: 12),
            PillButton(
              label: 'Done',
              radius: 14,
              onTap: _done,
            ),
          ],
        ),
      ),
    );
  }
}
