import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/membership_model.dart';

void main() {
  final now = DateTime(2026, 9, 7, 12);

  StoreSubscription sub({
    required bool active,
    required bool trial,
    String productId = MembershipProducts.yearly,
    DateTime? expiresAt,
    bool willRenew = true,
  }) =>
      StoreSubscription(
        productId: productId,
        isActive: active,
        expiresAt: expiresAt ??
            (active
                ? now.add(const Duration(days: 5))
                : now.subtract(const Duration(days: 2))),
        willRenew: willRenew,
        isTrial: trial,
      );

  StoreEntitlement entitlement({
    required bool active,
    bool trial = false,
    bool granted = false,
    String productId = MembershipProducts.yearly,
    DateTime? expiresAt,

    /// A grant with no end — lifetime access.
    bool openEnded = false,
    bool willRenew = true,
  }) =>
      StoreEntitlement(
        isActive: active,
        productId: productId,
        expiresAt: openEnded
            ? null
            : expiresAt ?? now.add(const Duration(days: 5)),
        willRenew: willRenew,
        isTrial: trial,
        isGranted: granted,
      );

  Membership resolve(StoreAccount? store) =>
      resolveMembership(store: store, now: now);

  test('nothing known: locked, trial offered', () {
    final m = resolve(null);
    expect(m.state, MembershipState.trialAvailable);
    expect(m.locked, isTrue);
    expect(m.trialOffered, isTrue);
  });

  test('never a member and Apple says the trial is used up: subscribe only',
      () {
    final m = resolve(
      const StoreAccount(subscriptions: [], trialEligible: false),
    );
    expect(m.state, MembershipState.subscribeOnly);
    expect(m.trialOffered, isFalse);
  });

  test('a live entitlement on the trial unlocks as trialing, with its end', () {
    final m = resolve(StoreAccount(
      entitlement: entitlement(active: true, trial: true),
      subscriptions: [sub(active: true, trial: true)],
      trialEligible: false,
    ));
    expect(m.state, MembershipState.trialing);
    expect(m.entitled, isTrue);
    expect(m.daysLeft(now), 5);
    expect(m.productId, MembershipProducts.yearly);
  });

  test('a live entitlement on a paid period is subscribed', () {
    final m = resolve(StoreAccount(
      entitlement: entitlement(active: true, willRenew: false),
      subscriptions: [sub(active: true, trial: false, willRenew: false)],
      trialEligible: false,
    ));
    expect(m.state, MembershipState.subscribed);
    expect(m.willRenew, isFalse);
  });

  test('a dashboard grant is complimentary, with no plan behind it', () {
    final m = resolve(StoreAccount(
      entitlement: entitlement(
        active: true,
        granted: true,
        productId: 'rc_promo_forma_pro_lifetime',
        openEnded: true,
      ),
      subscriptions: const [],
      trialEligible: true,
    ));
    expect(m.state, MembershipState.complimentary);
    expect(m.entitled, isTrue);
    expect(m.overrideSource, 'granted');
    expect(m.productId, isNull);
    expect(m.expiresAt, isNull);
  });

  test('an entitlement that has run out defers to the history', () {
    final m = resolve(StoreAccount(
      entitlement: entitlement(
        active: false,
        trial: true,
        expiresAt: now.subtract(const Duration(days: 2)),
      ),
      subscriptions: [sub(active: false, trial: true)],
      trialEligible: false,
    ));
    expect(m.state, MembershipState.trialEnded);
    expect(m.locked, isTrue);
  });

  test('a paid plan that ran out locks as lapsed', () {
    final m = resolve(StoreAccount(
      subscriptions: [sub(active: false, trial: false)],
      trialEligible: false,
    ));
    expect(m.state, MembershipState.lapsed);
  });

  test('with several past periods the latest one decides the copy', () {
    final m = resolve(StoreAccount(
      subscriptions: [
        sub(
          active: false,
          trial: true,
          expiresAt: now.subtract(const Duration(days: 40)),
        ),
        sub(
          active: false,
          trial: false,
          productId: MembershipProducts.monthly,
          expiresAt: now.subtract(const Duration(days: 3)),
        ),
      ],
      trialEligible: false,
    ));
    expect(m.state, MembershipState.lapsed);
    expect(m.productId, MembershipProducts.monthly);
  });

  test('round-trips through json for the on-device cache', () {
    final original = Membership(
      state: MembershipState.trialing,
      expiresAt: now.add(const Duration(days: 3)),
      productId: MembershipProducts.monthly,
      willRenew: true,
      resolvedAt: now,
    );
    final copy = Membership.fromJson(original.toJson())!;
    expect(copy.state, original.state);
    expect(copy.expiresAt, original.expiresAt!.toUtc());
    expect(copy.productId, original.productId);
    expect(copy.willRenew, isTrue);
    expect(Membership.fromJson({'state': 'nonsense'}), isNull);
  });
}
