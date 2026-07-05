import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/onboarding_profile_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/onboarding_service.dart';

/// Post-signup onboarding flow: welcome → how it works → what's inside →
/// archetype radar → about you → summary. Shown once per account; the
/// answers are saved to `user_onboarding_profiles` on Finish.

// ── Archetype radar data ────────────────────────────────────────────────────

class _Archetype {
  final String id;
  final double dir; // degrees on the radar; -90 is up
  final String name;
  final String sub;
  final Color hue;

  const _Archetype(this.id, this.dir, this.name, this.sub, this.hue);
}

const _archetypes = [
  _Archetype('technician', -90, 'The Technician',
      'Masters the moves, rep by rep', Color(0xFFA78BFA)),
  _Archetype('specialist', -45, 'The Specialist',
      'Elite static holds like planche and levers', Color(0xFFC98BCF)),
  _Archetype('powerhouse', 0, 'The Powerhouse',
      'Weighted, heavy, brute power', AppColors.accentPrimary),
  _Archetype('heavyweight', 45, 'The Heavyweight',
      'Strong and built to match', Color(0xFFFF7DA8)),
  _Archetype('builder', 90, 'The Builder', 'Lean, muscular, deliberate',
      Color(0xFFF472B6)),
  _Archetype('natural', 135, 'The Natural', 'Lean, limber, moves with ease',
      Color(0xFF7EC8D6)),
  _Archetype('mover', 180, 'The Mover', 'Range, control, pain-free',
      Color(0xFF4ECDC4)),
  _Archetype('artist', 225, 'The Artist', 'Handbalance, shapes, clean lines',
      Color(0xFF7FB8E6)),
];

const _balancedArchetype = _Archetype('generalist', -90, 'The Generalist',
    'Balanced across the board', AppColors.accentPrimary);

class _RadarAxis {
  final String label;
  final double deg;
  final Color hue;

  const _RadarAxis(this.label, this.deg, this.hue);
}

const _radarAxes = [
  _RadarAxis('SKILLS', -90, Color(0xFFA78BFA)),
  _RadarAxis('STRENGTH', 0, AppColors.accentPrimary),
  _RadarAxis('PHYSIQUE', 90, Color(0xFFF472B6)),
  _RadarAxis('MOBILITY', 180, Color(0xFF4ECDC4)),
];

/// Absolute angular distance normalised to 0–180°.
double _angularDistance(double degrees) {
  final wrapped = ((degrees + 180) % 360 + 360) % 360;
  return (wrapped - 180).abs();
}

int _nearestArchetypeIndex(double angleDeg) {
  var best = 0;
  for (var i = 1; i < _archetypes.length; i++) {
    if (_angularDistance(_archetypes[i].dir - angleDeg) <
        _angularDistance(_archetypes[best].dir - angleDeg)) {
      best = i;
    }
  }
  return best;
}

// ── About-you choices ───────────────────────────────────────────────────────

class _Choice {
  final String id;
  final String label;
  final int flex; // relative width ×10

  const _Choice(this.id, this.label, {this.flex = 10});
}

const _freqChoices = [
  _Choice('0', 'Not yet', flex: 13),
  _Choice('1-2', '1–2×'),
  _Choice('3-4', '3–4×'),
  _Choice('5+', '5+×'),
];

const _genderChoices = [
  _Choice('f', 'Female'),
  _Choice('m', 'Male'),
  _Choice('na', 'Prefer not to say', flex: 16),
];

// ── Flow ────────────────────────────────────────────────────────────────────

class OnboardingView extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingView({super.key, required this.onFinished});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _stepCount = 6;

  int _step = 0;
  bool _balanced = true;
  double _angleDeg = -90;
  int _age = 28;
  String? _gender;
  String? _freq;
  bool _saving = false;

  _Archetype get _archetype =>
      _balanced ? _balancedArchetype : _archetypes[_nearestArchetypeIndex(_angleDeg)];

  /// The radar step tints the progress bar and headline with the archetype.
  Color get _hue => _step == 3 ? _archetype.hue : AppColors.accentPrimary;

  bool get _isLast => _step == _stepCount - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  Future<void> _finish() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null || _saving) return;

    setState(() => _saving = true);
    try {
      await OnboardingService().saveProfile(OnboardingProfileModel(
        userId: userId,
        archetype: _archetype.id,
        radarBalanced: _balanced,
        radarAngleDeg: _balanced ? null : _angleDeg,
        age: _age,
        gender: _gender,
        trainingFrequency: _freq,
        completedAt: DateTime.now().toUtc(),
      ));
      widget.onFinished();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildWelcome(),
      _buildHowItWorks(),
      _buildWhatsInside(),
      _buildRadarStep(),
      _buildAboutYou(),
      _buildSummary(),
    ];
    final cta = _step == 0
        ? 'Get started'
        : _isLast
            ? (_saving ? 'Saving…' : 'Finish')
            : 'Continue';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(_step), child: steps[_step]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: PillButton(label: cta, onTap: _saving ? null : _next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Visibility(
            visible: _step > 0,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Pressable(
              onTap: () => setState(() => _step = math.max(0, _step - 1)),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < _stepCount; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? _hue
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Visibility(
            visible: !_isLast,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Pressable(
              onTap: () => setState(() => _step = _stepCount - 1),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: welcome ──

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'WELCOME TO FORMA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Train your body.\nMaster real skills.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.05,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Forma is your calisthenics coach. Every session builds the '
            'strength and mobility behind moves like the muscle-up and '
            'handstand.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: how it works — skill ladder ──

  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHead(
            eyebrow: 'How it works',
            title: 'You always know what to train.',
            sub: 'Every skill is a ladder of moves, climbed from the bottom. '
                'Forma picks the exact one for today\'s session — clear it '
                'and the next move unlocks.',
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ladderRow('Pull-up', AppColors.green, Icons.check_rounded,
                    tag: 'DONE'),
                _ladderConnector(),
                _ladderRow('False-grip Pull-ups', AppColors.accentPrimary,
                    Icons.play_arrow_rounded,
                    tag: 'NEXT', ringed: true),
                _ladderConnector(),
                _ladderRow('Muscle-up Negatives', AppColors.textMuted,
                    Icons.lock_outline_rounded),
                _ladderConnector(),
                _ladderGoalRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ladderRow(String name, Color color, IconData icon,
      {String? tag, bool ringed = false}) {
    final locked = color == AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: locked
                  ? AppColors.surface
                  : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: ringed
                  ? Border.all(color: AppColors.accentPrimary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: locked ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
          if (tag != null)
            Text(
              tag,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _ladderGoalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.flag_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muscle-up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'The skill you\'re building toward',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'GOAL',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ladderConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 34),
      width: 2,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // ── Step 2: what's inside ──

  Widget _buildWhatsInside() {
    const items = [
      (
        Icons.account_tree_rounded,
        'Skill trees',
        'See the whole path to a skill, one move at a time.'
      ),
      (
        Icons.fitness_center_rounded,
        'Daily workouts',
        'Open the app and today\'s session is ready for your level.'
      ),
      (
        Icons.trending_up_rounded,
        'Progress tracking',
        'Log every rep and hold, and track your numbers over time.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHead(eyebrow: 'What you get', title: 'What\'s inside.'),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (icon, title, sub) in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: SurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon,
                                size: 22, color: AppColors.accentPrimary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  sub,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: archetype radar ──

  Widget _buildRadarStep() {
    final arch = _archetype;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHead(
            eyebrow: 'Your profile',
            title: 'What brings you to Forma?',
            sub: 'Drag the dot toward what excites you most, or leave it '
                'centred. This just helps us get to know you.',
            hue: _hue,
          ),
          Expanded(
            // Centered explicitly — the step column is start-aligned, so the
            // shrink-wrapped radar cluster would otherwise sit at the left.
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RadarChart(
                    balanced: _balanced,
                    angleDeg: _angleDeg,
                    interactive: true,
                    onChanged: (balanced, angleDeg) => setState(() {
                      _balanced = balanced;
                      _angleDeg = angleDeg;
                    }),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _balanced ? 'BALANCED' : 'YOUR ARCHETYPE',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    arch.name,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: _balanced ? AppColors.textPrimary : arch.hue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    arch.sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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

  // ── Step 4: about you ──

  Widget _buildAboutYou() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 4, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHead(eyebrow: 'Your profile', title: 'About you.'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 18, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldCaption('YOUR AGE'),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '$_age${_age >= 70 ? '+' : ''}',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        height: 1,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ObSlider(
                    value: (_age - 16) / 54,
                    onChanged: (v) =>
                        setState(() => _age = 16 + (v * 54).round()),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('16', style: _rangeLabelStyle),
                      Text('70+', style: _rangeLabelStyle),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _FieldCaption('HOW OFTEN DO YOU ALREADY TRAIN?'),
                  const SizedBox(height: 10),
                  _choiceRow(
                    _freqChoices,
                    _freq,
                    (id) => setState(() => _freq = _freq == id ? null : id),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sessions per week, any kind of training.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  const _FieldCaption('GENDER'),
                  const SizedBox(height: 10),
                  _choiceRow(
                    _genderChoices,
                    _gender,
                    (id) =>
                        setState(() => _gender = _gender == id ? null : id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _rangeLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  Widget _choiceRow(
    List<_Choice> choices,
    String? selected,
    ValueChanged<String> onTap,
  ) {
    return Row(
      children: [
        for (var i = 0; i < choices.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            flex: choices[i].flex,
            child: Pressable(
              onTap: () => onTap(choices[i].id),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: selected == choices[i].id
                      ? AppColors.accentSoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  choices[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: selected == choices[i].id
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 5: summary ──

  Widget _buildSummary() {
    final arch = _archetype;
    final rows = [
      ('Age', '$_age${_age >= 70 ? '+' : ''}'),
      (
        'Trains',
        _freq == null
            ? '—'
            : _freq == '0'
                ? 'New to training'
                : '$_freq / week'
      ),
      (
        'Gender',
        _gender == null
            ? '—'
            : _genderChoices.firstWhere((g) => g.id == _gender).label
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHead(
            eyebrow: 'You\'re ready',
            title: 'Your Forma profile.',
            sub: 'Here\'s what we learned about you. Next, Forma builds your '
                'program around it.',
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                  child: Column(
                    children: [
                      _RadarChart(
                        balanced: _balanced,
                        angleDeg: _angleDeg,
                        interactive: false,
                        scale: 0.78,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'YOUR ARCHETYPE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        arch.name,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color:
                              _balanced ? AppColors.textPrimary : arch.hue,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        arch.sub,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.divider),
                      for (var i = 0; i < rows.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rows[i].$1,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                rows[i].$2,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < rows.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared step header ──────────────────────────────────────────────────────

class _StepHead extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? sub;
  final Color hue;

  const _StepHead({
    required this.eyebrow,
    required this.title,
    this.sub,
    this.hue = AppColors.accentPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: hue,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
            color: AppColors.textPrimary,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 8),
          Text(
            sub!,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldCaption extends StatelessWidget {
  final String text;

  const _FieldCaption(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: AppColors.textMuted,
      ),
    );
  }
}

// ── Age slider ──────────────────────────────────────────────────────────────

class _ObSlider extends StatelessWidget {
  final double value; // 0–1
  final ValueChanged<double> onChanged;

  const _ObSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void set(double dx) => onChanged((dx / width).clamp(0.0, 1.0));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => set(d.localPosition.dx),
          onHorizontalDragStart: (d) => set(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
          child: SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  height: 8,
                  width: width * value,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Positioned(
                  left: (width * value - 13).clamp(0.0, width - 26),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x80000000),
                          offset: Offset(0, 2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Radar chart ─────────────────────────────────────────────────────────────

class _RadarChart extends StatelessWidget {
  static const double _radius = 96;
  static const double _margin = 40; // room for the axis labels

  final bool balanced;
  final double angleDeg;
  final bool interactive;
  final double scale;
  final void Function(bool balanced, double angleDeg)? onChanged;

  const _RadarChart({
    required this.balanced,
    required this.angleDeg,
    required this.interactive,
    this.scale = 1,
    this.onChanged,
  });

  void _handle(Offset local, double side) {
    final delta = local - Offset(side / 2, side / 2);
    if (delta.distance < _radius * scale * 0.3) {
      onChanged!(true, angleDeg);
    } else {
      onChanged!(false, math.atan2(delta.dy, delta.dx) * 180 / math.pi);
    }
  }

  @override
  Widget build(BuildContext context) {
    final side = 2 * (_radius + _margin) * scale;
    final chart = SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
        painter: _RadarPainter(
          balanced: balanced,
          angleDeg: angleDeg,
          scale: scale,
        ),
      ),
    );

    if (!interactive) return chart;
    return GestureDetector(
      onPanDown: (d) => _handle(d.localPosition, side),
      onPanUpdate: (d) => _handle(d.localPosition, side),
      child: chart,
    );
  }
}

class _RadarPainter extends CustomPainter {
  final bool balanced;
  final double angleDeg;
  final double scale;

  _RadarPainter({
    required this.balanced,
    required this.angleDeg,
    required this.scale,
  });

  Offset _pt(Offset c, double deg, double r) {
    final rad = deg * math.pi / 180;
    return c + Offset(math.cos(rad) * r, math.sin(rad) * r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = _RadarChart._radius * scale;
    final sel = _archetypes[_nearestArchetypeIndex(angleDeg)];
    final hue = balanced ? AppColors.accentPrimary : sel.hue;

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.07);
    for (final f in [0.34, 0.67, 1.0]) {
      canvas.drawCircle(c, radius * f, grid);
    }
    for (final axis in _radarAxes) {
      canvas.drawLine(c, _pt(c, axis.deg, radius), grid);
    }

    // Selected-archetype wedge.
    if (!balanced) {
      const half = 22.5;
      final wedge = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(_pt(c, sel.dir - half, radius * 0.92).dx,
            _pt(c, sel.dir - half, radius * 0.92).dy)
        ..lineTo(_pt(c, sel.dir, radius * 0.92).dx,
            _pt(c, sel.dir, radius * 0.92).dy)
        ..lineTo(_pt(c, sel.dir + half, radius * 0.92).dx,
            _pt(c, sel.dir + half, radius * 0.92).dy)
        ..close();
      canvas.drawPath(
        wedge,
        Paint()..color = hue.withValues(alpha: 0.22),
      );
      canvas.drawPath(
        wedge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale
          ..strokeJoin = StrokeJoin.round
          ..color = hue.withValues(alpha: 0.55),
      );
    }

    // Archetype anchor dots.
    for (var i = 0; i < _archetypes.length; i++) {
      final on = !balanced && _archetypes[i] == sel;
      canvas.drawCircle(
        _pt(c, _archetypes[i].dir, radius * 0.92),
        (on ? 4 : 3) * scale,
        Paint()
          ..color = on
              ? _archetypes[i].hue
              : Colors.white.withValues(alpha: 0.22),
      );
    }

    // Centre ("balanced") target.
    if (balanced) {
      canvas.drawCircle(
        c,
        9 * scale,
        Paint()..color = AppColors.accentPrimary.withValues(alpha: 0.22),
      );
    }
    canvas.drawCircle(
      c,
      9 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..color = balanced
            ? AppColors.accentPrimary
            : Colors.white.withValues(alpha: 0.2),
    );

    // Axis labels.
    for (final axis in _radarAxes) {
      final painter = TextPainter(
        text: TextSpan(
          text: axis.label,
          style: TextStyle(
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8 * scale,
            color: axis.hue.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = _pt(c, axis.deg, radius + 22 * scale);
      painter.paint(
        canvas,
        pos - Offset(painter.width / 2, painter.height / 2),
      );
    }

    // Drag dot.
    final dot = balanced ? c : _pt(c, angleDeg, radius * 0.92);
    canvas.drawCircle(dot, 14 * scale, Paint()..color = hue.withValues(alpha: 0.25));
    canvas.drawCircle(dot, 8.5 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(
      dot,
      8.5 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..color = hue,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) {
    return oldDelegate.balanced != balanced ||
        oldDelegate.angleDeg != angleDeg ||
        oldDelegate.scale != scale;
  }
}
