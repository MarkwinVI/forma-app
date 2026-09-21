import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Which way a session rating went.
enum FeedbackSentiment {
  up('up'),
  down('down');

  final String dbValue;
  const FeedbackSentiment(this.dbValue);
}

/// Where a session rating is written. The screen talks to this, not to
/// Supabase, so a test can hand it a fake and read back what was sent.
abstract class SessionFeedbackStore {
  /// Writes the rating and returns the row's id. With [id] the existing row
  /// is updated in place — a thumb tapped early and a note sent later are
  /// one row, not two.
  Future<String> save({
    required String? id,
    required String? workoutSessionId,
    required FeedbackSentiment sentiment,
    required List<String> tags,
    required List<String> flaggedExerciseIds,
    required String? note,
  });
}

/// The `feedback` table: session ratings now, app ratings and support
/// messages when they arrive. Every write silently attaches the app
/// version, platform and OS version so a report can be read against the
/// build that earned it.
class FeedbackService implements SessionFeedbackStore {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<String> save({
    required String? id,
    required String? workoutSessionId,
    required FeedbackSentiment sentiment,
    required List<String> tags,
    required List<String> flaggedExerciseIds,
    required String? note,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot save feedback while signed out.');
    }
    final diagnostics = await FeedbackDiagnostics.collect();
    final trimmedNote = note?.trim();
    final values = {
      'sentiment': sentiment.dbValue,
      'tags': tags,
      'flagged_exercise_ids': flaggedExerciseIds,
      'note': trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
      ...diagnostics.toColumns(),
    };

    if (id != null) {
      await _client
          .from('feedback')
          .update({...values, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
      return id;
    }

    final row = await _client
        .from('feedback')
        .insert({
          'user_id': userId,
          'kind': 'session_rating',
          'workout_session_id': workoutSessionId,
          ...values,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }
}

/// The build a piece of feedback was sent from. Read once per launch; a
/// platform that cannot answer leaves the field null rather than failing
/// the send.
class FeedbackDiagnostics {
  final String? appVersion;
  final String platform;
  final String? osVersion;

  const FeedbackDiagnostics({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
  });

  static Future<FeedbackDiagnostics>? _cached;

  static Future<FeedbackDiagnostics> collect() =>
      _cached ??= _collect().catchError((Object error) {
        debugPrint('Feedback diagnostics unavailable: $error');
        return const FeedbackDiagnostics(
          appVersion: null,
          platform: 'unknown',
          osVersion: null,
        );
      });

  static Future<FeedbackDiagnostics> _collect() async {
    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (error) {
      debugPrint('App version unavailable: $error');
    }
    if (kIsWeb) {
      return FeedbackDiagnostics(
        appVersion: appVersion,
        platform: 'web',
        osVersion: null,
      );
    }
    return FeedbackDiagnostics(
      appVersion: appVersion,
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
    );
  }

  Map<String, Object?> toColumns() => {
        'app_version': appVersion,
        'platform': platform,
        'os_version': osVersion,
      };
}
