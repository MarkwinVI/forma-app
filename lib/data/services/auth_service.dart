import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

  // ---------- Google Sign In ----------

  static bool _googleInitialized = false;

  /// Native Google sign-in: the account sheet, then the ID token goes to
  /// Supabase the same way Apple's does. Google mints the token for the
  /// *web* client (Supabase's), so that is the `serverClientId`; Android
  /// finds the app's own client by package name and signing certificate.
  Future<UserModel?> signInWithGoogle() async {
    if (AppConfig.googleWebClientId.isEmpty) {
      throw StateError(
        'AppConfig.googleWebClientId is not set — Google sign-in needs the '
        'web OAuth client ID that the Supabase Google provider uses.',
      );
    }
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(serverClientId: AppConfig.googleWebClientId);
      _googleInitialized = true;
    }

    // Throws GoogleSignInException(code: canceled) when the sheet is
    // dismissed; the login view treats that as "nothing happened".
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google Sign In failed: no ID token received.');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign in failed: Supabase returned no user.');
    }

    await _upsertUserRow(
      user,
      email: user.email ?? account.email,
      fullName: _nonEmpty(account.displayName) ??
          _nonEmpty(user.userMetadata?['full_name'] as String?),
    );

    final data =
        await _client.from('users').select().eq('id', user.id).single();
    return UserModel.fromMap(data);
  }

  // ---------- Apple Sign In ----------

  Future<UserModel?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign In failed: no identity token received.');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign in failed: Supabase returned no user.');
    }

    await _upsertUser(user, credential);

    final data =
        await _client.from('users').select().eq('id', user.id).single();
    return UserModel.fromMap(data);
  }

  // ---------- Session ----------

  Future<void> signOut() async {
    await _client.auth.signOut();
    // Forget the Google account too, so the next sign-in shows the picker
    // instead of silently reusing it. Best effort: never blocks sign-out.
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut().catchError((_) {});
    }
  }

  /// Permanently deletes the account via the `delete_account` Postgres
  /// function (security definer). Deleting the auth user cascades through
  /// every user-owned table, so all server data is removed. The local
  /// session is cleared afterwards, which sends the app to the login view.
  Future<void> deleteAccount() async {
    // Captured (and pushed out) while the account still exists — after the
    // sign-out below, reset() has already cut the person link.
    AnalyticsService.capture('account_deleted');
    await AnalyticsService.flush();
    await _client.rpc('delete_account');
    // The server-side sign-out may 4xx because the user no longer exists;
    // gotrue clears the local session regardless of those responses.
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // ---------- Helpers ----------

  Future<void> _upsertUser(
    User user,
    AuthorizationCredentialAppleID credential,
  ) {
    final fullName = [
      credential.givenName,
      credential.familyName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');
    return _upsertUserRow(
      user,
      email: user.email ?? credential.email,
      fullName: fullName.isEmpty ? null : fullName,
    );
  }

  Future<void> _upsertUserRow(
    User user, {
    required String? email,
    required String? fullName,
  }) async {
    // A missing row is what makes this sign-in a registration — including
    // re-registration after an account deletion, which issues a new user id.
    final existing = await _client
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    // created_at is deliberately absent: the column's `default now()` stamps
    // it once on insert, and an upsert only touches the columns it is given —
    // so a returning sign-in can no longer overwrite the registration date.
    await _client.from('users').upsert({
      'id': user.id,
      'email': email,
      'full_name': fullName,
    });

    if (existing == null) {
      AnalyticsService.capture('account_created');
    }
  }

  static String? _nonEmpty(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
