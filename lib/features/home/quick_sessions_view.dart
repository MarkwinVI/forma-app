import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import 'quick_session_intro_view.dart';
import 'quick_sessions.dart';
import 'widgets/session_photo.dart';

/// "See all": every quick session, filtered by the chips and grouped by
/// what it is for — and, under them, the way to train without a plan at
/// all: a blank workout.
class QuickSessionsView extends StatefulWidget {
  /// The program session still planned for today, for the intro's note.
  final String? plannedToday;

  /// Starts an empty workout to fill in as it goes.
  final VoidCallback onBlankWorkout;

  const QuickSessionsView({
    super.key,
    this.plannedToday,
    required this.onBlankWorkout,
  });

  @override
  State<QuickSessionsView> createState() => _QuickSessionsViewState();
}

class _QuickSessionsViewState extends State<QuickSessionsView> {
  var _filter = QuickSessionFilter.all;

  void _open(QuickSession session) {
    showQuickSessionIntro(
      context,
      session: session,
      plannedToday: widget.plannedToday,
      source: 'sessions',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [
      for (final session in QuickSessions.all)
        if (session.matches(_filter)) session,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Clears the tab bar the page sits behind.
          padding: EdgeInsets.only(
            top: 6,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    semanticLabel: 'Back',
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sessions',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.9,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Short extras for the days and moments between your program '
                'workouts.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                itemCount: QuickSessionFilter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = QuickSessionFilter.values[index];
                  return _Chip(
                    label: filter.label,
                    selected: filter == _filter,
                    onTap: () => setState(() => _filter = filter),
                  );
                },
              ),
            ),
            for (final group in QuickSessionGroup.values)
              if (sessions.any((session) => session.group == group)) ...[
                _GroupHeader(group.label),
                for (final session in sessions)
                  if (session.group == group)
                    _SessionRow(session: session, onTap: () => _open(session)),
              ],
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Text(
                  'Nothing here yet.',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
              ),
            // Not a session: no plan, no clock. It sits under the list on
            // "All", where someone looking for something else ends up.
            if (_filter == QuickSessionFilter.all) ...[
              const _GroupHeader('YOUR OWN'),
              _BlankWorkoutRow(onTap: widget.onBlankWorkout),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4F5F8) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF08090C) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;

  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Text(label, style: monoStyle(size: 11, letterSpacing: 1.76)),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final QuickSession session;
  final VoidCallback onTap;

  const _SessionRow({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '${session.name}, ${session.minutes} minutes',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: SessionPhoto(
                image: session.image,
                focusY: session.imageFocusY,
                borderRadius: BorderRadius.circular(18),
                thumbnail: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RowText(title: session.name, sub: session.summary),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                session.durationLabel,
                style: monoStyle(
                  size: 11,
                  letterSpacing: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Blank workout": the same row shape as a session, with a plus where the
/// photo would be and a chevron where the duration would be — it has none.
class _BlankWorkoutRow extends StatelessWidget {
  final VoidCallback onTap;

  const _BlankWorkoutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Blank workout, add exercises as you go',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: _RowText(
                title: 'Blank workout',
                sub: 'Add exercises as you go',
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  final String title;
  final String sub;

  const _RowText({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.17,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
