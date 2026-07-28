// TEMPORARY dev entrypoint — renders the onboarding flow on its own so it can
// be reviewed without signing in. Delete once the flow is signed off.
import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/onboarding/onboarding_view.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPrimary,
        brightness: Brightness.dark,
        surface: AppColors.bg,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: NoSplash.splashFactory,
    ),
    home: OnboardingView(onFinished: () {}),
  ));
}
