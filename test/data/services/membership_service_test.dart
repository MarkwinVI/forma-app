import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/membership_model.dart';
import 'package:forma_app/data/services/membership_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_purchases_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Thrown by the override fetch while set — cleared to bring it back.
  Object? overrideError;

  final now = DateTime(2026, 9, 7, 12);
  const user = 'user-1';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // The service follows the auth session, so a (never signed-in)
    // Supabase has to exist.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    overrideError = null;
  });

  MembershipService service({
    required FakePurchasesGateway gateway,
    MembershipOverride? override,
  }) =>
      MembershipService(
        gateway: gateway,
        fetchOverride: (_) async {
          final error = overrideError;
          if (error != null) throw error;
          return override;
        },
        now: () => now,
      );

  StoreAccount activeTrial() => StoreAccount(
        subscriptions: [
          StoreSubscription(
            productId: MembershipProducts.yearly,
            isActive: true,
            expiresAt: now.add(const Duration(days: 6)),
            willRenew: true,
            isTrial: true,
          ),
        ],
        trialEligible: false,
      );

  test('setup starts the store under the signed-in user and load resolves',
      () async {
    final gateway = FakePurchasesGateway(account: activeTrial());
    final s = service(gateway: gateway);
    await s.setup();
    expect(gateway.configured, isTrue);

    final membership = await s.load(user);
    expect(membership.state, MembershipState.trialing);
    expect(s.current?.state, MembershipState.trialing);
    expect(s.notifier.value, same(membership));
  });

  test('the server override wins over the store', () async {
    final gateway = FakePurchasesGateway(account: activeTrial());
    final s = service(
      gateway: gateway,
      override: const MembershipOverride(source: 'comped'),
    );
    await s.setup();
    expect((await s.load(user)).state, MembershipState.complimentary);
  });

  test('a resolve that fails falls back to the cached copy', () async {
    final first = service(gateway: FakePurchasesGateway(account: activeTrial()));
    await first.setup();
    await first.load(user);
    // The cache write is fire-and-forget; let it land.
    await Future<void>.delayed(Duration.zero);

    final gateway = FakePurchasesGateway()..accountError = Exception('offline');
    overrideError = Exception('down');
    final second = service(gateway: gateway);
    await second.setup();
    final membership = await second.load(user);
    expect(membership.state, MembershipState.trialing,
        reason: 'the cache stands in for the network');

    // And the failure is not memoized: the next load asks again.
    gateway.accountError = null;
    overrideError = null;
    gateway.account = StoreAccount.empty;
    final again = await second.refresh();
    expect(again.state, MembershipState.trialAvailable);
  });

  test('with no cache and no network, the answer asks rather than assumes',
      () async {
    final gateway = FakePurchasesGateway()..accountError = Exception('offline');
    overrideError = Exception('down');
    final s = service(gateway: gateway);
    await s.setup();
    final membership = await s.load(user);
    expect(membership.state, MembershipState.trialAvailable);
    expect(membership.locked, isTrue);
  });

  test('a purchase publishes the new membership at once', () async {
    final gateway = FakePurchasesGateway();
    final s = service(gateway: gateway);
    await s.setup();
    expect((await s.load(user)).locked, isTrue);

    final membership = await s.purchase(MembershipProducts.yearly);
    expect(gateway.purchased, [MembershipProducts.yearly]);
    expect(membership.entitled, isTrue);
    expect(s.current?.entitled, isTrue);
  });

  test('a store-side change re-resolves against the last override',
      () async {
    final gateway = FakePurchasesGateway();
    final s = service(gateway: gateway);
    await s.setup();
    expect((await s.load(user)).locked, isTrue);

    gateway.emit(activeTrial());
    await Future<void>.delayed(Duration.zero);
    expect(s.current?.state, MembershipState.trialing);
  });

  test('plans are fetched once, unless the fetch failed', () async {
    final gateway = FakePurchasesGateway()..plansError = Exception('store');
    final s = service(gateway: gateway);
    await expectLater(s.plans(), throwsException);
    gateway.plansError = null;
    expect(await s.plans(), hasLength(2));
  });
}
