import '../models/onboarding_profile_model.dart';
import 'supabase_service.dart';

/// Reads and writes the post-signup onboarding answers
/// (`user_onboarding_profiles`, one row per user).
class OnboardingService {
  final _client = SupabaseService.client;

  /// Whether this user has finished the onboarding flow. New accounts —
  /// including re-registrations after an account deletion — have no row
  /// and are routed through onboarding.
  Future<bool> hasCompletedOnboarding(String userId) async {
    final row = await _client
        .from('user_onboarding_profiles')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> saveProfile(OnboardingProfileModel profile) async {
    await _client
        .from('user_onboarding_profiles')
        .upsert(profile.toMap(), onConflict: 'user_id');
  }
}
