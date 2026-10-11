import 'package:flutter/material.dart';

/// Pull down anywhere and the keyboard goes away — the Messages gesture,
/// app-wide (the app's builder in main.dart installs it over every page).
///
/// A raw pointer listener, so it never competes with the scroll or tap
/// underneath: the list still scrolls, the button still fires, and the
/// keyboard just leaves alongside. A drag that starts inside the focused
/// field is the field's own — a text selection, a long note scrolling —
/// and is left alone.
class KeyboardDismissOnSwipeDown extends StatefulWidget {
  final Widget child;

  const KeyboardDismissOnSwipeDown({super.key, required this.child});

  @override
  State<KeyboardDismissOnSwipeDown> createState() =>
      _KeyboardDismissOnSwipeDownState();
}

class _KeyboardDismissOnSwipeDownState
    extends State<KeyboardDismissOnSwipeDown> {
  /// How far down a finger travels before it counts as a pull.
  static const _pull = 24.0;

  /// Where the finger went down, while a pull from there would count.
  Offset? _down;

  void _onPointerDown(PointerDownEvent event) {
    _down = null;
    if (MediaQuery.viewInsetsOf(context).bottom == 0) return;
    final focused =
        FocusManager.instance.primaryFocus?.context?.findRenderObject();
    if (focused is RenderBox && focused.attached) {
      final bounds = focused.localToGlobal(Offset.zero) & focused.size;
      if (bounds.contains(event.position)) return;
    }
    _down = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final down = _down;
    if (down == null) return;
    final delta = event.position - down;
    if (delta.dy < _pull || delta.dy.abs() <= delta.dx.abs()) return;
    _down = null;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onPointerEnd(PointerEvent _) => _down = null;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: widget.child,
    );
  }
}
