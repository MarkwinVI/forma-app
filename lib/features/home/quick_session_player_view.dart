import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/services/analytics_service.dart';
import '../progress/widgets/skill_tree_confirm.dart';
import 'quick_session_player.dart';
import 'quick_sessions.dart';
import 'widgets/session_photo.dart';
import 'widgets/week_widgets.dart';

/// Runs a quick session over the whole screen. Resolves true when the
/// session was gone through to its end, false or null when it was left.
Future<bool?> showQuickSessionPlayer(
  BuildContext context, {
  required QuickSession session,
}) {
  AnalyticsService.screen('quick_session_player');
  AnalyticsService.capture('quick_session_started', properties: {
    'session': session.id,
  });
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      builder: (_) => QuickSessionPlayerView(session: session),
    ),
  );
}

/// A quick session, followed rather than logged: the move, a clock that
/// runs it down and moves on by itself, and what comes next. A counted
/// move shows its reps where the clock was and waits for "Done".
///
/// Nothing here is typed in and nothing is saved: the player leads, and
/// the session leaves no trace in the program.
class QuickSessionPlayerView extends StatefulWidget {
  final QuickSession session;

  const QuickSessionPlayerView({super.key, required this.session});

  @override
  State<QuickSessionPlayerView> createState() => _QuickSessionPlayerViewState();
}

class _QuickSessionPlayerViewState extends State<QuickSessionPlayerView>
    with WidgetsBindingObserver {
  static const _tick = Duration(milliseconds: 100);

  late final QuickSessionPlayer _player;
  Timer? _timer;
  int _seenTicks = 0;

  QuickSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _player = QuickSessionPlayer(_session, onCue: _cue)
      ..addListener(_onPlayer);
    WidgetsBinding.instance.addObserver(this);
    _setWakelock(true);
    // A timer's tick count includes the ticks it was too busy to fire, so
    // a slow frame does not slow the session's clock.
    _timer = Timer.periodic(_tick, (timer) {
      _player.advance(_tick * (timer.tick - _seenTicks));
      _seenTicks = timer.tick;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _player
      ..removeListener(_onPlayer)
      ..dispose();
    _setWakelock(false);
    super.dispose();
  }

  /// Leaving the app holds the session where it is; the clock does not run
  /// on behind a locked screen or another app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        !_player.paused &&
        !_player.isFinished) {
      _player.togglePause();
    }
  }

  void _onPlayer() {
    if (!mounted) return;
    if (_player.isFinished && _timer != null) {
      _timer?.cancel();
      _timer = null;
      _setWakelock(false);
      AnalyticsService.capture('quick_session_finished', properties: {
        'session': _session.id,
        'seconds': _player.active.inSeconds,
      });
    }
    setState(() {});
  }

  /// The phone is on the floor by now: each change is felt and heard.
  void _cue(QuickSessionCue cue) {
    switch (cue) {
      case QuickSessionCue.tick:
        HapticFeedback.selectionClick();
      case QuickSessionCue.go:
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
      case QuickSessionCue.rest:
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      case QuickSessionCue.finished:
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Guarded like the live workout's: the plugin needs a platform channel,
  /// and where there is none (tests) the session runs on without it.
  static void _setWakelock(bool on) {
    try {
      final future = on ? WakelockPlus.enable() : WakelockPlus.disable();
      future.catchError((_) {});
    } catch (_) {
      // Not available here; the session does not depend on it.
    }
  }

  Future<void> _close() async {
    final wasPaused = _player.paused;
    if (!wasPaused) _player.togglePause();
    final leave = await showSkillTreeConfirm(
      context,
      icon: Icons.close_rounded,
      caution: false,
      title: 'End this session?',
      body: const [
        TextSpan(
          text: 'A quick session isn’t saved, so you lose only your '
              'place in it.',
        ),
      ],
      confirmLabel: 'End session',
    );
    if (!mounted) return;
    if (!leave) {
      if (!wasPaused && _player.paused) _player.togglePause();
      return;
    }
    AnalyticsService.capture('quick_session_ended_early', properties: {
      'session': _session.id,
      'step': _player.index + 1,
      'steps': _player.steps.length,
    });
    Navigator.of(context).pop(false);
  }

  // ── Words ─────────────────────────────────────────────────────────

  String _clockText(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  /// "MOVE 3 OF 5", with the round when there is more than one.
  String _position(QuickSessionStep step) {
    final at = _session.moves.indexOf(step.move) + 1;
    final move = 'MOVE $at OF ${_session.moves.length}';
    return step.rounds > 1
        ? '$move · ROUND ${step.round} OF ${step.rounds}'
        : move;
  }

  /// What the pause before a step is: the first has nothing to rest from,
  /// and the second side of a move is a change of position.
  String _leadInLabel(QuickSessionStep step) {
    if (_player.index == 0) return 'GET READY';
    if (step.side == 'RIGHT SIDE') return 'SWITCH SIDES';
    return _session.restSeconds > 0 ? 'REST' : 'UP NEXT';
  }

  String _minutes(Duration time) {
    final minutes = (time.inSeconds / 60).round();
    return minutes < 1 ? 'Under a minute' : '$minutes min';
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _player.isFinished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: _player.isFinished ? _finished(context) : _running(context),
        ),
      ),
    );
  }

  Widget _finished(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          WeekDoneBody(
            title: 'Session done',
            line: '${_session.name} · ${_minutes(_player.active)}',
          ),
          const Spacer(flex: 2),
          Pressable(
            onTap: () => Navigator.of(context).pop(true),
            semanticLabel: 'Done',
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF08090C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _running(BuildContext context) {
    final step = _player.step;
    final next = _player.next;
    final leadIn = _player.phase == QuickSessionPhase.leadIn;
    final counted = !leadIn && !step.isTimed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
          child: Row(
            children: [
              Pressable(
                onTap: _close,
                semanticLabel: 'End session',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _segments()),
            ],
          ),
        ),
        // Where the move's loop plays. Until the clips exist, the
        // session's photo stands in for every move.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: SessionPhoto(
                image: _session.image,
                focusY: _session.imageFocusY,
                thumbnail: true,
                borderRadius: BorderRadius.circular(30),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: step.side == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.all(14),
                          child: PhotoPill(step.side!),
                        ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            leadIn ? _leadInLabel(step) : _position(step),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: monoStyle(
              size: 11,
              letterSpacing: 1.76,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            step.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.08,
              height: 1.04,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Semantics(
            liveRegion: counted,
            label: counted
                ? '${step.move.reps} reps'
                : '${_player.secondsLeft} seconds left',
            child: ExcludeSemantics(
              child: Text(
                counted
                    ? '${step.move.reps}×'
                    : _clockText(_player.secondsLeft),
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 84,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  height: 1,
                  // The pause before a step reads quieter than the step.
                  color:
                      leadIn ? AppColors.textMuted : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.surface3),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _player.progress,
                    child: ColoredBox(
                      // White, not blue: blue is the program's.
                      color: leadIn
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leadIn
                    ? 'THEN'
                    : next == null
                        ? 'LAST MOVE'
                        : 'NEXT',
                style: monoStyle(size: 10, letterSpacing: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                leadIn
                    ? step.move.amount
                    : next == null
                        ? 'Then you’re done'
                        : next.side == 'RIGHT SIDE'
                            ? '${next.name}, right side'
                            : next.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              _RoundButton(
                icon: Icons.skip_previous_rounded,
                label: 'Previous move',
                onTap: _player.previous,
              ),
              const SizedBox(width: 10),
              Expanded(child: _mainButton(counted)),
              const SizedBox(width: 10),
              _RoundButton(
                icon: Icons.skip_next_rounded,
                label: 'Skip',
                onTap: _player.skip,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// One segment per step: behind in green, this one filling in white.
  Widget _segments() {
    final steps = _player.steps.length;
    final working = _player.phase == QuickSessionPhase.work;
    return Semantics(
      label: 'Step ${_player.index + 1} of $steps',
      child: Row(
        children: [
          for (var i = 0; i < steps; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: i < _player.index
                            ? AppColors.green
                            : AppColors.surface3,
                      ),
                      if (i == _player.index && working)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          // A counted step has no clock to fill it.
                          widthFactor:
                              _player.step.isTimed ? _player.progress : 1,
                          child: const ColoredBox(color: AppColors.textPrimary),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "Done" on a counted move — the one tap a session asks for — and
  /// pause or resume everywhere else.
  Widget _mainButton(bool counted) {
    final paused = _player.paused;
    final done = counted && !paused;
    final label = done
        ? 'Done'
        : paused
            ? 'Resume'
            : 'Pause';
    return Pressable(
      onTap: done ? _player.done : _player.togglePause,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done || paused ? const Color(0xFFF4F5F8) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: done || paused
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!done) ...[
              Icon(
                paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
                color: paused ? const Color(0xFF08090C) : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color:
                    done || paused ? const Color(0xFF08090C) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}
