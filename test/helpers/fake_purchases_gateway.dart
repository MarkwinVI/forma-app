import 'dart:async';

import 'package:forma_app/data/models/membership_model.dart';
import 'package:forma_app/data/services/purchases_gateway.dart';

/// A store that answers with whatever the test puts in it.
class FakePurchasesGateway implements PurchasesGateway {
  StoreAccount account;
  List<MembershipPlan> plans;

  /// What [purchase] does: null buys [account] as-is with the product
  /// active; a value throws it.
  Object? purchaseError;
  Object? plansError;
  Object? accountError;

  final purchased = <String>[];
  var restores = 0;
  var configured = false;
  String? loggedIn;
  var logOuts = 0;

  final _updates = StreamController<StoreAccount>.broadcast();

  FakePurchasesGateway({
    this.account = StoreAccount.empty,
    List<MembershipPlan>? plans,
  }) : plans = plans ?? defaultPlans;

  static const yearly = MembershipPlan(
    productId: MembershipProducts.yearly,
    price: 49.99,
    currencyCode: 'USD',
    priceString: r'$49.99',
    monthlyEquivalentString: r'$4.17',
    trialDays: 7,
  );

  static const monthly = MembershipPlan(
    productId: MembershipProducts.monthly,
    price: 9.99,
    currencyCode: 'USD',
    priceString: r'$9.99',
    monthlyEquivalentString: null,
    trialDays: 7,
  );

  static const defaultPlans = [yearly, monthly];

  /// Pushes a store-side change, the way the SDK's listener would.
  void emit(StoreAccount next) {
    account = next;
    _updates.add(next);
  }

  @override
  Stream<StoreAccount> get updates => _updates.stream;

  @override
  Future<void> configure({String? userId}) async {
    configured = true;
    loggedIn = userId;
  }

  @override
  Future<void> logIn(String userId) async => loggedIn = userId;

  @override
  Future<void> logOut() async {
    loggedIn = null;
    logOuts++;
  }

  @override
  Future<StoreAccount> fetchAccount() async {
    final error = accountError;
    if (error != null) throw error;
    return account;
  }

  @override
  Future<List<MembershipPlan>> fetchPlans() async {
    final error = plansError;
    if (error != null) throw error;
    return plans;
  }

  @override
  Future<StoreAccount> purchase(String productId) async {
    final error = purchaseError;
    if (error != null) throw error;
    purchased.add(productId);
    account = StoreAccount(
      subscriptions: [
        StoreSubscription(
          productId: productId,
          isActive: true,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          willRenew: true,
          isTrial: account.trialEligible != false,
        ),
      ],
      trialEligible: false,
    );
    return account;
  }

  @override
  Future<StoreAccount> restore() async {
    restores++;
    return account;
  }
}
