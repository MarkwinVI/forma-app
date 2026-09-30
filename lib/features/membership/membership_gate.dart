import 'package:flutter/material.dart';

import '../../data/services/membership_service.dart';
import 'membership_lock_dock.dart';
import 'membership_scope.dart';

/// Wraps a tab's index page: while the user is locked out, the page stays
/// visible — dimmed, inert — under the lock dock. Nothing to dismiss;
/// the tab bar keeps working, and Profile is never wrapped.
///
/// The tabs are only reached once a program exists — the setup wizard, and
/// its paywall, come first — so the lock is the membership alone.
class MembershipGate extends StatelessWidget {
  final MembershipService service;
  final Widget child;

  const MembershipGate({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final membership = MembershipScope.maybeOf(context);
    if (membership == null || !membership.locked) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Opacity(opacity: 0.55, child: child),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: MembershipLockDock(
            membership: membership,
            service: service,
          ),
        ),
      ],
    );
  }
}
