import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/training_program_model.dart';

/// Answers collected by the "Build your program" wizard.
class ProgramSetupResult {
  final int daysPerWeek;
  final TrainingProgramType split;
  final bool hasGym;

  /// exercise id -> reps/kg value, or null when the user picked "I don't know".
  final Map<String, int?> startingStrength;
  final List<String> skillIds;

  const ProgramSetupResult({
    required this.daysPerWeek,
    required this.split,
    required this.hasGym,
    required this.startingStrength,
    required this.skillIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'days_per_week': daysPerWeek,
      'split': split.dbValue,
      'has_gym': hasGym,
      'starting_strength': startingStrength,
      'skill_ids': skillIds,
    };
  }
}

// ── Wizard data ─────────────────────────────────────────────

const _days = [2, 3, 4, 5, 6];

class _SplitOption {
  final TrainingProgramType type;
  final String label;
  final String sub;

  const _SplitOption(this.type, this.label, this.sub);
}

const _splits = [
  _SplitOption(
    TrainingProgramType.fullBody,
    'Full body',
    'Every session trains everything',
  ),
  _SplitOption(
    TrainingProgramType.upperLower,
    'Upper / Lower',
    'Alternate upper- and lower-body days',
  ),
  _SplitOption(
    TrainingProgramType.pushPull,
    'Push / Pull',
    'One movement focus per session',
  ),
];

TrainingProgramType _recommendedSplit(int days) {
  if (days <= 3) return TrainingProgramType.fullBody;
  if (days == 4) return TrainingProgramType.upperLower;
  return TrainingProgramType.pushPull;
}

class _StrengthExercise {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final String unit;
  final int step;
  final int def;
  final int max;

  const _StrengthExercise({
    required this.id,
    required this.label,
    required this.sub,
    required this.icon,
    this.unit = 'reps',
    this.step = 1,
    required this.def,
    required this.max,
  });
}

const _strengthExercises = [
  _StrengthExercise(
    id: 'pushups',
    label: 'Push-ups',
    sub: 'Max reps in one set',
    icon: Icons.trending_flat_rounded,
    def: 10,
    max: 100,
  ),
  _StrengthExercise(
    id: 'pullups',
    label: 'Pull-ups',
    sub: 'Max reps in one set',
    icon: Icons.arrow_upward_rounded,
    def: 3,
    max: 50,
  ),
  _StrengthExercise(
    id: 'dips',
    label: 'Dips',
    sub: 'Max reps in one set',
    icon: Icons.north_rounded,
    def: 5,
    max: 50,
  ),
  _StrengthExercise(
    id: 'squat',
    label: 'Barbell squat',
    sub: 'One rep maximum',
    icon: Icons.accessibility_new_rounded,
    unit: 'kg',
    step: 5,
    def: 40,
    max: 300,
  ),
];

const _difficultyLabels = ['Approachable', 'Intermediate', 'Advanced'];

class _SkillGroup {
  final String id;
  final String label;

  const _SkillGroup(this.id, this.label);
}

const _skillGroups = [
  _SkillGroup('pullups', 'Pull-ups'),
  _SkillGroup('rows', 'Rows'),
  _SkillGroup('pushups', 'Push-ups'),
  _SkillGroup('dips', 'Dips'),
  _SkillGroup('squat', 'Squat'),
  _SkillGroup('other', 'Other skills'),
];

class _SkillOption {
  final String id;
  final String label;
  final IconData icon;
  final String group;
  final int difficulty;

  const _SkillOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.group,
    required this.difficulty,
  });
}

const _skills = [
  _SkillOption(id: 'weighted', label: 'Weighted pull-up', icon: Icons.arrow_upward_rounded, group: 'pullups', difficulty: 1),
  _SkillOption(id: 'highpull', label: 'High pull-up', icon: Icons.arrow_upward_rounded, group: 'pullups', difficulty: 1),
  _SkillOption(id: 'lsitpull', label: 'L-sit pull-up', icon: Icons.self_improvement_rounded, group: 'pullups', difficulty: 1),
  _SkillOption(id: 'oap', label: 'One-arm pull-up', icon: Icons.arrow_upward_rounded, group: 'pullups', difficulty: 2),
  _SkillOption(id: 'wrow', label: 'Weighted row', icon: Icons.sync_alt_rounded, group: 'rows', difficulty: 1),
  _SkillOption(id: 'oarow', label: 'One-arm row', icon: Icons.sync_alt_rounded, group: 'rows', difficulty: 1),
  _SkillOption(id: 'frontlever', label: 'Front lever', icon: Icons.sync_alt_rounded, group: 'rows', difficulty: 2),
  _SkillOption(id: 'ringpu', label: 'Rings push-up', icon: Icons.north_rounded, group: 'pushups', difficulty: 1),
  _SkillOption(id: 'oapu', label: 'One-arm push-up', icon: Icons.trending_flat_rounded, group: 'pushups', difficulty: 1),
  _SkillOption(id: 'planchepu', label: 'Planche push-up', icon: Icons.trending_flat_rounded, group: 'pushups', difficulty: 2),
  _SkillOption(id: 'wdip', label: 'Weighted dip', icon: Icons.north_rounded, group: 'dips', difficulty: 1),
  _SkillOption(id: 'ringdip', label: 'Ring dip', icon: Icons.north_rounded, group: 'dips', difficulty: 1),
  _SkillOption(id: 'pistol', label: 'Pistol squat', icon: Icons.accessibility_new_rounded, group: 'squat', difficulty: 1),
  _SkillOption(id: 'shrimp', label: 'Shrimp squat', icon: Icons.accessibility_new_rounded, group: 'squat', difficulty: 1),
  _SkillOption(id: 'lsit', label: 'L-sit / V-sit', icon: Icons.self_improvement_rounded, group: 'other', difficulty: 1),
  _SkillOption(id: 'muscleup', label: 'Muscle-up', icon: Icons.fitness_center_rounded, group: 'other', difficulty: 2),
  _SkillOption(id: 'hspu', label: 'Handstand push-up', icon: Icons.sports_gymnastics_rounded, group: 'other', difficulty: 2),
  _SkillOption(id: 'planche', label: 'Planche', icon: Icons.trending_flat_rounded, group: 'other', difficulty: 2),
];

// ── Wizard ──────────────────────────────────────────────────

/// Five-step "Build your program" wizard: schedule, split, equipment,
/// starting strength and skill goals. Calls [onComplete] with the answers,
/// then shows the "program ready" confirmation.
class ProgramSetupView extends StatefulWidget {
  final Future<void> Function(ProgramSetupResult result) onComplete;

  const ProgramSetupView({
    super.key,
    required this.onComplete,
  });

  @override
  State<ProgramSetupView> createState() => _ProgramSetupViewState();
}

class _StrengthAnswer {
  int value;
  bool unsure;

  _StrengthAnswer(this.value) : unsure = false;
}

class _ProgramSetupViewState extends State<ProgramSetupView> {
  static const _stepCount = 5;

  int _step = 0;
  int _days = 4;
  TrainingProgramType? _split; // null = follow recommendation
  bool _hasGym = true;
  final Map<String, _StrengthAnswer> _strength = {
    for (final exercise in _strengthExercises)
      exercise.id: _StrengthAnswer(exercise.def),
  };
  final List<String> _pickedSkills = [];
  bool _saving = false;
  bool _ready = false;

  TrainingProgramType get _effectiveSplit => _split ?? _recommendedSplit(_days);

  bool get _isLastStep => _step == _stepCount - 1;

  Future<void> _next() async {
    if (!_isLastStep) {
      setState(() => _step += 1);
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await widget.onComplete(
        ProgramSetupResult(
          daysPerWeek: _days,
          split: _effectiveSplit,
          hasGym: _hasGym,
          startingStrength: {
            for (final entry in _strength.entries)
              entry.key: entry.value.unsure ? null : entry.value.value,
          },
          skillIds: List.of(_pickedSkills),
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
      return _ProgramReadyView(
        onDone: () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
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
                  1 => _SplitStep(
                      days: _days,
                      split: _effectiveSplit,
                      onChanged: (value) => setState(() => _split = value),
                    ),
                  2 => _EquipmentStep(
                      hasGym: _hasGym,
                      onChanged: (value) => setState(() => _hasGym = value),
                    ),
                  3 => _StrengthStep(
                      strength: _strength,
                      onChanged: () => setState(() {}),
                    ),
                  _ => _SkillsStep(
                      picked: _pickedSkills,
                      onToggleSkill: (id) => setState(() {
                        if (_pickedSkills.contains(id)) {
                          _pickedSkills.remove(id);
                        } else {
                          _pickedSkills.add(id);
                        }
                      }),
                    ),
                },
              ),
            ),
            _WizardFooter(
              label: !_isLastStep
                  ? 'Continue'
                  : _pickedSkills.isEmpty
                      ? 'Skip — build my program'
                      : 'Build my program',
              trailingChevron: !_isLastStep,
              saving: _saving,
              onTap: _next,
            ),
          ],
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
  final VoidCallback onTap;

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
  final String text;

  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
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

class _RadioRow extends StatelessWidget {
  final bool selected;
  final String label;
  final String sub;
  final String? badge;
  final VoidCallback onTap;

  const _RadioRow({
    required this.selected,
    required this.label,
    required this.sub,
    this.badge,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
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
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
  final int days;
  final ValueChanged<int> onChanged;

  const _ScheduleStep({
    required this.days,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 16),
        _InfoNote(
          text: days == 2
              ? 'Two focused sessions still move you forward — Forma keeps '
                  'each one efficient.'
              : '$days days gives Forma room for a balanced week across '
                  'every movement pattern.',
        ),
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

// ── Step 2: split ───────────────────────────────────────────

class _SplitStep extends StatelessWidget {
  final int days;
  final TrainingProgramType split;
  final ValueChanged<TrainingProgramType> onChanged;

  const _SplitStep({
    required this.days,
    required this.split,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final recommended = _recommendedSplit(days);
    final warn = days == 2 && split != TrainingProgramType.fullBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          title: 'Pick your split',
          sub: 'How your $days weekly sessions divide the work. '
              'You can change this anytime.',
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < _splits.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _RadioRow(
            selected: _splits[index].type == split,
            label: _splits[index].label,
            sub: _splits[index].sub,
            badge: _splits[index].type == recommended ? 'Recommended' : null,
            onTap: () => onChanged(_splits[index].type),
          ),
        ],
        if (warn) ...[
          const SizedBox(height: 14),
          const _WarnNote(
            icon: Icons.warning_amber_rounded,
            message: TextSpan(
              children: [
                TextSpan(
                  text: 'At 2 days a week, a split rotation trains each '
                      'muscle less than once a week. ',
                ),
                TextSpan(
                  text: 'Full body is recommended.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Step 3: equipment ───────────────────────────────────────

class _EquipmentStep extends StatelessWidget {
  final bool hasGym;
  final ValueChanged<bool> onChanged;

  const _EquipmentStep({
    required this.hasGym,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Where will you train?',
          sub: 'Do you have access to a full gym?',
        ),
        const SizedBox(height: 18),
        _RadioRow(
          selected: hasGym,
          label: 'Yes, a full gym',
          sub: 'Pull-up bar, rings, barbells — the works',
          onTap: () => onChanged(true),
        ),
        const SizedBox(height: 10),
        _RadioRow(
          selected: !hasGym,
          label: 'No gym',
          sub: 'Training at home or outdoors',
          onTap: () => onChanged(false),
        ),
        if (!hasGym) ...[
          const SizedBox(height: 14),
          const _WarnNote(
            icon: Icons.fitness_center_rounded,
            message: TextSpan(
              children: [
                TextSpan(text: 'You’ll need access to at least a '),
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

// ── Step 4: starting strength ───────────────────────────────

class _StrengthStep extends StatelessWidget {
  final Map<String, _StrengthAnswer> strength;
  final VoidCallback onChanged;

  const _StrengthStep({
    required this.strength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'Where are you starting?',
          sub: 'A rough guess is fine — this just sets your opening '
              'progressions. Not sure? Your first session will find out.',
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < _strengthExercises.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _StrengthCard(
            exercise: _strengthExercises[index],
            answer: strength[_strengthExercises[index].id]!,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final _StrengthExercise exercise;
  final _StrengthAnswer answer;
  final VoidCallback onChanged;

  const _StrengthCard({
    required this.exercise,
    required this.answer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unsure = answer.unsure;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    const SizedBox(height: 1),
                    Text(
                      unsure
                          ? 'Forma will test this in session one'
                          : exercise.sub,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (unsure)
                const SizedBox(
                  width: 130,
                  child: Text(
                    '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                _Stepper(
                  value: answer.value,
                  step: exercise.step,
                  max: exercise.max,
                  unit: exercise.unit,
                  onChanged: (value) {
                    answer.value = value;
                    onChanged();
                  },
                ),
            ],
          ),
          const SizedBox(height: 11),
          Pressable(
            onTap: () {
              answer.unsure = !answer.unsure;
              onChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: unsure ? AppColors.accentSoft : AppColors.surface2,
                borderRadius: BorderRadius.circular(999),
                border: unsure
                    ? Border.all(color: AppColors.accentPrimary, width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 1.6,
                        color: unsure
                            ? AppColors.accentPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: unsure
                        ? const Icon(
                            Icons.check_rounded,
                            size: 9,
                            color: AppColors.accentPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'I don’t know',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: unsure
                          ? AppColors.accentPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int step;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.step,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          enabled: value > 0,
          onTap: () => onChanged((value - step).clamp(0, max)),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          alignment: Alignment.center,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.42,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit == 'kg')
                  const TextSpan(
                    text: ' kg',
                    style: TextStyle(
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
          enabled: value < max,
          onTap: () => onChanged((value + step).clamp(0, max)),
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

// ── Step 5: skills ──────────────────────────────────────────

class _SkillsStep extends StatelessWidget {
  final List<String> picked;
  final ValueChanged<String> onToggleSkill;

  const _SkillsStep({
    required this.picked,
    required this.onToggleSkill,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle(
          title: 'What do you want to learn?',
          sub: 'Pick any skills that excite you — you don’t need to be able '
              'to do any of them yet. Forma builds the path from where you '
              'are today.',
        ),
        for (final group in _skillGroups)
          ..._buildGroup(
            group,
            _skills.where((skill) => skill.group == group.id).toList(),
          ),
        const SizedBox(height: 16),
        const _InfoNote(
          text: 'Nothing calling to you yet? Skip this — Forma builds a '
              'balanced program either way.',
        ),
      ],
    );
  }

  List<Widget> _buildGroup(_SkillGroup group, List<_SkillOption> skills) {
    if (skills.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 9),
        child: Text(
          group.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      _SkillGrid(
        skills: skills,
        picked: picked,
        onToggleSkill: onToggleSkill,
      ),
    ];
  }
}

class _SkillGrid extends StatelessWidget {
  final List<_SkillOption> skills;
  final List<String> picked;
  final ValueChanged<String> onToggleSkill;

  const _SkillGrid({
    required this.skills,
    required this.picked,
    required this.onToggleSkill,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < skills.length; index += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SkillCard(
                    skill: skills[index],
                    selected: picked.contains(skills[index].id),
                    onTap: () => onToggleSkill(skills[index].id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: index + 1 < skills.length
                      ? _SkillCard(
                          skill: skills[index + 1],
                          selected: picked.contains(skills[index + 1].id),
                          onTap: () => onToggleSkill(skills[index + 1].id),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _SkillCard extends StatelessWidget {
  final _SkillOption skill;
  final bool selected;
  final VoidCallback onTap;

  const _SkillCard({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.accentPrimary, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  skill.icon,
                  size: 22,
                  color: selected
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                ),
                if (selected)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              skill.label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                for (var dot = 0; dot < 3; dot++)
                  Container(
                    width: 4.5,
                    height: 4.5,
                    margin: EdgeInsets.only(right: dot < 2 ? 2.5 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot <= skill.difficulty
                          ? (selected
                              ? AppColors.accentPrimary
                              : AppColors.textSecondary)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                const SizedBox(width: 5),
                Text(
                  _difficultyLabels[skill.difficulty],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Program ready ───────────────────────────────────────────

class _ProgramReadyView extends StatelessWidget {
  final VoidCallback onDone;

  const _ProgramReadyView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
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
                    size: 36,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your program is ready',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.52,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  width: 290,
                  child: Text(
                    'Forma built a balanced split across every movement '
                    'pattern. Your first session is waiting on the home '
                    'screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Pressable(
                  onTap: onDone,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Go to my program',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
