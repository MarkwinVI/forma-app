import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/membership_model.dart';
import 'analytics_service.dart';
import 'auth_service.dart';
import 'purchases_gateway.dart';
import 'supabase_service.dart';

/// Reads the server's membership override for a user, if any.
typedef MembershipOverrideFetcher = Future<MembershipOverride?> Function(
  String userId,
);

Future<MembershipOverride?> fetchMembershipOverride(String userId) async {
  final row = await SupabaseService.client
      .from('user_membership_overrides')
      .select('source, expires_at')
      .eq('user_id', userId)
      .maybeSingle();
  if (row == null) return null;
  return MembershipOverride(
    source: row['source'] as String,
    expiresAt: DateTime.tryParse(row['expires_at'] as String? ?? '')?.toLocal(),
  );
}

/// One membership for the whole app: resolved behind the splash, cached on
/// device so a cold start never waits on the network, and pushed through
/// [notifier] so the lock lifts everywhere the moment a purchase lands.
///
/// The membership is worked out by [resolveMembership] from two sources
/// fetched together — the store (RevenueCat) and the server override row.
/// Screens read [current] or listen to [notifier]; they never talk to the
/// store directly.
class MembershipService {
  MembershipService({
    PurchasesGateway? gateway,
    MembershipOverrideFetcher? fetchOverride,
    DateTime Function()? now,
  })  : _gateway = gateway ?? RevenueCatGateway(),
        _fetchOverride = fetchOverride ?? fetchMembershipOverride,
        _now = now ?? DateTime.now;

  /// The app-wide instance. Tests swap it for one with a fake gateway.
  static MembershipService instance = MembershipService();

  static const _prefsPrefix = 'membership_';

  /// How long the startup resolve may wait on the network before the cached
  /// (or default) membership stands in. The splash covers most of this.
  static const networkTimeout = Duration(seconds: 8);

  final PurchasesGateway _gateway;
  final MembershipOverrideFetcher _fetchOverride;
  final DateTime Function() _now;

  /// The membership in force, null until the first resolve for a user has
  /// produced anything (a cached copy counts). In debug builds a forced
  /// state (see [setDebugState]) shows here in place of the real one.
  final ValueNotifier<Membership?> notifier = ValueNotifier(null);

  Membership? get current => notifier.value;

  /// The genuinely resolved membership, whatever the debug override says.
  Membership? _real;

  void _setReal(Membership? membership) {
    _real = membership;
    notifier.value = _debugState == null ? membership : _debug();
  }

  /// Memoized per user, so the warm-up in main() and the shell's landing
  /// check share one resolve (see OnboardingService for the same pattern).
  final _loads = <String, Future<Membership>>{};
  String? _userId;

  /// The account the store SDK is identified as, and the identification in
  /// flight — a resolve waits for it, so an account's first read is never
  /// the anonymous identity's empty history.
  String? _storeUserId;
  Future<void>? _identifying;
  MembershipOverride? _lastOverride;
  Future<List<MembershipPlan>>? _plans;
  StreamSubscription<StoreAccount>? _updates;
  bool _configured = false;

  /// Debug builds only: a state forced from the Developer section so every
  /// locked variant can be seen without a sandbox subscription.
  MembershipState? _debugState;

  /// Starts the store SDK and follows the auth session: sign-in ties the
  /// store identity to the account, sign-out drops it. Never throws — an
  /// SDK that fails to start (no StoreKit on this platform) leaves the app
  /// resolving from the override row and the cache alone.
  Future<void> setup() async {
    final signedIn = AuthService().currentUser;
    try {
      await _gateway.configure(userId: signedIn?.id);
      _configured = true;
      _userId = signedIn?.id;
      _storeUserId = signedIn?.id;
      _updates = _gateway.updates.listen(_onStoreUpdate);
    } catch (error) {
      debugPrint('Store SDK setup failed, membership from cache only: $error');
    }

    AuthService().onAuthStateChange.listen((state) {
      final user = state.session?.user;
      if (state.event == AuthChangeEvent.signedOut) {
        unawaited(_signOut());
      } else if (user != null && user.id != _storeUserId) {
        _identify(user.id);
      }
    });
  }

  /// Ties the store identity to [userId]. Tracked so a resolve started in
  /// the same breath waits for it.
  void _identify(String userId) {
    _storeUserId = userId;
    if (!_configured) return;
    final future = _gateway.logIn(userId).catchError((Object error) {
      debugPrint('Store logIn failed: $error');
    });
    _identifying = future;
    future.whenComplete(() {
      if (identical(_identifying, future)) _identifying = null;
    });
  }

  Future<void> _signOut() async {
    _userId = null;
    _storeUserId = null;
    _loads.clear();
    _lastOverride = null;
    _setReal(null);
    if (_configured) await _gateway.logOut();
  }

  /// The membership for [userId]: the cached copy at once when there is
  /// one, then the fresh resolve. Awaiting it gives the fresh answer, or
  /// the best available one once [networkTimeout] runs out.
  Future<Membership> load(String userId) {
    _userId = userId;
    return _loads[userId] ??= () {
      late final Future<Membership> future;
      future = _load(userId, onFailure: () {
        // A failed resolve must not stick, or a retry would replay it.
        if (identical(_loads[userId], future)) _loads.remove(userId);
      });
      return future;
    }();
  }

  /// Drops the memo and resolves again — after a purchase, a restore, or a
  /// pull to refresh.
  Future<Membership> refresh() {
    final userId = _userId ?? AuthService().currentUser?.id;
    if (userId == null) return Future.value(_fallback());
    _loads.remove(userId);
    return load(userId);
  }

  Future<Membership> _load(
    String userId, {
    required VoidCallback onFailure,
  }) async {
    final cached = await _readCache(userId);
    if (cached != null && _real == null) _setReal(cached);

    try {
      final (override, account) = await (
        _fetchOverrideOrLast(userId),
        _fetchAccount(),
      ).wait.timeout(networkTimeout);
      _lastOverride = override;
      return _publish(
          userId,
          resolveMembership(
            store: account,
            override: override,
            now: _now(),
          ));
    } catch (error) {
      debugPrint('Membership resolve failed, using cache: $error');
      onFailure();
      final membership = cached ?? _fallback();
      if (_real == null) _setReal(membership);
      return membership;
    }
  }

  /// The server's override row. A failed read is not a failed resolve —
  /// the store's answer still stands — so it falls back to the last row
  /// seen this session (usually none).
  Future<MembershipOverride?> _fetchOverrideOrLast(String userId) async {
    try {
      return await _fetchOverride(userId);
    } catch (error) {
      debugPrint('Membership override read failed: $error');
      return _lastOverride;
    }
  }

  Future<StoreAccount?> _fetchAccount() async {
    if (!_configured) return null;
    await _identifying;
    return _gateway.fetchAccount();
  }

  /// The membership that asks rather than assumes, for when nothing is
  /// known: locked, trial offered.
  Membership _fallback() => Membership(
        state: MembershipState.trialAvailable,
        resolvedAt: _now(),
      );

  /// The store changed under us — a renewal, a cancellation, a purchase on
  /// another device. Re-resolve against the last known override.
  void _onStoreUpdate(StoreAccount account) {
    final userId = _userId;
    if (userId == null) return;
    _publish(
        userId,
        resolveMembership(
          store: account,
          override: _lastOverride,
          now: _now(),
        ));
  }

  Membership _publish(String userId, Membership membership) {
    final previous = _real;
    _setReal(membership);
    unawaited(_writeCache(userId, membership));
    if (previous?.state != membership.state) {
      AnalyticsService.capture('membership_resolved', properties: {
        'state': membership.state.name,
        if (membership.productId != null) 'product_id': membership.productId!,
        if (membership.overrideSource != null)
          'override_source': membership.overrideSource!,
      }, personProperties: {
        'membership_state': membership.state.name,
      });
    }
    return membership;
  }

  /// The plans on sale, fetched once per session. A failed fetch is not
  /// memoized, so the paywall's retry asks again.
  Future<List<MembershipPlan>> plans() {
    return _plans ??= () {
      final future = _gateway.fetchPlans();
      future.then<void>((_) {}, onError: (Object _) {
        if (identical(_plans, future)) _plans = null;
      });
      return future;
    }();
  }

  /// Runs the App Store purchase and resolves the membership from the
  /// result. Throws [PurchaseCancelled] when the user backs out.
  Future<Membership> purchase(String productId) async {
    final userId = _requireUser();
    AnalyticsService.capture('purchase_started', properties: {
      'product_id': productId,
      'membership_state': current?.state.name ?? 'unknown',
    });
    final StoreAccount account;
    try {
      account = await _gateway.purchase(productId);
    } on PurchaseCancelled {
      AnalyticsService.capture('purchase_cancelled', properties: {
        'product_id': productId,
      });
      rethrow;
    }
    final membership = _publish(
        userId,
        resolveMembership(
          store: account,
          override: _lastOverride,
          now: _now(),
        ));
    _loads[userId] = Future.value(membership);
    AnalyticsService.capture('purchase_completed', properties: {
      'product_id': productId,
      'state': membership.state.name,
    });
    return membership;
  }

  /// Restores purchases made under this Apple ID and resolves from them.
  Future<Membership> restore() async {
    final userId = _requireUser();
    final account = await _gateway.restore();
    final membership = _publish(
        userId,
        resolveMembership(
          store: account,
          override: _lastOverride,
          now: _now(),
        ));
    _loads[userId] = Future.value(membership);
    AnalyticsService.capture('purchase_restored', properties: {
      'state': membership.state.name,
    });
    return membership;
  }

  String _requireUser() {
    final userId = _userId ?? AuthService().currentUser?.id;
    if (userId == null) throw StateError('No signed-in user.');
    _userId = userId;
    return userId;
  }

  // ── Debug override ──────────────────────────────────────────────────

  MembershipState? get debugState => _debugState;

  /// Forces [current] to a state (debug builds only). Null clears it.
  void setDebugState(MembershipState? state) {
    if (!kDebugMode) return;
    _debugState = state;
    _setReal(_real);
  }

  Membership _debug() {
    final state = _debugState!;
    final now = _now();
    return Membership(
      state: state,
      expiresAt: switch (state) {
        MembershipState.trialing => now.add(const Duration(days: 5)),
        MembershipState.subscribed => now.add(const Duration(days: 200)),
        MembershipState.trialEnded ||
        MembershipState.lapsed =>
          now.subtract(const Duration(days: 3)),
        _ => null,
      },
      productId: switch (state) {
        MembershipState.trialing ||
        MembershipState.subscribed ||
        MembershipState.trialEnded ||
        MembershipState.lapsed =>
          MembershipProducts.yearly,
        _ => null,
      },
      willRenew: state == MembershipState.trialing ||
          state == MembershipState.subscribed,
      overrideSource: state == MembershipState.complimentary ? 'comped' : null,
      resolvedAt: now,
    );
  }

  // ── Cache ───────────────────────────────────────────────────────────

  Future<Membership?> _readCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix$userId');
      if (raw == null) return null;
      return Membership.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String userId, Membership membership) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefsPrefix$userId',
        jsonEncode(membership.toJson()),
      );
    } catch (_) {
      // Best effort: the in-memory membership is already published.
    }
  }

  @visibleForTesting
  void dispose() {
    _updates?.cancel();
  }
}
