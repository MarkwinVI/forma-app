import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the "rest is over" notification during a live workout.
///
/// The notification is deliberately silent while the app is in the
/// foreground — the workout screen already plays its own alert sound when a
/// rest timer runs out. It only surfaces (as a time-sensitive banner with
/// sound) when the phone is locked or the user is in another app.
///
/// On Android the notification rides on an alarm, and only an exact alarm
/// lands on the second. Exact alarms are granted on install up to Android
/// 13; from 14 on the user switches them on under Alarms & reminders, which
/// the workout screen asks for once ([shouldAskExactAlarms]). Without them
/// the notification is scheduled inexactly — minutes late at worst, when
/// the phone is locked — and [restElapsed] posts it on time whenever the
/// app is still running, so in Forma itself rest never ends silently.
class WorkoutNotificationService {
  WorkoutNotificationService._();

  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();

  static const _restOverId = 2001;
  static const _exactAlarmsAskedKey = 'exact_alarms_asked';

  /// How long a fired notification stays up on the workout screen before it
  /// is taken down: enough for the half-second chime to play out.
  static const _foregroundLinger = Duration(seconds: 2);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;

  /// Whether Android lets this app schedule exact alarms. Always true on
  /// iOS and below Android 12, where there is no such switch.
  bool _exactAllowed = true;

  /// The pending notification, if any: whether it was scheduled exactly,
  /// and its copy, in case it has to be posted by hand at the end of rest.
  bool _pendingExact = true;
  String? _pendingTitle;
  String? _pendingBody;

  /// Whether the rest-over sound is owned by the notification. When
  /// permission was denied the workout screen keeps playing its own alert
  /// sound instead, so rest never ends silently.
  bool get soundHandledByNotification => _permissionGranted;

  bool get _isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

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
        _permissionGranted = await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      } else if (Platform.isAndroid) {
        _permissionGranted =
            await _android?.requestNotificationsPermission() ?? false;
        await _refreshExactAllowed();
      }
    } catch (error, stackTrace) {
      debugPrint('Notification permission request failed: $error\n$stackTrace');
    }
  }

  // ── Exact alarms (Android) ──

  Future<void> _refreshExactAllowed() async {
    if (!Platform.isAndroid) return;
    try {
      _exactAllowed = await _android?.canScheduleExactNotifications() ?? true;
    } catch (error) {
      debugPrint('Exact alarm check failed: $error');
    }
  }

  /// Whether the workout screen should ask for Alarms & reminders: Android
  /// has not granted exact alarms, and the ask has never been shown. Answers
  /// true once per install — the answer, either way, is the user's to keep.
  Future<bool> shouldAskExactAlarms() async {
    if (!_isSupported || !Platform.isAndroid) return false;
    await _refreshExactAllowed();
    if (_exactAllowed) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_exactAlarmsAskedKey) ?? false) return false;
      await prefs.setBool(_exactAlarmsAskedKey, true);
      return true;
    } catch (error) {
      debugPrint('Exact alarm ask lookup failed: $error');
      return false;
    }
  }

  /// Opens Android's Alarms & reminders page for this app and resolves
  /// when the user comes back, with whether exact alarms are now allowed.
  Future<bool> requestExactAlarms() async {
    if (!_isSupported || !Platform.isAndroid) return true;
    await _ensureInitialized();
    try {
      _exactAllowed =
          await _android?.requestExactAlarmsPermission() ?? _exactAllowed;
    } catch (error, stackTrace) {
      debugPrint('Exact alarm request failed: $error\n$stackTrace');
    }
    return _exactAllowed;
  }

  // ── The rest-over notification ──

  NotificationDetails get _details => const NotificationDetails(
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
          // The bundled chime plays wherever the notification lands —
          // lock screen, another app, or Forma itself. In the foreground
          // the banner stays hidden (the workout screen IS the rest
          // timer) but the sound still marks the moment; the in-app
          // fallback chime only fires when permission was denied.
          sound: 'rest_over.caf',
          presentAlert: false,
          presentBanner: false,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          // Sounds bake into a channel at creation, so the custom chime
          // needs a fresh channel id — never reuse 'rest_timer'.
          'rest_timer_v2',
          'Rest timer',
          channelDescription: 'Alerts when a rest timer finishes',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.workout,
          sound: RawResourceAndroidNotificationSound('rest_over'),
        ),
      );

  /// (Re)schedules the rest-over notification for [endsAt]. Replaces any
  /// previously scheduled one — there is only ever one rest timer running.
  Future<void> scheduleRestOver({
    required DateTime endsAt,
    required String exerciseName,
  }) async {
    if (!_isSupported) return;
    await _ensureInitialized();
    if (!endsAt.isAfter(DateTime.now())) return;

    // The user may have flipped the switch in Settings since last time.
    await _refreshExactAllowed();
    const title = 'Rest is over';
    final body = 'Back to $exerciseName — next set is up.';

    try {
      await _plugin.zonedSchedule(
        _restOverId,
        title,
        body,
        tz.TZDateTime.from(endsAt, tz.local),
        _details,
        androidScheduleMode: _exactAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _pendingExact = _exactAllowed;
      _pendingTitle = title;
      _pendingBody = body;
    } catch (error, stackTrace) {
      // A workout must never fail because a notification could not be
      // scheduled (permission denied, exact alarms off, …).
      debugPrint('Failed to schedule rest notification: $error\n$stackTrace');
    }
  }

  /// Rest ran its course while the app was running. An exact notification
  /// has just fired by itself; an inexact one may still be minutes out, so
  /// it is posted now instead. Either way, on the workout screen the banner
  /// is taken down once the chime has played — in the background it stays,
  /// being the cue the user put the phone down for.
  Future<void> restElapsed() async {
    if (!_isSupported || !_initialized) return;
    try {
      if (!_pendingExact && _pendingTitle != null) {
        await _plugin.cancel(_restOverId);
        await _plugin.show(_restOverId, _pendingTitle, _pendingBody, _details);
      }
      _pendingTitle = null;
      _pendingBody = null;
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        await Future<void>.delayed(_foregroundLinger);
        await _plugin.cancel(_restOverId);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to settle rest notification: $error\n$stackTrace');
    }
  }

  /// Cancels the pending rest-over notification, if any — the user cut
  /// rest short, or left the workout.
  Future<void> cancelRestOver() async {
    if (!_isSupported || !_initialized) return;
    _pendingTitle = null;
    _pendingBody = null;
    try {
      await _plugin.cancel(_restOverId);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel rest notification: $error\n$stackTrace');
    }
  }
}
