import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Snapshot of the workout shown on the iOS Live Activity. Timers travel as
/// timestamps: the lock screen counts the workout clock up and the rest
/// clock down natively, so the app only pushes an update when something
/// discrete changes (set ticked, rest started, pause, …).
class LiveWorkoutActivityState {
  final String exerciseName;
  final int setNumber;
  final int totalSets;
  final String repGoalLabel;
  final DateTime workoutStartedAt;
  final bool isPaused;
  final String? pausedElapsedLabel;
  final DateTime? restStartedAt;
  final DateTime? restEndsAt;

  /// Every set of every exercise is ticked; the activity says so instead
  /// of asking for a next set.
  final bool allSetsCompleted;

  /// A set was just ticked from the activity's own button. For a moment
  /// the activity keeps showing that set, with its check filled green, so
  /// the tap visibly landed — then the next update moves it on.
  final bool setJustCompleted;

  const LiveWorkoutActivityState({
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.repGoalLabel,
    required this.workoutStartedAt,
    required this.isPaused,
    this.pausedElapsedLabel,
    this.restStartedAt,
    this.restEndsAt,
    this.allSetsCompleted = false,
    this.setJustCompleted = false,
  });

  Map<String, Object?> toMap() => {
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'totalSets': totalSets,
        'repGoalLabel': repGoalLabel,
        'workoutStartedAtMs': workoutStartedAt.millisecondsSinceEpoch,
        'isPaused': isPaused,
        'pausedElapsedLabel': pausedElapsedLabel,
        'restStartedAtMs': restStartedAt?.millisecondsSinceEpoch,
        'restEndsAtMs': restEndsAt?.millisecondsSinceEpoch,
        'allSetsCompleted': allSetsCompleted,
        'setJustCompleted': setJustCompleted,
      };
}

/// Talks to the native Live Activity (iOS 16.2+) over a method channel.
/// Everything is fire-and-forget and failure-tolerant: a workout must never
/// notice that the lock screen could not be updated.
class LiveActivityService {
  LiveActivityService._() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static final LiveActivityService instance = LiveActivityService._();

  static const _channel = MethodChannel('forma/live_activity');

  /// Called with the action id when a lock-screen button is tapped
  /// (completeSet, restPlus15, restMinus15, skipRest).
  void Function(String action)? onAction;

  bool _started = false;

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'onAction') {
      final action = call.arguments;
      if (action is String) onAction?.call(action);
    }
    return null;
  }

  Future<bool> isSupported() async {
    if (!_isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> start(
    String sessionLabel,
    LiveWorkoutActivityState state,
  ) async {
    if (!await isSupported()) return;
    try {
      await _channel.invokeMethod('start', {
        'sessionLabel': sessionLabel,
        ...state.toMap(),
      });
      _started = true;
    } catch (error) {
      debugPrint('Live Activity start failed: $error');
    }
  }

  Future<void> update(LiveWorkoutActivityState state) async {
    if (!_started) return;
    try {
      await _channel.invokeMethod('update', state.toMap());
    } catch (error) {
      debugPrint('Live Activity update failed: $error');
    }
  }

  Future<void> end() async {
    if (!_started) return;
    _started = false;
    try {
      await _channel.invokeMethod('end');
    } catch (error) {
      debugPrint('Live Activity end failed: $error');
    }
  }
}
