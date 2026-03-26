import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

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
    if (idToken == null) throw Exception('Apple Sign In failed: no identity token received.');

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    final user = response.user;
    if (user == null) throw Exception('Sign in failed: Supabase returned no user.');

    await _upsertUser(user, credential);

    final data = await _client.from('users').select().eq('id', user.id).single();
    return UserModel.fromMap(data);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // ---------- Helpers ----------

  Future<void> _upsertUser(
    User user,
    AuthorizationCredentialAppleID credential,
  ) async {
    final fullName = [
      credential.givenName,
      credential.familyName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    await _client.from('users').upsert({
      'id': user.id,
      'email': user.email ?? credential.email,
      'full_name': fullName.isEmpty ? null : fullName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
