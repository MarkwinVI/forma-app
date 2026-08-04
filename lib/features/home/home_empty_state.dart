import 'package:flutter/material.dart';

import '../../core/widgets/no_program_state.dart';
import '../../core/widgets/type_led.dart';

/// First-run Train tab, shown while the user has no training program yet.
/// This screen says what will be here once setup is done, and its CTA opens
/// the setup wizard directly.
class HomeEmptyState extends StatelessWidget {
  /// Opens the program setup wizard.
  final VoidCallback onCreateProgram;

  const HomeEmptyState({super.key, required this.onCreateProgram});

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return NoProgramState(
      title: 'Your workouts will appear here',
      sub: 'Create your program to see what to train today and what’s '
          'planned for the rest of your week.',
      onCreateProgram: onCreateProgram,
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
