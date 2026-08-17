import 'package:flutter/widgets.dart';

/// Fired by the shell when the user re-taps the tab they are already on and
/// its navigator has nothing left to pop. Pages that keep "deeper" state
/// inside a single widget (a focused tree on the skill wheel, say) rather
/// than on the navigator stack listen and unwind themselves. Reports whether
/// anyone actually had something to unwind so the shell can otherwise fall
/// back to scrolling to the top.
class TabResetNotifier extends ChangeNotifier {
  bool _handled = false;

  /// True while a listener claims the reset. Read by [fire], set by
  /// listeners via [markHandled].
  void markHandled() => _handled = true;

  /// Notifies listeners; returns whether any of them handled the reset.
  bool fire() {
    _handled = false;
    notifyListeners();
    return _handled;
  }
}

/// Hands each tab its [TabResetNotifier].
class TabReset extends InheritedWidget {
  final TabResetNotifier notifier;

  const TabReset({
    super.key,
    required this.notifier,
    required super.child,
  });

  static TabResetNotifier? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabReset>()?.notifier;

  @override
  bool updateShouldNotify(TabReset oldWidget) => notifier != oldWidget.notifier;
}
