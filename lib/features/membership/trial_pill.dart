import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/membership_model.dart';
import 'membership_scope.dart';

/// "FREE TRIAL · 6 DAYS LEFT" under the Train tab's title while the trial
/// runs. Nothing at all for a subscriber, so the tab reads exactly the same
/// once the trial has converted.
class TrialPill extends StatelessWidget {
  final DateTime now;

  const TrialPill({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final membership = MembershipScope.maybeOf(context);
    if (membership == null || membership.state != MembershipState.trialing) {
      return const SizedBox.shrink();
    }
    final days = membership.daysLeft(now);
    final left = days == 1 ? '1 DAY LEFT' : '$days DAYS LEFT';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_rounded,
                size: 11,
                color: AppColors.accentPrimary,
              ),
              const SizedBox(width: 5),
              Text(
                'FREE TRIAL · $left',
                style: monoStyle(
                  size: 10,
                  color: AppColors.accentPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
