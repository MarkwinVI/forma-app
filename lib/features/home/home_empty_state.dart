import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';

/// First-run home screen shown while the user has no training program yet.
class HomeEmptyState extends StatelessWidget {
  final VoidCallback onBuildProgram;
  final VoidCallback onOpenSettings;

  const HomeEmptyState({
    super.key,
    required this.onBuildProgram,
    required this.onOpenSettings,
  });

  void _openHowItWorks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HowFormaWorksView(onBuildProgram: onBuildProgram),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Welcome',
            actions: [
              HeaderCircleButton(
                icon: Icons.settings_outlined,
                onTap: onOpenSettings,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              'Let’s build the program that gets you there.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _SetupCard(onBuildProgram: onBuildProgram),
                const SizedBox(height: 12),
                _HowItWorksRow(onTap: () => _openHowItWorks(context)),
                const SectionHeader(title: 'Getting started'),
                _GettingStartedChecklist(onBuildProgram: onBuildProgram),
                const SectionHeader(title: 'Your progress'),
                const _LockedProgressCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero: set up your training program ──────────────────────

class _SetupCard extends StatelessWidget {
  final VoidCallback onBuildProgram;

  const _SetupCard({
    required this.onBuildProgram,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set up your training program',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.48,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell Forma your goals and schedule. We’ll build a balanced '
            'program across every movement pattern — and adapt it as you '
            'progress.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'Build my program',
            icon: Icons.chevron_right_rounded,
            trailingIcon: true,
            onTap: onBuildProgram,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                'Takes about 2 minutes',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── "How Forma works" row ───────────────────────────────────

class _HowItWorksRow extends StatelessWidget {
  final VoidCallback onTap;

  const _HowItWorksRow({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: const Row(
        children: [
          IconTile(icon: Icons.help_outline_rounded, tint: true),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Forma works',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'A 60-second tour of the training program',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Getting-started checklist ───────────────────────────────

class _GettingStartedChecklist extends StatelessWidget {
  final VoidCallback onBuildProgram;

  const _GettingStartedChecklist({
    required this.onBuildProgram,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: 'Set up your training program',
        sub: 'Pick goals and a schedule',
        active: true,
      ),
      (
        label: 'Complete your first workout',
        sub: 'Log your opening session',
        active: false,
      ),
      (
        label: 'Reach your first skill level-up',
        sub: 'Hit a target to rank a skill',
        active: false,
      ),
    ];

    return SurfaceCard(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your first 3 steps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '0 / 3',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          for (final item in items)
            _ChecklistRow(
              label: item.label,
              sub: item.sub,
              active: item.active,
              onTap: item.active ? onBuildProgram : null,
            ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool active;
  final VoidCallback? onTap;

  const _ChecklistRow({
    required this.label,
    required this.sub,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Opacity(
        opacity: active ? 1 : 0.5,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.accentSoft : Colors.transparent,
                border: Border.all(
                  width: 2,
                  color: active
                      ? AppColors.accentPrimary
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
              alignment: Alignment.center,
              child: active
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.accentPrimary,
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Pressable(onTap: onTap, child: row);
  }
}

// ── Locked progress preview ─────────────────────────────────

class _LockedProgressCard extends StatelessWidget {
  const _LockedProgressCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness level',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: -1.26,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Locked',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              value: 0,
              minHeight: 6,
              backgroundColor: AppColors.surface2,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Complete your first workout and Forma starts tracking '
                    'each skill — building the character sheet that maps '
                    'your whole body.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
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
}

// ── "How Forma works" walkthrough ───────────────────────────

class HowFormaWorksView extends StatelessWidget {
  final VoidCallback onBuildProgram;

  const HowFormaWorksView({
    super.key,
    required this.onBuildProgram,
  });

  static const _steps = [
    (
      title: 'Tell Forma your goals',
      body: 'Pick the skills you’re chasing — your first pull-up, a '
          'handstand, a muscle-up — and how many days a week you train.',
      icon: Icons.sports_gymnastics_rounded,
    ),
    (
      title: 'We build your split',
      body: 'Forma assembles a balanced program across all eight movement '
          'patterns — push, pull, hinge, squat, core and skill work '
          '— with the right progression in each.',
      icon: Icons.fitness_center_rounded,
    ),
    (
      title: 'Train and log',
      body: 'Sessions roll forward, never date-locked — miss one and it '
          'slots into your next training day. Log your sets and Forma tracks '
          'every rep.',
      icon: Icons.rowing_rounded,
    ),
    (
      title: 'Skills level up',
      body: 'Hit your targets and each skill ranks up — Pull-up Lv 6, '
          'Handstand Lv 4 — filling out a character sheet that maps '
          'your whole body.',
      icon: Icons.military_tech_outlined,
    ),
    (
      title: 'It adapts as you grow',
      body: 'Stall on a movement and Forma eases off and rebuilds. Clear a '
          'progression and the next exercise in that path unlocks '
          'automatically.',
      icon: Icons.autorenew_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Forma works',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'A 60-second tour',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 44),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 10, 2, 18),
              child: Text(
                'Forma turns your goals into a structured calisthenics '
                'program — and levels you up like a skill tree as you '
                'train.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            for (var index = 0; index < _steps.length; index++)
              _WalkthroughStep(
                number: index + 1,
                title: _steps[index].title,
                body: _steps[index].body,
                icon: _steps[index].icon,
                isLast: index == _steps.length - 1,
              ),
            const SizedBox(height: 26),
            PillButton(
              label: 'Build my program',
              icon: Icons.chevron_right_rounded,
              trailingIcon: true,
              onTap: () {
                Navigator.of(context).pop();
                onBuildProgram();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughStep extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final IconData icon;
  final bool isLast;

  const _WalkthroughStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                IconTile(icon: icon, size: 44, tint: true),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 0$number',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
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
