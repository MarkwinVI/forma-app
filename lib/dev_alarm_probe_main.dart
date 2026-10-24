// Throwaway harness: drives WorkoutNotificationService without signing in,
// so the rest-over notification's permission paths can be checked on an
// Android that denies exact alarms by default (14 and up).
//
//   flutter run -t lib/dev_alarm_probe_main.dart
//
// Not part of the app. Delete freely.
import 'package:flutter/material.dart';

import 'data/services/workout_notification_service.dart';

void main() {
  runApp(const MaterialApp(home: _Probe()));
}

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _service = WorkoutNotificationService.instance;
  final _log = <String>[];

  void _note(String line) {
    debugPrint('probe: $line');
    setState(() => _log.insert(0, line));
  }

  Future<void> _run(String what, Future<String> Function() action) async {
    try {
      _note('$what → ${await action()}');
    } catch (error) {
      _note('$what threw $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(String, Future<String> Function())>[
      (
        'Permission + should ask',
        () async {
          await _service.requestPermission();
          final ask = await _service.shouldAskExactAlarms();
          return 'sound by notification: '
              '${_service.soundHandledByNotification}, should ask: $ask';
        }
      ),
      (
        'Request exact alarms',
        () async => 'exact allowed now: ${await _service.requestExactAlarms()}',
      ),
      (
        'Schedule rest, 15s',
        () async {
          await _service.scheduleRestOver(
            endsAt: DateTime.now().add(const Duration(seconds: 15)),
            exerciseName: 'Pull Up',
          );
          return 'scheduled for ${DateTime.now().add(const Duration(seconds: 15))}';
        }
      ),
      (
        'Rest elapsed now',
        () async {
          await _service.restElapsed();
          return 'settled';
        }
      ),
      (
        'Cancel',
        () async {
          await _service.cancelRestOver();
          return 'cancelled';
        }
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed 72dp rows from the top, so a script can tap them.
            for (final (label, action) in actions)
              SizedBox(
                height: 72,
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _run(label, action),
                  child: Text(label, style: const TextStyle(fontSize: 18)),
                ),
              ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final line in _log)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(line, style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
