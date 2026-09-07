import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/services/membership_service.dart';
import 'membership_lock_dock.dart';
import 'membership_scope.dart';

/// Wraps a tab's index page: while the user is locked out, the page stays
/// visible — dimmed, inert — under the lock dock. Nothing to dismiss;
/// the tab bar keeps working, and Profile is never wrapped.
///
/// [hasProgram] keeps the gate off until a program exists: the empty tabs'
/// "Create my program" has to stay tappable, since building the program is
/// how the user reaches the paywall in the first place. It is a listenable
/// because the gate lives inside a tab's navigator route, which the shell's
/// own rebuilds never reach.
class MembershipGate extends StatelessWidget {
  final ValueListenable<bool> hasProgram;
  final MembershipService service;
  final Widget child;

  const MembershipGate({
    super.key,
    required this.hasProgram,
    required this.service,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final membership = MembershipScope.maybeOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: hasProgram,
      builder: (context, hasProgram, _) {
        final locked = hasProgram && membership != null && membership.locked;
        if (!locked) return child;

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
      },
    );
  }
}
