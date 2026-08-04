import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the "rest is over" notification during a live workout.
///
/// The notification is deliberately silent while the app is in the
/// foreground — the workout screen already plays its own alert sound when a
/// rest timer runs out. It only surfaces (as a time-sensitive banner with
/// sound) when the phone is locked or the user is in another app.
class WorkoutNotificationService {
  WorkoutNotificationService._();

  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();

  static const _restOverId = 2001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> _ensureInitialized() async {
    if (_initialized || !_isSupported) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(
          // Permission is asked explicitly from the workout flow, not at
          // plugin start-up.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  /// Asks for notification permission. Safe to call every workout — the OS
  /// only prompts once; afterwards it resolves from the stored setting.
  Future<void> requestPermission() async {
    if (!_isSupported) return;
    await _ensureInitialized();

    try {
      if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true);
      } else if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (error, stackTrace) {
      debugPrint('Notification permission request failed: $error\n$stackTrace');
    }
  }

  /// (Re)schedules the rest-over notification for [endsAt]. Replaces any
  /// previously scheduled one — there is only ever one rest timer running.
  Future<void> scheduleRestOver({
    required DateTime endsAt,
    required String exerciseName,
  }) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!endsAt.isAfter(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        _restOverId,
        'Rest is over',
        'Back to $exerciseName — next set is up.',
        tz.TZDateTime.from(endsAt, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
            // In the foreground the workout screen plays its own sound, so
            // the notification stays quiet there and only presents when the
            // app is backgrounded or the phone is locked.
            presentAlert: false,
            presentBanner: false,
            presentSound: false,
          ),
          android: AndroidNotificationDetails(
            'rest_timer',
            'Rest timer',
            channelDescription: 'Alerts when a rest timer finishes',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.workout,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (error, stackTrace) {
      // A workout must never fail because a notification could not be
      // scheduled (permission denied, exact alarms off, …).
      debugPrint('Failed to schedule rest notification: $error\n$stackTrace');
    }
  }

  /// Cancels the pending rest-over notification, if any.
  Future<void> cancelRestOver() async {
    if (!_isSupported || !_initialized) return;
    try {
      await _plugin.cancel(_restOverId);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel rest notification: $error\n$stackTrace');
    }
  }
}
