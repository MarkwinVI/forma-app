import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Profile values that affect training prescriptions.
class UserProfileService {
  final _client = SupabaseService.client;

  /// The last bodyweight this session has seen, updated by every fetch and
  /// save. Open screens that derive weights from bodyweight — the live
  /// workout's "+100% bodyweight" targets — listen and repaint, so a profile
  /// edit lands everywhere at once.
  static final ValueNotifier<double?> bodyweightKgNotifier =
      ValueNotifier(null);

  Future<double?> fetchBodyweightKg(String userId) async {
    final data = await _client
        .from('users')
        .select('bodyweight_kg')
        .eq('id', userId)
        .maybeSingle();
    final value = (data?['bodyweight_kg'] as num?)?.toDouble();
    bodyweightKgNotifier.value = value;
    return value;
  }

  Future<void> updateBodyweightKg(String userId, double bodyweightKg) async {
    if (bodyweightKg < 20 || bodyweightKg > 400) {
      throw ArgumentError.value(
        bodyweightKg,
        'bodyweightKg',
        'Bodyweight must be between 20 and 400 kg.',
      );
    }
    await _client.from('users').update({
      'bodyweight_kg': bodyweightKg,
    }).eq('id', userId);
    bodyweightKgNotifier.value = bodyweightKg;
  }
}
