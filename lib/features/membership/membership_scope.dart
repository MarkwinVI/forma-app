import 'package:flutter/widgets.dart';

import '../../data/models/membership_model.dart';
import '../../data/services/membership_service.dart';

/// Hands the live membership down the tree. Anything that reads it
/// rebuilds when it changes — a purchase landing lifts every lock at once.
class MembershipScope extends StatelessWidget {
  final MembershipService service;
  final Widget child;

  const MembershipScope({
    super.key,
    required this.service,
    required this.child,
  });

  /// The membership in scope, or the service's own when no scope is above
  /// (a screen pushed on the root navigator).
  static Membership? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_MembershipInherited>();
    return scope?.membership ?? MembershipService.instance.current;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service.notifier,
      builder: (context, _) => _MembershipInherited(
        membership: service.current,
        child: child,
      ),
    );
  }
}

class _MembershipInherited extends InheritedWidget {
  final Membership? membership;

  const _MembershipInherited({
    required this.membership,
    required super.child,
  });

  @override
  bool updateShouldNotify(_MembershipInherited oldWidget) =>
      oldWidget.membership != membership;
}
