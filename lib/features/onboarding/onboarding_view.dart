import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/skill_tree_map.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/onboarding_profile_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/onboarding_service.dart';

/// Post-signup onboarding: welcome hook → three grounded beats (the skill tree
/// route, the workout that levels up, the data loop that eases you back) →
/// archetype radar → about you → ready. Shown once per account; the answers are
/// saved to `user_onboarding_profiles` when the last step is confirmed.

// ── Shared type styles ──────────────────────────────────────────────────────

TextStyle _mono({
  required Color color,
  double size = 10.5,
  double spacing = 1.5,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.robotoMono(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      color: color,
    );

const _titleStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.6,
  height: 1.12,
  color: AppColors.textPrimary,
);

const _captionStyle = TextStyle(
  fontSize: 14,
  height: 1.5,
  color: AppColors.textSecondary,
);

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
      'More time on skill progressions and getting your form right.',
      Color(0xFFA78BFA)),
  _Archetype('specialist', -45, 'The Specialist',
      'Leans on static holds like the planche and front lever.',
      Color(0xFF7FA8F0)),
  _Archetype('powerhouse', 0, 'The Powerhouse',
      'Low reps and added weight to build raw strength.',
      AppColors.accentPrimary),
  _Archetype('heavyweight', 45, 'The Heavyweight',
      'Heavy lifting for strength, with extra sets to add size.',
      Color(0xFF7DB0FF)),
  _Archetype('builder', 90, 'The Builder',
      'Higher reps and more volume to put on muscle.', Color(0xFFF472B6)),
  _Archetype('natural', 135, 'The Natural',
      'Steady strength work with enough mobility to move well.',
      Color(0xFF7EC8D6)),
  _Archetype('mover', 180, 'The Mover',
      'More mobility work so you move well and stay injury-free.',
      Color(0xFF4ECDC4)),
  _Archetype('artist', 225, 'The Artist',
      'Handstand and balance work, with the flexibility to match.',
      Color(0xFF7FB8E6)),
];

const _balancedArchetype = _Archetype('generalist', -90, 'The Generalist',
    'A bit of everything, without specializing.', AppColors.accentPrimary);

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
  static const _stepCount = 7;

  /// The step that tints the progress bar with the picked archetype.
  static const _radarStep = 4;

  int _step = 0;
  int _dir = 1;
  bool _balanced = true;
  double _angleDeg = -90;
  int _age = 28;
  String? _gender;
  String? _freq;
  bool _saving = false;

  _Archetype get _archetype => _balanced
      ? _balancedArchetype
      : _archetypes[_nearestArchetypeIndex(_angleDeg)];

  Color get _hue =>
      _step == _radarStep ? _archetype.hue : AppColors.accentPrimary;

  bool get _isLast => _step == _stepCount - 1;

  void _go(int next) {
    final clamped = next.clamp(0, _stepCount - 1);
    if (clamped == _step) return;
    setState(() {
      _dir = clamped >= _step ? 1 : -1;
      _step = clamped;
    });
  }

  void _advance() {
    if (_isLast) {
      _finish();
    } else {
      _go(_step + 1);
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
      _buildSkillsBeat(),
      _buildWorkoutBeat(),
      _buildDataBeat(),
      _buildRadarStep(),
      _buildAboutYou(),
      _buildReady(),
    ];
    final cta = _step == 0
        ? 'Get started'
        : _isLast
            ? (_saving ? 'Saving…' : 'Enter Forma')
            : 'Continue';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final incoming = (child.key as ValueKey<int>).value == _step;
                  final shift = incoming ? 0.07 : -0.05;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_dir >= 0 ? shift : -shift, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(key: ValueKey(_step), child: steps[_step]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: PillButton(label: cta, onTap: _saving ? null : _advance),
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
              onTap: () => _go(_step - 1),
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
              onTap: () => _go(_stepCount - 1),
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
    return const Stack(
      children: [
        Positioned(
          top: 40,
          left: -80,
          child: _AccentGlow(size: 320),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Rise(index: 0, child: _WelcomeHeadline()),
              SizedBox(height: 18),
              _Rise(
                index: 1,
                child: Text(
                  'Pick any calisthenics skill you want. Forma breaks it into '
                  'steps and builds personalized workouts that get you there.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Steps 1–3: the narrative beats ──

  Widget _buildSkillsBeat() {
    return const _NarrativeSlide(
      title: 'A roadmap for every calisthenic skill.',
      label: 'PULL-UP SKILL TREE',
      caption: 'Every skill is a foundation for the next. Reach your goals '
          'skill by skill.',
      visual: _SkillTreeBeat(),
    );
  }

  Widget _buildWorkoutBeat() {
    return const _NarrativeSlide(
      title: 'Your exercises adapt to your skill level.',
      label: "TODAY'S WORKOUT",
      caption: 'When you master a skill, the next one is seamlessly placed '
          'into your workout program.',
      visual: _LevelUpBeat(),
    );
  }

  Widget _buildDataBeat() {
    return const _NarrativeSlide(
      title: 'Your workouts adapt so you never start over.',
      label: 'PULL-UP REPS / SESSION',
      caption: 'Drop off for a while and Forma steps the exercise back, then '
          'builds you up again.',
      visual: _AdaptBeat(),
    );
  }

  // ── Step 4: archetype radar ──

  Widget _buildRadarStep() {
    final arch = _archetype;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHead(
            icon: Icons.center_focus_strong_rounded,
            pill: 'A LITTLE BIT ABOUT YOU',
            title: 'What is your aim?',
            sub: 'Drag the dot toward what matters most to you, or leave it '
                'centred for a balanced mix.',
          ),
          Expanded(
            // Centered explicitly — the step column is start-aligned, so the
            // shrink-wrapped radar cluster would otherwise sit at the left.
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Rise(
                    index: 3,
                    child: _RadarChart(
                      balanced: _balanced,
                      angleDeg: _angleDeg,
                      interactive: true,
                      onChanged: (balanced, angleDeg) => setState(() {
                        _balanced = balanced;
                        _angleDeg = angleDeg;
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Rise(
                    index: 4,
                    child: Column(
                      children: [
                        Text(
                          _balanced ? 'BALANCED' : 'YOUR ARCHETYPE',
                          style: _mono(
                            color: AppColors.textMuted,
                            size: 10,
                            spacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          arch.name,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color:
                                _balanced ? AppColors.textPrimary : arch.hue,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Two lines are always reserved: the descriptions vary
                        // in length, and letting the block reflow would shove
                        // the radar up and down as you drag.
                        SizedBox(
                          height: 38,
                          child: Text(
                            arch.sub,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.textMuted,
                            ),
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
    );
  }

  // ── Step 5: about you ──

  Widget _buildAboutYou() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHead(
            icon: Icons.person_rounded,
            pill: 'A LITTLE BIT ABOUT YOU',
            title: 'Your profile',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 18, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Rise(
                    index: 2,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Rise(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldCaption('GENDER'),
                        const SizedBox(height: 10),
                        _choiceRow(
                          _genderChoices,
                          _gender,
                          (id) => setState(
                              () => _gender = _gender == id ? null : id),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Rise(
                    index: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldCaption('HOW OFTEN DO YOU TRAIN?'),
                        const SizedBox(height: 10),
                        _choiceRow(
                          _freqChoices,
                          _freq,
                          (id) =>
                              setState(() => _freq = _freq == id ? null : id),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Sessions per week, any kind of training.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textMuted,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
                decoration: BoxDecoration(
                  color: selected == choices[i].id
                      ? AppColors.accentSoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == choices[i].id
                        ? AppColors.accentPrimary
                        : AppColors.divider,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  choices[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
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

  // ── Step 6: ready ──

  Widget _buildReady() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Positioned(top: 60, child: _AccentGlow(size: 300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Rise(
                index: 0,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.28),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _Rise(
                index: 2,
                child: Text(
                  'Welcome to Forma',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.08,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _Rise(
                index: 3,
                child: Text(
                  'Open your home and start your first workout. Forma builds '
                  'your program around your progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Entrance stagger ────────────────────────────────────────────────────────

/// Fades and lifts its child into place, [index] slots after the slide opens.
class _Rise extends StatefulWidget {
  final int index;
  final Widget child;

  const _Rise({required this.index, required this.child});

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  static const _riseMs = 500;
  static const _stepMs = 70;

  late final int _delayMs = 60 + widget.index * _stepMs;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _delayMs + _riseMs),
  )..forward();

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delayMs / (_delayMs + _riseMs),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// Soft accent bloom behind the welcome and ready screens.
class _AccentGlow extends StatelessWidget {
  final double size;

  const _AccentGlow({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accentPrimary.withValues(alpha: 0.16),
              AppColors.accentPrimary.withValues(alpha: 0),
            ],
            stops: const [0, 0.68],
          ),
        ),
      ),
    );
  }
}

// ── Step 0: the swapping headline ───────────────────────────────────────────

/// "From your first <skill> to the <skill>" — real moves only, cycling for as
/// long as the step is up.
class _WelcomeHeadline extends StatefulWidget {
  const _WelcomeHeadline();

  @override
  State<_WelcomeHeadline> createState() => _WelcomeHeadlineState();
}

class _WelcomeHeadlineState extends State<_WelcomeHeadline> {
  static const _pairs = [
    ('pull-up', 'muscle-up'),
    ('push-up', 'handstand'),
    ('squat', 'l-sit'),
  ];
  static const _style = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.16,
    color: AppColors.textPrimary,
  );

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// Cycles for as long as the step is on screen — it never settles.
  void _schedule() {
    _timer = Timer(
      Duration(milliseconds: _index == 0 ? 1250 : 1450),
      () {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % _pairs.length);
        _schedule();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _slot(String word) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      child: Text(
        word,
        key: ValueKey(word),
        style: _style.copyWith(color: AppColors.accentPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = _pairs[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('From your first', style: _style),
        _slot(pair.$1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('to the ', style: _style),
            Flexible(child: _slot(pair.$2)),
          ],
        ),
      ],
    );
  }
}

// ── Steps 1–3: narrative slide shell ────────────────────────────────────────

class _NarrativeSlide extends StatelessWidget {
  final String title;
  final String label;
  final String caption;
  final Widget visual;

  const _NarrativeSlide({
    required this.title,
    required this.label,
    required this.caption,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 6, 26, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rise(index: 1, child: Text(title, style: _titleStyle)),
          Expanded(
            child: _Rise(
              index: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 9),
                    child: Text(
                      label,
                      style: _mono(color: AppColors.textMuted, size: 10),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 18),
                          blurRadius: 34,
                          spreadRadius: -18,
                        ),
                      ],
                    ),
                    child: visual,
                  ),
                ],
              ),
            ),
          ),
          _Rise(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Text(caption, style: _captionStyle),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: the real skill-tree map, filling in ─────────────────────────────

/// The Pullups tree drawn by the same [SkillTreeMap] the Skills tab uses,
/// walked forward along one route (Weighted) a step at a time: the working
/// node's rep ring fills, rests a beat at full, and only then does the node
/// clear and the next take over — the rest keeps the hand-off from reading as
/// a jump.
class _SkillTreeBeat extends StatefulWidget {
  const _SkillTreeBeat();

  @override
  State<_SkillTreeBeat> createState() => _SkillTreeBeatState();
}

class _SkillTreeBeatState extends State<_SkillTreeBeat>
    with SingleTickerProviderStateMixin {
  static const _branchId = 'weighted';

  static const _slotMs = 520;

  /// Fraction of a slot spent filling; the remainder holds the ring at full so
  /// the node clearing lands as a beat rather than a jolt.
  static const _fillPortion = 0.74;

  /// Steps of the list kept on screen at once.
  static const _visibleRows = 3;
  static const _rowHeight = 34.0;

  static final List<String> _path =
      SkillCategoryCatalog.pullups.trainingPaths[_branchId]!;

  /// Every step of the route gets a slot, plus one that holds the finished
  /// tree before the loop starts over.
  static final int _slots = _path.length + 1;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _slots * _slotMs),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, ExerciseStatus> _progressAt(int cleared) => {
        for (var i = 0; i < cleared; i++) _path[i]: ExerciseStatus.mastered,
        if (cleared < _path.length) _path[cleared]: ExerciseStatus.active,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final raw = _controller.value * _slots;
        final cleared = raw.floor().clamp(0, _slots - 1);
        // The last slot is the hold: the tree simply sits on what it cleared.
        final fill = cleared >= _slots - 1
            ? 0.0
            : Curves.easeOutSine
                .transform(((raw - cleared) / _fillPortion).clamp(0.0, 1.0));

        final full = TreeVizModel.fromCategory(
          category: SkillCategoryCatalog.pullups,
          progressMap: _progressAt(cleared),
          activeBranchId: _branchId,
        );

        final map = SkillTreeMap(
          viz: TreeVizModel(
            spine: full.spine,
            branches: [
              // The whole fan stays drawn — it is what makes this read as a
              // roadmap — but only Weighted advances. Left alone, clearing the
              // foundation opens every branch's first step at once, and four
              // routes appear to progress together.
              for (final branch in full.branches)
                if (branch.id == _branchId)
                  branch
                else
                  TreeVizBranch(
                    id: branch.id,
                    label: branch.label,
                    states: List.filled(
                      branch.states.length,
                      TreeNodeState.locked,
                    ),
                    isActive: false,
                  ),
            ],
          ),
          fillPct: fill,
          maxHeight: 150,
        );

        return Column(
          children: [
            map,
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 6),
            _buildRouteList(cleared),
          ],
        );
      },
    );
  }

  /// The steps of the route, windowed to three rows and scrolled so the one
  /// being trained sits in the middle — it tracks the node the map is filling.
  Widget _buildRouteList(int cleared) {
    // A blank row leads the strip so the step being trained can sit in the
    // middle slot from the very first one, rather than starting at the top.
    final maxTop = (_path.length + 1 - _visibleRows).clamp(0, _path.length);
    final top = cleared.clamp(0, maxTop) * _rowHeight;

    return SizedBox(
      height: _rowHeight * _visibleRows,
      child: ShaderMask(
        // Rows dissolve at the window's edges instead of being cut off, so the
        // list reads as a strip moving past rather than a clipped box.
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, 0.16, 0.84, 1],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ClipRect(
          child: Stack(
            children: [
              AnimatedPositioned(
                // The loop restarting is a cut, not a step: gliding all the
                // way back would read as a rewind.
                duration: cleared == 0
                    ? Duration.zero
                    : const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: -top,
                child: Column(
                  children: [
                    const SizedBox(height: _rowHeight),
                    for (var i = 0; i < _path.length; i++)
                      _RouteStepRow(
                        name: ExerciseCatalog.findById(_path[i])?.name ?? '',
                        state: i < cleared
                            ? TreeNodeState.done
                            : i == cleared
                                ? TreeNodeState.cur
                                : TreeNodeState.locked,
                        height: _rowHeight,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One step of the route: a state dot, the exercise, and where it stands.
/// Everything animates so a step changing hands reads as a change, not a
/// repaint.
class _RouteStepRow extends StatelessWidget {
  final String name;
  final TreeNodeState state;
  final double height;

  const _RouteStepRow({
    required this.name,
    required this.state,
    required this.height,
  });

  Color get _color => switch (state) {
        TreeNodeState.done => AppColors.green,
        TreeNodeState.cur => AppColors.accentBright,
        _ => AppColors.textMuted,
      };

  String get _label => switch (state) {
        TreeNodeState.done => 'MASTERED',
        TreeNodeState.cur => 'ACTIVE',
        _ => 'LOCKED',
      };

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 260);
    final locked = state == TreeNodeState.locked;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                width: state == TreeNodeState.cur ? 9 : 7,
                height: state == TreeNodeState.cur ? 9 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locked ? AppColors.surface3 : _color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: locked ? FontWeight.w600 : FontWeight.w700,
                letterSpacing: -0.2,
                color: locked ? AppColors.textMuted : AppColors.textPrimary,
              ),
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 10),
          // The colour eases, the word itself cuts. Cross-fading the two
          // labels stacks them and renders as garbled text mid-swap.
          AnimatedDefaultTextStyle(
            duration: duration,
            style: _mono(
              color: locked ? AppColors.textMuted : _color,
              size: 9,
              spacing: 1,
            ),
            child: Text(_label),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: reps build until the exercise levels up ─────────────────────────

class _LevelUpBeat extends StatefulWidget {
  const _LevelUpBeat();

  @override
  State<_LevelUpBeat> createState() => _LevelUpBeatState();
}

class _LevelUpBeatState extends State<_LevelUpBeat> {
  /// Three real steps of the Pullups tree, in the order the program hands
  /// them out.
  static const _sequence = [
    'Assisted Pull Ups',
    'Pull Ups',
    'Close Grip Pull Ups',
  ];
  static const _startReps = 5;
  static const _targetReps = 8;

  int _index = 0;
  int _reps = _startReps;
  bool _levelling = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  /// One state change per call, then re-arms itself.
  void _tick() {
    final Duration delay;
    if (_levelling) {
      delay = const Duration(milliseconds: 1500);
    } else if (_reps >= _targetReps) {
      delay = const Duration(milliseconds: 600);
    } else {
      delay = const Duration(milliseconds: 640);
    }

    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        if (_levelling) {
          _levelling = false;
          _index = (_index + 1) % _sequence.length;
          _reps = _startReps;
        } else if (_reps >= _targetReps) {
          _levelling = true;
        } else {
          _reps++;
        }
      });
      _tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The card body and the level-up burst never share the frame — they swap,
    // so the burst can never read on top of legible text.
    return Column(
      children: [
        SizedBox(
          height: 76,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _levelling ? _buildBurst() : _buildCardBody(),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _sequence.length; i++) ...[
              if (i > 0)
                Container(
                  width: 16,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: i <= _index
                        ? AppColors.accentPrimary
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _index ? 10 : 8,
                height: i == _index ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? AppColors.accentPrimary
                      : i < _index
                          ? AppColors.green
                          : AppColors.surface2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCardBody() {
    final progress = (_reps - _startReps) / (_targetReps - _startReps);

    return Column(
      key: const ValueKey('card'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.28),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 23,
                color: AppColors.accentPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sequence[_index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '3 × ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                        child: Text(
                          '$_reps',
                          key: ValueKey(_reps),
                          style: _mono(
                            color: AppColors.accentPrimary,
                            size: 13,
                            spacing: 0,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Text(
                        ' reps',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.surface2,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accentPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBurst() {
    return Column(
      key: const ValueKey('burst'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.28),
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_upward_rounded,
            size: 24,
            color: AppColors.accentPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'LEVEL UP',
          style: _mono(
            color: AppColors.accentPrimary,
            size: 12.5,
            spacing: 2.5,
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Step 3: the reps graph drives the plan both ways ────────────────────────

class _AdaptBeat extends StatefulWidget {
  const _AdaptBeat();

  @override
  State<_AdaptBeat> createState() => _AdaptBeatState();
}

class _AdaptBeatState extends State<_AdaptBeat>
    with SingleTickerProviderStateMixin {
  static const _climbing = [40.0, 47, 53, 61, 67, 75, 83];
  static const _dropping = [83.0, 77, 65, 53, 43, 34, 27];

  static const _morphMs = 1150;
  static const _holdMs = 1500;
  static const _cycleMs = 2 * (_morphMs + _holdMs);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _cycleMs),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * _cycleMs;

        // climb → hold high → drop → hold low, then round again.
        final bool down;
        final double phase;
        if (t < _morphMs) {
          down = true;
          phase = t / _morphMs;
        } else if (t < _morphMs + _holdMs) {
          down = true;
          phase = 1;
        } else if (t < 2 * _morphMs + _holdMs) {
          down = false;
          phase = (t - _morphMs - _holdMs) / _morphMs;
        } else {
          down = false;
          phase = 1;
        }

        final eased = Curves.easeInOutQuad.transform(phase.clamp(0.0, 1.0));
        final from = down ? _climbing : _dropping;
        final to = down ? _dropping : _climbing;
        final values = [
          for (var i = 0; i < from.length; i++)
            from[i] + (to[i] - from[i]) * eased,
        ];

        final hue = down ? AppColors.amber : AppColors.green;
        final swapFrom = down ? 'Pull Ups' : 'Assisted Pull Ups';
        final swapTo = down ? 'Assisted Pull Ups' : 'Pull Ups';

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
              decoration: BoxDecoration(
                color: hue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: hue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    down
                        ? Icons.arrow_drop_down_rounded
                        : Icons.arrow_drop_up_rounded,
                    size: 16,
                    color: hue,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    down ? 'dropping' : 'climbing',
                    style: _mono(color: hue, size: 10, spacing: 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 94,
              width: double.infinity,
              child: CustomPaint(
                painter: _RepsGraphPainter(values: values, hue: hue),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.arrow_downward_rounded,
              size: 18,
              color: AppColors.surface3,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      swapFrom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      down
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 16,
                      color: hue,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      swapTo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RepsGraphPainter extends CustomPainter {
  final List<double> values;
  final Color hue;

  const _RepsGraphPainter({required this.values, required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 6.0;
    final baseline = size.height - 12;
    final span = (size.width - 2 * pad) / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(pad + i * span, baseline - (values[i] / 100) * (baseline - 6)),
    ];

    canvas.drawLine(
      Offset(pad, baseline),
      Offset(size.width - pad, baseline),
      Paint()
        ..color = AppColors.divider
        ..strokeWidth = 1,
    );

    final area = Path()..moveTo(points.first.dx, baseline);
    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }
    area
      ..lineTo(points.last.dx, baseline)
      ..close();
    canvas.drawPath(area, Paint()..color = hue.withValues(alpha: 0.12));

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = hue,
    );

    canvas.drawCircle(points.last, 4, Paint()..color = hue);
  }

  @override
  bool shouldRepaint(_RepsGraphPainter oldDelegate) =>
      oldDelegate.hue != hue || !listEquals(oldDelegate.values, values);
}

// ── Shared step header ──────────────────────────────────────────────────────

/// Accent pill, headline, and an optional supporting line — the shape the
/// question steps share.
class _StepHead extends StatelessWidget {
  final IconData icon;
  final String pill;
  final String title;
  final String? sub;

  const _StepHead({
    required this.icon,
    required this.pill,
    required this.title,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rise(
          index: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.accentPrimary),
                const SizedBox(width: 7),
                Text(pill, style: _mono(color: AppColors.accentPrimary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        _Rise(
          index: 1,
          child: Text(
            title,
            style: _titleStyle.copyWith(fontSize: 27, height: 1.08),
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 8),
          _Rise(index: 2, child: Text(sub!, style: _captionStyle)),
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
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
                  left: (width * value - 12).clamp(0.0, width - 24),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentPrimary,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80000000),
                          offset: Offset(0, 2),
                          blurRadius: 8,
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
  final void Function(bool balanced, double angleDeg)? onChanged;

  const _RadarChart({
    required this.balanced,
    required this.angleDeg,
    required this.interactive,
    this.onChanged,
  });

  void _handle(Offset local, double side) {
    final delta = local - Offset(side / 2, side / 2);
    if (delta.distance < _radius * 0.3) {
      onChanged!(true, angleDeg);
    } else {
      onChanged!(false, math.atan2(delta.dy, delta.dx) * 180 / math.pi);
    }
  }

  @override
  Widget build(BuildContext context) {
    const side = 2 * (_radius + _margin);
    final chart = SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
        painter: _RadarPainter(balanced: balanced, angleDeg: angleDeg),
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

  _RadarPainter({required this.balanced, required this.angleDeg});

  Offset _pt(Offset c, double deg, double r) {
    final rad = deg * math.pi / 180;
    return c + Offset(math.cos(rad) * r, math.sin(rad) * r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const radius = _RadarChart._radius;
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
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = hue.withValues(alpha: 0.55),
      );
    }

    // Archetype anchor dots.
    for (var i = 0; i < _archetypes.length; i++) {
      final on = !balanced && _archetypes[i] == sel;
      canvas.drawCircle(
        _pt(c, _archetypes[i].dir, radius * 0.92),
        on ? 4 : 3,
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
        9,
        Paint()..color = AppColors.accentPrimary.withValues(alpha: 0.22),
      );
    }
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
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
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: axis.hue.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = _pt(c, axis.deg, radius + 22);
      painter.paint(
        canvas,
        pos - Offset(painter.width / 2, painter.height / 2),
      );
    }

    // Drag dot.
    final dot = balanced ? c : _pt(c, angleDeg, radius * 0.92);
    canvas.drawCircle(dot, 14, Paint()..color = hue.withValues(alpha: 0.25));
    canvas.drawCircle(dot, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      dot,
      8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = hue,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) {
    return oldDelegate.balanced != balanced ||
        oldDelegate.angleDeg != angleDeg;
  }
}
