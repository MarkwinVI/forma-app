import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/weight_entry.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/weight_unit_service.dart';

/// What the user trains with, asked once during setup. Both weighted answers
/// — a full gym or just a barbell and dumbbells — count as access to weights
/// wherever the skill trees choose between a loaded and a bodyweight lift.
enum SetupEquipment { fullGym, freeWeights, none }

extension SetupEquipmentX on SetupEquipment {
  String get dbValue => switch (this) {
        SetupEquipment.fullGym => 'gym',
        SetupEquipment.freeWeights => 'barbell',
        SetupEquipment.none => 'none',
      };

  bool get hasWeights => this != SetupEquipment.none;
}

/// Answers collected by the "Build your program" wizard.
class ProgramSetupResult {
  final int daysPerWeek;
  final TrainingProgramType split;
  final SetupEquipment equipment;
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
  /// table — true for both the full-gym and free-weights answers.
  bool get hasWeights => equipment.hasWeights;

  Map<String, dynamic> toMap() {
    return {
      'days_per_week': daysPerWeek,
      'split': split.dbValue,
      'equipment': equipment.dbValue,
      // The pre-equipment readers of this flag all mean "can load a bar",
      // so free weights count the same as a full gym.
      'has_gym': hasWeights,
      'bodyweight_kg': bodyweightKg,
      'starting_strength': startingStrength,
    };
  }
}

// ── Wizard data ─────────────────────────────────────────────

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
  final String? hint;
  final IconData icon;

  /// Whether the answer is a load (kg/lbs) rather than a rep count.
  final bool isWeight;
  final int step;
  final int def;
  final int max;

  const _StrengthExercise({
    required this.id,
    required this.label,
    this.hint,
    required this.icon,
    this.isWeight = false,
    this.step = 1,
    required this.def,
    required this.max,
  });
}

const _repStrengthExercises = [
  _StrengthExercise(
    id: 'pushups',
    label: 'Push-ups',
    icon: Icons.trending_flat_rounded,
    def: 10,
    max: 100,
  ),
  _StrengthExercise(
    id: 'pullups',
    label: 'Pull-ups',
    icon: Icons.arrow_upward_rounded,
    def: 3,
    max: 50,
  ),
  _StrengthExercise(
    id: 'dips',
    label: 'Dips',
    icon: Icons.north_rounded,
    def: 5,
    max: 50,
  ),
];

/// Asked with access to weights: the heaviest bar weight squatted for a
/// single rep, in the display unit the wizard is running in. The planner
/// starts the weighted squat branch at 80% of it.
_StrengthExercise _barbellSquatFor(WeightUnit unit) => _StrengthExercise(
      id: 'squat',
      label: 'Barbell squat',
      hint: 'Best single rep — bar weight',
      icon: Icons.accessibility_new_rounded,
      isWeight: true,
      step: 5,
      def: unit == WeightUnit.lb ? 90 : 40,
      max: unit == WeightUnit.lb ? 660 : 300,
    );

/// Also asked with access to weights: the heaviest single-rep Romanian
/// deadlift, placing the start of the hinge tree's weighted ladder the same
/// way — at 80% of it.
_StrengthExercise _romanianDeadliftFor(WeightUnit unit) => _StrengthExercise(
      id: 'rdl',
      label: 'Romanian deadlift',
      hint: 'Best single rep — bar weight',
      icon: Icons.fitness_center_rounded,
      isWeight: true,
      step: 5,
      def: unit == WeightUnit.lb ? 90 : 40,
      max: unit == WeightUnit.lb ? 660 : 300,
    );

/// Asked without weights: bodyweight squats measured in reps instead.
const _bodyweightSquat = _StrengthExercise(
  id: 'squat_bw',
  label: 'Bodyweight squats',
  icon: Icons.accessibility_new_rounded,
  def: 15,
  max: 100,
);

// ── Wizard ──────────────────────────────────────────────────

/// Four-step "Build your program" wizard: schedule, equipment, bodyweight
/// and starting strength. The split comes from the schedule ([splitForDays])
/// rather than being asked. Calls [onComplete] with the answers, then shows
/// the "program ready" confirmation.
class ProgramSetupView extends StatefulWidget {
  final Future<void> Function(ProgramSetupResult result) onComplete;

  const ProgramSetupView({
    super.key,
    required this.onComplete,
  });

  @override
  State<ProgramSetupView> createState() => _ProgramSetupViewState();
}

class _ProgramSetupViewState extends State<ProgramSetupView> {
  static const _stepCount = 4;

  int _step = 0;

  /// Schedule and equipment start unanswered — the CTA holds until a pick.
  int? _days;
  SetupEquipment? _equipment;

  /// Bodyweight is kept in the unit being displayed; only the finish
  /// converts to canonical kilograms.
  WeightUnit _unit = WeightUnitService.unit;
  late double _bw = _unit == WeightUnit.lb ? 165 : 75;
  String _bwEdit = '';
  bool _bwEditing = false;

  /// Starting-strength answers, unset until the user adds a number. The
  /// squat and RDL loads live in the display unit while the wizard runs.
  final Map<String, int?> _strength = {
    'pushups': null,
    'pullups': null,
    'dips': null,
    'squat': null,
    'rdl': null,
    'squat_bw': null,
  };

  bool _saving = false;
  bool _ready = false;

  double get _bwMin => _unit == WeightUnit.lb ? 66 : 30;
  double get _bwMax => _unit == WeightUnit.lb ? 550 : 250;

  TrainingProgramType get _split => splitForDays(_days ?? 3);

  bool get _isLastStep => _step == _stepCount - 1;

  bool get _ctaDisabled =>
      (_step == 0 && _days == null) || (_step == 1 && _equipment == null);

  /// The wizard's unit toggle is the app-wide choice: picking lbs here flips
  /// every weight the app shows from now on.
  void _setUnit(WeightUnit unit) {
    if (unit == _unit) return;
    _commitBodyweight();
    setState(() {
      final kg = _unit == WeightUnit.lb ? _bw * WeightUnitService.kgPerLb : _bw;
      // The barbell answers are loads, so they travel with the unit —
      // rounded to something loadable rather than a raw conversion.
      for (final barbell in [_barbellSquatFor(unit), _romanianDeadliftFor(unit)]) {
        final value = _strength[barbell.id];
        if (value == null) continue;
        final converted = unit == WeightUnit.lb
            ? value / WeightUnitService.kgPerLb
            : value * WeightUnitService.kgPerLb;
        _strength[barbell.id] =
            ((converted / 5).round() * 5).clamp(5, barbell.max).toInt();
      }
      _unit = unit;
      _bw = _clampBw(
        unit == WeightUnit.lb
            ? (kg / WeightUnitService.kgPerLb).roundToDouble()
            : kg.roundToDouble(),
      );
      _bwEdit = '';
    });
    WeightUnitService.set(unit);
  }

  double _clampBw(double value) => value.clamp(_bwMin, _bwMax);

  /// Folds whatever was typed into the bodyweight value and closes the
  /// keypad. Runs when the step is left in any direction.
  void _commitBodyweight() {
    if (!_bwEditing && _bwEdit.isEmpty) return;
    final parsed = double.tryParse(_bwEdit);
    setState(() {
      if (parsed != null && parsed > 0) _bw = _clampBw(parsed);
      _bwEdit = '';
      _bwEditing = false;
    });
  }

  void _pressBwKey(String key) {
    setState(() {
      _bwEdit = weightEntryPress(_bwEdit, key);
      final parsed = double.tryParse(_bwEdit);
      if (parsed != null) _bw = parsed.clamp(0, _bwMax).toDouble();
    });
  }

  Future<void> _next() async {
    if (_step == 2) _commitBodyweight();
    if (!_isLastStep) {
      setState(() => _step += 1);
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step == 2) _commitBodyweight();
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// A barbell answer in canonical kilograms, whatever unit it was typed in.
  int? _strengthKg(String id) {
    final value = _strength[id];
    if (value == null) return null;
    return (_unit == WeightUnit.lb
            ? value * WeightUnitService.kgPerLb
            : value.toDouble())
        .round();
  }

  Future<void> _finish() async {
    final equipment = _equipment ?? SetupEquipment.fullGym;
    final bodyweightKg = _clampBw(_bw) *
        (_unit == WeightUnit.lb ? WeightUnitService.kgPerLb : 1);

    setState(() => _saving = true);
    try {
      await widget.onComplete(
        ProgramSetupResult(
          daysPerWeek: _days ?? 3,
          split: _split,
          equipment: equipment,
          bodyweightKg: bodyweightKg,
          // Only the leg questions matching the equipment answer are
          // recorded, and the loads are converted back to canonical
          // kilograms.
          startingStrength: {
            'pushups': _strength['pushups'],
            'pullups': _strength['pullups'],
            'dips': _strength['dips'],
            if (equipment.hasWeights) ...{
              'squat': _strengthKg('squat'),
              'rdl': _strengthKg('rdl'),
            } else
              'squat_bw': _strength['squat_bw'],
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _ready = true;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to save program setup: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your program. Try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return _ProgramSummaryView(
        days: _days ?? 3,
        split: _split,
        onDone: () => Navigator.of(context).pop(),
      );
    }

    return PopScope(
      // Only the first step is the wizard's exit; everywhere else the back
      // gesture is handled here and steps backwards instead.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _WizardHeader(
                step: _step,
                stepCount: _stepCount,
                onBack: _back,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: switch (_step) {
                    0 => _ScheduleStep(
                        days: _days,
                        onChanged: (value) => setState(() => _days = value),
                      ),
                    1 => _EquipmentStep(
                        equipment: _equipment,
                        onChanged: (value) =>
                            setState(() => _equipment = value),
                      ),
                    2 => _WeightStep(
                        bw: _bw,
                        edit: _bwEdit,
                        editing: _bwEditing,
                        unit: _unit,
                        min: _bwMin,
                        onUnitChanged: _setUnit,
                        onTapValue: () => setState(() {
                          _bwEditing = true;
                          _bwEdit = '';
                        }),
                        onKey: _pressBwKey,
                      ),
                    3 => _StrengthStep(
                        strength: _strength,
                        hasWeights: _equipment?.hasWeights ?? true,
                        unit: _unit,
                        onChanged: () => setState(() {}),
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
              _WizardFooter(
                label: _isLastStep
                    ? 'Build my program'
                    : _ctaDisabled
                        ? 'Pick one to continue'
                        : 'Continue',
                trailingChevron: !_isLastStep && !_ctaDisabled,
                saving: _saving,
                onTap: _ctaDisabled ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final int step;
  final int stepCount;
  final VoidCallback onBack;

  const _WizardHeader({
    required this.step,
    required this.stepCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Pressable(
                onTap: onBack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Build your program',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${step + 1} / $stepCount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              for (var index = 0; index < stepCount; index++) ...[
                if (index > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= step
                          ? AppColors.accentPrimary
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WizardFooter extends StatelessWidget {
  final String label;
  final bool trailingChevron;
  final bool saving;
  final VoidCallback? onTap;

  const _WizardFooter({
    required this.label,
    required this.trailingChevron,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: saving
          ? Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            )
          : PillButton(
              label: label,
              icon: trailingChevron ? Icons.chevron_right_rounded : null,
              trailingIcon: true,
              onTap: onTap,
            ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String sub;

  const _StepTitle({
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.46,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
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

class _WarnNote extends StatelessWidget {
  final IconData icon;
  final InlineSpan message;

  const _WarnNote({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: AppColors.amber),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.amber,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Radio card with a one-sentence "why" explainer under the choice.
class _RadioRow extends StatelessWidget {
  final bool selected;
  final String label;
  final String sub;
  final String? why;
  final VoidCallback onTap;

  const _RadioRow({
    required this.selected,
    required this.label,
    required this.sub,
    this.why,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.16,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (why != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      why!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
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
        const _StepTitle(
          title: 'Your training schedule',
          sub: 'Choose how many days a week you want to train.',
        ),
        const SizedBox(height: 20),
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

class _EquipmentStep extends StatelessWidget {
  final SetupEquipment? equipment;
  final ValueChanged<SetupEquipment> onChanged;

  const _EquipmentStep({
    required this.equipment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Your equipment',
          sub: 'What do you have access to?',
        ),
        const SizedBox(height: 18),
        _RadioRow(
          selected: equipment == SetupEquipment.fullGym,
          label: 'Full gym',
          sub: 'Pull-up bar, rings, barbells',
          why: 'Unlocks weighted progressions — weighted pull-ups, dips and '
              'barbell work run alongside your skill goals.',
          onTap: () => onChanged(SetupEquipment.fullGym),
        ),
        const SizedBox(height: 10),
        _RadioRow(
          selected: equipment == SetupEquipment.freeWeights,
          label: 'Barbell and dumbbells',
          sub: 'A home setup with free weights',
          why: 'Weighted progressions stay in — Forma just builds around '
              'free weights instead of machines and cables.',
          onTap: () => onChanged(SetupEquipment.freeWeights),
        ),
        const SizedBox(height: 10),
        _RadioRow(
          selected: equipment == SetupEquipment.none,
          label: 'No equipment',
          sub: 'Training at home or outdoors',
          why: 'Progress comes from harder bodyweight variations instead of '
              'added weight — nothing about the skills changes.',
          onTap: () => onChanged(SetupEquipment.none),
        ),
        if (equipment != null && equipment != SetupEquipment.fullGym) ...[
          const SizedBox(height: 14),
          const _WarnNote(
            icon: Icons.fitness_center_rounded,
            message: TextSpan(
              children: [
                TextSpan(text: 'You’ll still need access to at least a '),
                TextSpan(
                  text: 'pull-up bar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' — most of Forma’s pulling work hangs from one. '
                      'A doorway bar or a park is enough.',
                ),
              ],
            ),
          ),
        ],
      ],
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
  final ValueChanged<WeightUnit> onUnitChanged;
  final VoidCallback onTapValue;
  final ValueChanged<String> onKey;

  const _WeightStep({
    required this.bw,
    required this.edit,
    required this.editing,
    required this.unit,
    required this.min,
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
    final belowMin = editing && bw < min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Your bodyweight',
          sub: 'Weighted skill targets — like a pull-up at +50% of '
              'bodyweight — are calculated from it, and progressions scale '
              'with it.',
        ),
        const SizedBox(height: 22),
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
        else if (belowMin)
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
        const SizedBox(height: 16),
        const _InfoNote(
          message: TextSpan(
            children: [
              TextSpan(
                  text: 'A close guess is fine — you can update it '
                      'anytime under '),
              TextSpan(
                text: 'Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(text: ', and Forma re-scales your targets.'),
            ],
          ),
        ),
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
      if (hasWeights) ...[
        _barbellSquatFor(unit),
        _romanianDeadliftFor(unit),
      ] else
        _bodyweightSquat,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Where are you starting?',
          sub: 'Max reps in one set — a rough guess is fine. Your first '
              'session will dial it in.',
        ),
        const SizedBox(height: 18),
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
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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
                if (exercise.hint != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    exercise.hint!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _UnsetStepper(
            value: value,
            step: exercise.step,
            def: exercise.def,
            max: exercise.max,
            unitSuffix: exercise.isWeight ? unit.suffix : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Unset by default — "+" adds a value, and stepping below zero clears it
/// back to unset ("—"), which the planner reads as "test it in session one".
class _UnsetStepper extends StatelessWidget {
  final int? value;
  final int step;
  final int def;
  final int max;
  final String? unitSuffix;
  final ValueChanged<int?> onChanged;

  const _UnsetStepper({
    required this.value,
    required this.step,
    required this.def,
    required this.max,
    required this.unitSuffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unset = value == null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          enabled: !unset,
          onTap: () {
            final next = value! - step;
            onChanged(next < 0 ? null : next);
          },
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          alignment: Alignment.center,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: unset ? '—' : '$value',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: unset ? AppColors.textMuted : AppColors.textPrimary,
                    letterSpacing: -0.42,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!unset && unitSuffix != null)
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
        _StepperButton(
          icon: Icons.add_rounded,
          enabled: unset || value! < max,
          onTap: () => onChanged(unset ? def : (value! + step).clamp(0, max)),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: enabled ? onTap : null,
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
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ── Program summary ─────────────────────────────────────────

class _WeekDay {
  final String label;
  final String sub;
  final IconData icon;

  const _WeekDay(this.label, this.sub, this.icon);
}

/// Week layout preview built from the chosen schedule and split.
List<_WeekDay> _weekLayout(int days, TrainingProgramType split) {
  const letters = 'ABCDE';
  switch (split) {
    case TrainingProgramType.fullBody:
      const icons = [
        Icons.trending_flat_rounded,
        Icons.arrow_upward_rounded,
        Icons.accessibility_new_rounded,
        Icons.sync_alt_rounded,
        Icons.fitness_center_rounded,
      ];
      return [
        for (var index = 0; index < days; index++)
          _WeekDay(
            'Full body ${letters[index]}',
            'Push · pull · squat · core',
            icons[index % icons.length],
          ),
      ];
    case TrainingProgramType.upperLower:
      return [
        for (var index = 0; index < days; index++)
          index.isEven
              ? _WeekDay(
                  'Upper ${letters[index ~/ 2]}',
                  'Push · pull · core',
                  Icons.arrow_upward_rounded,
                )
              : _WeekDay(
                  'Lower ${letters[index ~/ 2]}',
                  'Squat · hinge · core',
                  Icons.accessibility_new_rounded,
                ),
      ];
    case TrainingProgramType.pushPull:
      return [
        for (var index = 0; index < days; index++)
          index.isEven
              ? _WeekDay(
                  days > 2 ? 'Push ${letters[index ~/ 2]}' : 'Push',
                  'Push-ups · dips',
                  Icons.trending_flat_rounded,
                )
              : _WeekDay(
                  days > 2 ? 'Pull ${letters[index ~/ 2]}' : 'Pull',
                  'Pull-ups · rows',
                  Icons.arrow_upward_rounded,
                ),
      ];
  }
}

/// Post-wizard reveal: presents the built program's week as a motivating
/// overview before landing back on Home.
class _ProgramSummaryView extends StatefulWidget {
  final int days;
  final TrainingProgramType split;
  final VoidCallback onDone;

  const _ProgramSummaryView({
    required this.days,
    required this.split,
    required this.onDone,
  });

  @override
  State<_ProgramSummaryView> createState() => _ProgramSummaryViewState();
}

class _ProgramSummaryViewState extends State<_ProgramSummaryView>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1500);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Staggered ease-out segment matching the mockup's 90ms cascade.
  Animation<double> _segment(int index) {
    final start = (150 + index * 90) / _duration.inMilliseconds;
    final end = start + 550 / _duration.inMilliseconds;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final week = _weekLayout(widget.days, widget.split);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    var step = 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 64),
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _controller,
                        curve:
                            const Interval(0, 0.4, curve: Curves.easeOutBack),
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentSoft,
                          border: Border.all(
                            color: AppColors.accentGlow,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          size: 33,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Reveal(
                      animation: _segment(step++),
                      child: const Text(
                        'Your program is ready',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Reveal(
                      animation: _segment(step++),
                      child: const Center(
                        child: SizedBox(
                          width: 300,
                          child: Text(
                            'Built from your answers. Change anything '
                            'you like.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _SummaryStat(
                              animation: _segment(step++),
                              value: '${widget.days}×',
                              label: 'per week',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryStat(
                              animation: _segment(step++),
                              value: '8',
                              label: 'exercises',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SummaryLabel(
                      animation: _segment(step++),
                      text: 'Your week — ${widget.split.label}',
                    ),
                    _Reveal(
                      animation: _segment(step++),
                      child: _WeekCard(week: week),
                    ),
                  ],
                ),
              ),
            ),
            _Reveal(
              animation: _segment(step + 1),
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: PillButton(
                  label: 'Let’s go',
                  icon: Icons.chevron_right_rounded,
                  trailingIcon: true,
                  onTap: widget.onDone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fade + 16px upward slide, matching the mockup's entrance animation.
class _Reveal extends AnimatedWidget {
  final Widget child;

  const _Reveal({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - t)),
        child: child,
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final Animation<double> animation;
  final String value;
  final String label;

  const _SummaryStat({
    required this.animation,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      animation: animation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.44,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  final Animation<double> animation;
  final String text;

  const _SummaryLabel({
    required this.animation,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      animation: animation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final List<_WeekDay> week;

  const _WeekCard({required this.week});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < week.length; index++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: index == 0
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
              child: Row(
                children: [
                  IconTile(icon: week[index].icon, tint: index == 0),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          week[index].label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          week[index].sub,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'UP FIRST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentPrimary,
                          letterSpacing: 0.33,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Session ${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
