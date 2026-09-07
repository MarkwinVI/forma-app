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

  test('nothing known: locked, trial offered', () {
    final m = resolveMembership(store: null, override: null, now: now);
    expect(m.state, MembershipState.trialAvailable);
    expect(m.locked, isTrue);
    expect(m.trialOffered, isTrue);
  });

  test('never a member and Apple says the trial is used up: subscribe only',
      () {
    final m = resolveMembership(
      store: const StoreAccount(subscriptions: [], trialEligible: false),
      override: null,
      now: now,
    );
    expect(m.state, MembershipState.subscribeOnly);
    expect(m.trialOffered, isFalse);
  });

  test('an active trial unlocks as trialing, with its end date', () {
    final m = resolveMembership(
      store: StoreAccount(
        subscriptions: [sub(active: true, trial: true)],
        trialEligible: false,
      ),
      override: null,
      now: now,
    );
    expect(m.state, MembershipState.trialing);
    expect(m.entitled, isTrue);
    expect(m.daysLeft(now), 5);
    expect(m.productId, MembershipProducts.yearly);
  });

  test('an active paid period is subscribed', () {
    final m = resolveMembership(
      store: StoreAccount(
        subscriptions: [sub(active: true, trial: false, willRenew: false)],
        trialEligible: false,
      ),
      override: null,
      now: now,
    );
    expect(m.state, MembershipState.subscribed);
    expect(m.willRenew, isFalse);
  });

  test('a trial that ran out locks as trialEnded', () {
    final m = resolveMembership(
      store: StoreAccount(
        subscriptions: [sub(active: false, trial: true)],
        trialEligible: false,
      ),
      override: null,
      now: now,
    );
    expect(m.state, MembershipState.trialEnded);
    expect(m.locked, isTrue);
  });

  test('a paid plan that ran out locks as lapsed', () {
    final m = resolveMembership(
      store: StoreAccount(
        subscriptions: [sub(active: false, trial: false)],
        trialEligible: false,
      ),
      override: null,
      now: now,
    );
    expect(m.state, MembershipState.lapsed);
  });

  test('with several past periods the latest one decides the copy', () {
    final m = resolveMembership(
      store: StoreAccount(
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
      ),
      override: null,
      now: now,
    );
    expect(m.state, MembershipState.lapsed);
    expect(m.productId, MembershipProducts.monthly);
  });

  test('a live override beats the store', () {
    final m = resolveMembership(
      store: StoreAccount(
        subscriptions: [sub(active: false, trial: true)],
        trialEligible: false,
      ),
      override: const MembershipOverride(source: 'grandfathered'),
      now: now,
    );
    expect(m.state, MembershipState.complimentary);
    expect(m.overrideSource, 'grandfathered');
    expect(m.expiresAt, isNull);
  });

  test('an expired override is ignored', () {
    final m = resolveMembership(
      store: null,
      override: MembershipOverride(
        source: 'comped',
        expiresAt: now.subtract(const Duration(days: 1)),
      ),
      now: now,
    );
    expect(m.state, MembershipState.trialAvailable);
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
