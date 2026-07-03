import 'package:flutter/material.dart';

const _optionsBg = Color(0xFF111114);
const _optionsCard = Color(0xFF1C1C20);
const _optionsBorder = Color(0xFF323237);
const _optionsText = Color(0xFFF5F5F7);
const _optionsTextSecondary = Color(0xFF9C9CA3);
const _optionsOrange = Color(0xFFFC5200);

class AlternateWorkoutOptionsView extends StatelessWidget {
  final VoidCallback onOpenBlankWorkout;

  const AlternateWorkoutOptionsView({
    super.key,
    required this.onOpenBlankWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _optionsBg,
      appBar: AppBar(
        backgroundColor: _optionsBg,
        surfaceTintColor: _optionsBg,
        elevation: 0,
        title: const Text(
          'Train Something Else',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _optionsText,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Not feeling the recommended workout, try something else to keep things fresh',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: _optionsTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenBlankWorkout,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: _optionsCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _optionsBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _optionsOrange.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.add_rounded,
                              color: _optionsOrange,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Blank workout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _optionsText,
                                    letterSpacing: -0.15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add exercises as you go',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: _optionsTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _optionsTextSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
