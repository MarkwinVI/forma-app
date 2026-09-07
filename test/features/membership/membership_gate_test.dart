import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/membership_model.dart';
import 'package:forma_app/data/services/membership_service.dart';
import 'package:forma_app/features/membership/membership_gate.dart';
import 'package:forma_app/features/membership/membership_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_purchases_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(MembershipService, FakePurchasesGateway)> service({
    StoreAccount account = StoreAccount.empty,
  }) async {
    final gateway = FakePurchasesGateway(account: account);
    final s = MembershipService(
      gateway: gateway,
      fetchOverride: (_) async => null,
    );
    await s.setup();
    await s.load('user');
    return (s, gateway);
  }

  Future<int> pump(
    WidgetTester tester,
    MembershipService service, {
    required bool hasProgram,
  }) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: MembershipScope(
        service: service,
        child: Scaffold(
          body: MembershipGate(
            hasProgram: ValueNotifier(hasProgram),
            service: service,
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Start session'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session'), warnIfMissed: false);
    await tester.pump();
    return taps;
  }

  StoreAccount trialEnded() => StoreAccount(
        subscriptions: [
          StoreSubscription(
            productId: MembershipProducts.yearly,
            isActive: false,
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
            willRenew: false,
            isTrial: true,
          ),
        ],
        trialEligible: false,
      );

  testWidgets(
      'with a program and no membership, the page is inert under '
      'the lock dock', (tester) async {
    final (s, _) = await service();
    final taps = await pump(tester, s, hasProgram: true);

    expect(taps, 0);
    expect(find.text('Start free trial'), findsOneWidget);
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(find.textContaining('Your program is saved'), findsOneWidget);
  });

  testWidgets(
      'without a program there is no lock — setup must stay '
      'reachable', (tester) async {
    final (s, _) = await service();
    final taps = await pump(tester, s, hasProgram: false);
    expect(taps, 1);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
  });

  testWidgets('the copy follows how the user got locked out', (tester) async {
    final (s, _) = await service(account: trialEnded());
    await pump(tester, s, hasProgram: true);
    expect(find.text('Your free trial has ended'), findsOneWidget);
    expect(find.text(r'Subscribe · $9.99 / month'), findsOneWidget);
    expect(find.textContaining(r'or $49.99 / year'), findsOneWidget);
  });

  testWidgets('a purchase landing lifts the lock in place', (tester) async {
    final (s, gateway) = await service();
    expect(await pump(tester, s, hasProgram: true), 0);

    gateway.emit(StoreAccount(
      subscriptions: [
        StoreSubscription(
          productId: MembershipProducts.monthly,
          isActive: true,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          willRenew: true,
          isTrial: true,
        ),
      ],
      trialEligible: false,
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    await tester.tap(find.text('Start session'));
    expect(find.text('Start session'), findsOneWidget);
  });
}
