/// Replace these placeholder values with your actual Supabase project credentials.
/// Find them at: https://supabase.com/dashboard → your project → Settings → API
class AppConfig {
  static const String supabaseUrl = 'https://pcardimuewjcegourlgo.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_5AHTjZh-G8mwtJyvHwo7Bg_1v3KFmP4';

  /// PostHog project (EU Cloud): https://eu.posthog.com → Settings → Project
  static const String posthogApiKey =
      'phc_wwrCxQh98KgQmdBYFGRtdASPEXe2BZni9Coimmw86Z53';
  static const String posthogHost = 'https://eu.i.posthog.com';

  /// Google Cloud → APIs & Services → Credentials → the OAuth client of type
  /// "Web application" — the same Client ID entered under Supabase →
  /// Authentication → Providers → Google. Google signs the ID token for this
  /// client; Android identifies the app itself by package name + SHA-1, so
  /// no Android client ID is needed here.
  static const String googleWebClientId =
      '892742802208-lplmfinelmg29vr1ov181hlsfilri0mb.apps.googleusercontent.com';
}
