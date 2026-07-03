import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Placeholder destination for "Build my program".
/// The real program creation flow doesn't exist yet.
class ProgramSetupView extends StatelessWidget {
  const ProgramSetupView({super.key});

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
          'Build your program',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Program setup is coming soon.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
