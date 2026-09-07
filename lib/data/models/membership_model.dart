import 'package:flutter/foundation.dart';

/// What the app knows about a user's membership, resolved from the store
/// (RevenueCat over Apple) and the server's override table.
///
/// The three locked states carry different copy on the lock dock: someone
/// who can still start a trial is invited to; someone whose trial ran out is
/// asked to subscribe; someone whose paid plan lapsed is welcomed back.
/// [subscribeOnly] is the odd one: never a member here, but Apple says the
/// trial is used up (it is one per Apple ID), so the copy must not promise
/// a free week the App Store sheet would then charge for.
enum MembershipState {
  /// Locked. Never a member; a free trial is on offer.
  trialAvailable,

  /// Locked. Never a member here, but no trial is available.
  subscribeOnly,

  /// Locked. The free trial ran out without converting.
  trialEnded,

  /// Locked. A paid plan that was cancelled or failed to renew.
  lapsed,

  /// Unlocked, inside the free trial.
  trialing,

  /// Unlocked, on a paid plan.
  subscribed,

  /// Unlocked by a grant made in the RevenueCat dashboard, not a purchase.
  complimentary,
}

extension MembershipStateX on MembershipState {
  bool get entitled =>
      this == MembershipState.trialing ||
      this == MembershipState.subscribed ||
      this == MembershipState.complimentary;
}

/// The two plans on sale, by store product id.
///
/// Release builds sell the App Store products. Debug builds talk to
/// RevenueCat's Test Store, whose copies of the same two plans carry
/// shorter ids — so the ids the store is asked for depend on the build,
/// and "is this the yearly plan" accepts either spelling.
class MembershipProducts {
  MembershipProducts._();

  /// The one entitlement every plan unlocks, and the thing a dashboard
  /// grant switches on. What the app checks.
  static const String entitlement = 'forma_pro';

  static const String yearly = 'forma_pro_annual';
  static const String monthly = 'forma_pro_monthly';

  static const String testStoreYearly = 'forma_test_yearly';
  static const String testStoreMonthly = 'forma_test_monthly';

  /// The ids to ask this build's store for.
  static List<String> get all => kDebugMode
      ? const [testStoreYearly, testStoreMonthly]
      : const [yearly, monthly];

  static bool isYearly(String productId) =>
      productId == yearly || productId == testStoreYearly;

  static bool isKnown(String productId) =>
      productId == yearly ||
      productId == monthly ||
      productId == testStoreYearly ||
      productId == testStoreMonthly;
}

class Membership {
  final MembershipState state;

  /// When the current period ends — the trial's end, the paid period's
  /// renewal date, or a comped row's expiry. Null when open-ended.
  final DateTime? expiresAt;

  /// The subscribed product, while one is active or was.
  final String? productId;

  /// Whether the active plan renews at [expiresAt]. False once cancelled.
  final bool willRenew;

  /// Set for [MembershipState.complimentary]: how the access was granted
  /// ('granted' — a promotional entitlement from the dashboard).
  final String? overrideSource;

  /// When this was worked out. A cached copy is only ever a fallback.
  final DateTime resolvedAt;

  const Membership({
    required this.state,
    this.expiresAt,
    this.productId,
    this.willRenew = false,
    this.overrideSource,
    required this.resolvedAt,
  });

  bool get entitled => state.entitled;
  bool get locked => !entitled;

  /// Whether a free trial is what the CTAs should lead with.
  bool get trialOffered => state == MembershipState.trialAvailable;

  /// Whole days left in the current period, never negative.
  int daysLeft(DateTime now) {
    final end = expiresAt;
    if (end == null) return 0;
    final hours = end.difference(now).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'product_id': productId,
        'will_renew': willRenew,
        'override_source': overrideSource,
        'resolved_at': resolvedAt.toUtc().toIso8601String(),
      };

  static Membership? fromJson(Map<String, dynamic> json) {
    final state = MembershipState.values
        .where((value) => value.name == json['state'])
        .firstOrNull;
    final resolvedAt = DateTime.tryParse(json['resolved_at'] as String? ?? '');
    if (state == null || resolvedAt == null) return null;
    return Membership(
      state: state,
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      productId: json['product_id'] as String?,
      willRenew: json['will_renew'] as bool? ?? false,
      overrideSource: json['override_source'] as String?,
      resolvedAt: resolvedAt,
    );
  }
}

/// One subscription the store knows about for this user, active or not.
class StoreSubscription {
  final String productId;
  final bool isActive;
  final DateTime? expiresAt;
  final bool willRenew;

  /// True while (or if the last period was) the free trial.
  final bool isTrial;

  const StoreSubscription({
    required this.productId,
    required this.isActive,
    required this.expiresAt,
    required this.willRenew,
    required this.isTrial,
  });
}

/// The `forma_pro` entitlement as the store reports it: what unlocked it
/// (a plan, or a grant), until when, and whether it is live now.
class StoreEntitlement {
  final bool isActive;
  final String productId;
  final DateTime? expiresAt;
  final bool willRenew;

  /// True while the entitlement runs on the free trial.
  final bool isTrial;

  /// True for a promotional grant made in the dashboard rather than a
  /// purchase.
  final bool isGranted;

  const StoreEntitlement({
    required this.isActive,
    required this.productId,
    required this.expiresAt,
    required this.willRenew,
    required this.isTrial,
    required this.isGranted,
  });
}

/// The store's view of the user: the entitlement, every subscription it
/// has seen, and whether Apple would still grant the free trial (null =
/// unknown).
class StoreAccount {
  final StoreEntitlement? entitlement;
  final List<StoreSubscription> subscriptions;
  final bool? trialEligible;

  const StoreAccount({
    this.entitlement,
    required this.subscriptions,
    required this.trialEligible,
  });

  static const empty = StoreAccount(subscriptions: [], trialEligible: null);
}

/// Works out the membership from what the store says.
///
/// A live entitlement unlocks: complimentary for a dashboard grant, else
/// trialing or subscribed by the period it runs on. Without one, the
/// subscription history sets the copy for how the user got locked out;
/// and with no history at all the trial is offered unless Apple says it
/// is used up. No store data — offline on a fresh install, or the store
/// SDK unavailable — reads as locked with the trial offered, the state
/// that asks rather than assumes.
Membership resolveMembership({
  required StoreAccount? store,
  required DateTime now,
}) {
  final entitlement = store?.entitlement;
  if (entitlement != null && entitlement.isActive) {
    return Membership(
      state: entitlement.isGranted
          ? MembershipState.complimentary
          : entitlement.isTrial
              ? MembershipState.trialing
              : MembershipState.subscribed,
      expiresAt: entitlement.expiresAt,
      productId: entitlement.isGranted ? null : entitlement.productId,
      willRenew: entitlement.willRenew,
      overrideSource: entitlement.isGranted ? 'granted' : null,
      resolvedAt: now,
    );
  }

  final subscriptions = store?.subscriptions ?? const [];

  StoreSubscription? latest(Iterable<StoreSubscription> items) {
    StoreSubscription? best;
    for (final item in items) {
      if (best == null) {
        best = item;
        continue;
      }
      final a = item.expiresAt, b = best.expiresAt;
      if (b == null) continue;
      if (a == null || a.isAfter(b)) best = item;
    }
    return best;
  }

  final past = latest(subscriptions);
  if (past != null) {
    return Membership(
      state: past.isTrial ? MembershipState.trialEnded : MembershipState.lapsed,
      expiresAt: past.expiresAt,
      productId: past.productId,
      resolvedAt: now,
    );
  }

  return Membership(
    state: store?.trialEligible == false
        ? MembershipState.subscribeOnly
        : MembershipState.trialAvailable,
    resolvedAt: now,
  );
}

/// A plan as the store prices it, ready to print.
class MembershipPlan {
  final String productId;
  final double price;
  final String currencyCode;

  /// The store's own localized price, "$49.99".
  final String priceString;

  /// For the yearly plan, the price spread over a month, "$4.17".
  final String? monthlyEquivalentString;

  /// Free-trial length in days, 0 when the product carries none.
  final int trialDays;

  const MembershipPlan({
    required this.productId,
    required this.price,
    required this.currencyCode,
    required this.priceString,
    required this.monthlyEquivalentString,
    required this.trialDays,
  });

  bool get isYearly => MembershipProducts.isYearly(productId);

  String get periodLabel => isYearly ? 'year' : 'month';
}
