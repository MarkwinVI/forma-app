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

/// Where the Profile tab's two sheets send: an app rating in stars, and a
/// message to support.
abstract class ProfileFeedbackStore {
  Future<void> sendAppFeedback({required int rating, required String? note});

  /// Delivers a support message to the team and records it. Throws when it
  /// could not be delivered, so the sheet can say so and keep the draft.
  Future<void> sendSupportMessage(String message);
}

/// The `feedback` table: session ratings, app ratings and support
/// messages. Every write silently attaches the app version, platform and
/// OS version so a report can be read against the build that earned it.
class FeedbackService implements SessionFeedbackStore, ProfileFeedbackStore {
  SupabaseClient get _client => SupabaseService.client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot save feedback while signed out.');
    }
    return userId;
  }

  @override
  Future<String> save({
    required String? id,
    required String? workoutSessionId,
    required FeedbackSentiment sentiment,
    required List<String> tags,
    required List<String> flaggedExerciseIds,
    required String? note,
  }) async {
    final userId = _requireUserId();
    final diagnostics = await FeedbackDiagnostics.collect();
    final values = {
      'sentiment': sentiment.dbValue,
      'tags': tags,
      'flagged_exercise_ids': flaggedExerciseIds,
      'note': _cleanNote(note),
      ...diagnostics.toColumns(),
    };

    if (id != null) {
      await _client.from('feedback').update({
        ...values,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', id);
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

  @override
  Future<void> sendAppFeedback({
    required int rating,
    required String? note,
  }) async {
    final userId = _requireUserId();
    final diagnostics = await FeedbackDiagnostics.collect();
    await _client.from('feedback').insert({
      'user_id': userId,
      'kind': 'app_rating',
      'rating': rating,
      'note': _cleanNote(note),
      ...diagnostics.toColumns(),
    });
  }

  /// The `support-message` edge function records the message and emails
  /// it to the team inbox with the account email as the reply address, so
  /// a reply from the inbox lands straight back with the user.
  @override
  Future<void> sendSupportMessage(String message) async {
    _requireUserId();
    final diagnostics = await FeedbackDiagnostics.collect();
    await _client.functions.invoke('support-message', body: {
      'message': message.trim(),
      ...diagnostics.toColumns(),
    });
  }

  static String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
