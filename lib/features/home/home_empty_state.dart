import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';

/// First-run Train tab shown while the user has no training program yet.
/// Program setup itself lives on the Program tab — this screen just points
/// the way and explains how Forma works.
class HomeEmptyState extends StatelessWidget {
  /// Sends the user to the Program tab, where setup lives.
  final VoidCallback onGoToProgram;
  final VoidCallback onOpenSettings;

  const HomeEmptyState({
    super.key,
    required this.onGoToProgram,
    required this.onOpenSettings,
  });

  void _openHowItWorks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HowFormaWorksView(onGoToProgram: onGoToProgram),
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
                SurfaceCard(
                  onTap: onGoToProgram,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: const Row(
                    children: [
                      IconTile(
                        icon: Icons.event_note_rounded,
                        size: 44,
                        tint: true,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No program yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Head to the Program tab to set up your '
                              'training program — it takes about 2 minutes.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _HowItWorksRow(onTap: () => _openHowItWorks(context)),
              ],
            ),
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
            child: Text(
              'How Forma works',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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

// ── "How Forma works" walkthrough ───────────────────────────

class HowFormaWorksView extends StatelessWidget {
  final VoidCallback onGoToProgram;

  const HowFormaWorksView({
    super.key,
    required this.onGoToProgram,
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
        title: const Text(
          'How Forma works',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
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
                onGoToProgram();
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
