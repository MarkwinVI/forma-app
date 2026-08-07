import 'supabase_service.dart';

/// Profile values that affect training prescriptions.
class UserProfileService {
  final _client = SupabaseService.client;

  Future<double?> fetchBodyweightKg(String userId) async {
    final data = await _client
        .from('users')
        .select('bodyweight_kg')
        .eq('id', userId)
        .maybeSingle();
    return (data?['bodyweight_kg'] as num?)?.toDouble();
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
  }
}
