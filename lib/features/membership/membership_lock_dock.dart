import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/membership_model.dart';
import '../../data/services/membership_service.dart';
import 'membership_copy.dart';
import 'paywall_sheet.dart';

/// The lock message pinned above the tab bar on a locked tab: a lock, the
/// state's title and line, the one button, and the quiet terms under it.
/// The same dock on every locked tab — one gate across the app.
class MembershipLockDock extends StatefulWidget {
  final Membership membership;
  final MembershipService service;

  const MembershipLockDock({
    super.key,
    required this.membership,
    required this.service,
  });

  @override
  State<MembershipLockDock> createState() => _MembershipLockDockState();
}

class _MembershipLockDockState extends State<MembershipLockDock> {
  List<MembershipPlan>? _plans;

  @override
  void initState() {
    super.initState();
    // Prices land when they land; the copy reads fine without them.
    widget.service.plans().then((plans) {
      if (mounted) setState(() => _plans = plans);
    }, onError: (Object _) {});
  }

  Future<void> _open() => showPaywallSheet(
        context,
        service: widget.service,
        source: 'lock_dock',
      );

  @override
  Widget build(BuildContext context) {
    final copy = MembershipLockCopy.forMembership(widget.membership, _plans);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, bottomInset + 18),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  copy.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            copy.body,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: copy.cta(_plans),
            radius: 14,
            onTap: _open,
          ),
          const SizedBox(height: 10),
          Text(
            copy.sub(_plans),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
