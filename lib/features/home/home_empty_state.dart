import 'package:flutter/material.dart';

import '../../core/widgets/no_program_state.dart';
import '../../core/widgets/type_led.dart';

/// First-run Train tab, shown while the user has no training program yet.
/// Setup itself lives on the Program tab; this screen says what will be here
/// once it is done, and offers the same way to get there.
class HomeEmptyState extends StatelessWidget {
  /// Sends the user to the Program tab, where setup lives.
  final VoidCallback onGoToProgram;

  const HomeEmptyState({super.key, required this.onGoToProgram});

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return NoProgramState(
      title: 'Your workouts will appear here',
      sub: 'Create your program to see what to train today and what’s '
          'planned for the rest of your week.',
      onCreateProgram: onGoToProgram,
      children: [
        // A week with nothing in it: every letter reads the same, so no day
        // looks already chosen.
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Row(
            children: [
              for (final letter in _weekdayLetters)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Text(
                      letter,
                      textAlign: TextAlign.center,
                      style: monoStyle(size: 13, letterSpacing: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const TypeSectionLabel("Today's session", top: 24),
        for (var i = 0; i < 4; i++)
          GhostRow(name: 'Exercise', last: i == 3),
      ],
    );
  }
}
