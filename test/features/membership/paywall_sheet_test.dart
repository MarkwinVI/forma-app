import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/membership_model.dart';
import 'package:forma_app/data/services/membership_service.dart';
import 'package:forma_app/data/services/purchases_gateway.dart';
import 'package:forma_app/features/membership/paywall_sheet.dart';
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

  Future<Future<bool>> open(
    WidgetTester tester,
    MembershipService service,
  ) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    late Future<bool> result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => result = showPaywallSheet(
                context,
                service: service,
                source: 'test',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('offers the trial with both plans priced by the store',
      (tester) async {
    final (s, _) = await service();
    await open(tester, s);

    expect(find.text('Try Forma free for 7 days'), findsOneWidget);
    expect(find.text('Today — full access'), findsOneWidget);
    expect(find.text('Day 7 — billing starts'), findsOneWidget);
    // No reminders are promised anywhere on the sheet.
    expect(find.textContaining('remind'), findsNothing);
    expect(find.textContaining('notify'), findsNothing);

    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('SAVE 58%'), findsOneWidget);
    expect(find.text(r'$49.99'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text('Start free trial'), findsOneWidget);
    expect(
      find.textContaining(r'$0.00 today · then $49.99 / year after 7 days'),
      findsOneWidget,
    );
  });

  testWidgets('a completed purchase closes the sheet as a member',
      (tester) async {
    final (s, gateway) = await service();
    final result = await open(tester, s);

    // The plans sit low on a tall sheet: bring the card into view first.
    await tester.ensureVisible(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pump();
    await tester.tap(find.text('Start free trial'));
    await tester.pumpAndSettle();

    expect(gateway.purchased, [MembershipProducts.monthly]);
    expect(await result, isTrue);
    expect(s.current?.entitled, isTrue);
    expect(find.text('Start free trial'), findsNothing);

    // The one confirmation, with no reminder promised.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Trial started'), findsOneWidget);
    expect(find.textContaining('Full access until'), findsOneWidget);
    expect(find.textContaining('remind'), findsNothing);
    // And it leaves on its own (the hold and the two slides need frames).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Trial started'), findsNothing);
  });

  testWidgets('backing out of the App Store sheet keeps the paywall open',
      (tester) async {
    final (s, gateway) = await service();
    gateway.purchaseError = const PurchaseCancelled();
    await open(tester, s);

    await tester.tap(find.text('Start free trial'));
    await tester.pumpAndSettle();

    expect(find.text('Start free trial'), findsOneWidget);
    expect(find.textContaining("didn't go through"), findsNothing);
    expect(s.current?.locked, isTrue);
  });

  testWidgets('a failed purchase says so in place', (tester) async {
    final (s, gateway) = await service();
    gateway.purchaseError = Exception('store down');
    await open(tester, s);

    await tester.tap(find.text('Start free trial'));
    await tester.pumpAndSettle();

    expect(find.textContaining("didn't go through"), findsOneWidget);
  });

  testWidgets('with the trial used up it sells the plan, billed today',
      (tester) async {
    final (s, _) = await service(
      account: const StoreAccount(subscriptions: [], trialEligible: false),
    );
    await open(tester, s);

    expect(find.text('Choose your plan'), findsOneWidget);
    expect(find.text('Today — full access'), findsNothing);
    expect(find.text(r'Subscribe · $49.99 / year'), findsOneWidget);
    expect(find.textContaining('Billed today · renews yearly'), findsOneWidget);
  });

  testWidgets('restore that finds nothing says so and stays', (tester) async {
    final (s, gateway) = await service();
    await open(tester, s);

    // "Restore" is a span in the legal line, not a widget of its own.
    await tester.tapOnText(find.textRange.ofSubstring('Restore'));
    await tester.pumpAndSettle();

    expect(gateway.restores, 1);
    expect(find.textContaining('No active subscription'), findsOneWidget);
    expect(find.text('Start free trial'), findsOneWidget);
  });
}
