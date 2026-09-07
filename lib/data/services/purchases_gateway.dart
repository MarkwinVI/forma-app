import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/membership_model.dart';

/// The user closed the App Store sheet without buying.
class PurchaseCancelled implements Exception {
  const PurchaseCancelled();
}

/// Everything the app asks of the store, behind one interface so the rest
/// of the app never names RevenueCat — swapping providers means swapping
/// this one implementation.
abstract class PurchasesGateway {
  /// Starts the SDK. Safe to call more than once.
  Future<void> configure({String? userId});

  /// Ties purchases to the signed-in account.
  Future<void> logIn(String userId);

  /// Back to an anonymous store identity after sign-out.
  Future<void> logOut();

  /// The store's current view of the user, fetched fresh.
  Future<StoreAccount> fetchAccount();

  /// The plans on sale, priced by the store.
  Future<List<MembershipPlan>> fetchPlans();

  /// Runs the App Store purchase. Throws [PurchaseCancelled] when the user
  /// backs out, anything else when the purchase failed.
  Future<StoreAccount> purchase(String productId);

  /// Asks the store for purchases made under this Apple ID.
  Future<StoreAccount> restore();

  /// Pushed by the SDK whenever the store's view changes — a renewal, a
  /// cancellation detected in the background, a purchase on another device.
  Stream<StoreAccount> get updates;
}

/// RevenueCat, over StoreKit.
class RevenueCatGateway implements PurchasesGateway {
  final _updates = StreamController<StoreAccount>.broadcast();
  final _productsById = <String, StoreProduct>{};

  bool _configured = false;
  bool? _trialEligible;

  @override
  Stream<StoreAccount> get updates => _updates.stream;

  @override
  Future<void> configure({String? userId}) async {
    if (_configured) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(AppConfig.revenueCatApiKey)..appUserID = userId,
    );
    _configured = true;
    Purchases.addCustomerInfoUpdateListener((info) {
      _updates.add(_toAccount(info));
    });
  }

  @override
  Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
    // Eligibility is per Apple ID, not per account, but a new identity is
    // a good moment to re-ask.
    _trialEligible = null;
  }

  @override
  Future<void> logOut() async {
    // Logging out an already-anonymous identity throws; there is nothing
    // to undo in that case.
    try {
      if (!await Purchases.isAnonymous) await Purchases.logOut();
    } catch (error) {
      debugPrint('RevenueCat logOut skipped: $error');
    }
    _trialEligible = null;
  }

  @override
  Future<StoreAccount> fetchAccount() async {
    final (info, eligible) = await (
      Purchases.getCustomerInfo(),
      _fetchTrialEligibility(),
    ).wait;
    _trialEligible = eligible;
    return _toAccount(info);
  }

  /// Whether Apple would still grant the trial: eligible on any plan counts,
  /// ineligible only when every plan says so, otherwise unknown.
  Future<bool?> _fetchTrialEligibility() async {
    try {
      final map = await Purchases.checkTrialOrIntroductoryPriceEligibility(
        MembershipProducts.all,
      );
      final statuses = map.values.map((e) => e.status).toList();
      if (statuses.contains(
        IntroEligibilityStatus.introEligibilityStatusEligible,
      )) {
        return true;
      }
      if (statuses.isNotEmpty &&
          statuses.every(
            (s) => s == IntroEligibilityStatus.introEligibilityStatusIneligible,
          )) {
        return false;
      }
      return null;
    } catch (error) {
      debugPrint('Trial eligibility check failed: $error');
      return null;
    }
  }

  @override
  Future<List<MembershipPlan>> fetchPlans() async {
    final products = await Purchases.getProducts(MembershipProducts.all);
    final plans = <MembershipPlan>[];
    for (final product in products) {
      _productsById[product.identifier] = product;
      plans.add(_toPlan(product));
    }
    // Yearly first, the way the sheet lists them.
    plans.sort((a, b) => a.isYearly ? -1 : (b.isYearly ? 1 : 0));
    return plans;
  }

  @override
  Future<StoreAccount> purchase(String productId) async {
    final product = _productsById[productId] ??
        (await Purchases.getProducts([productId])).firstOrNull;
    if (product == null) {
      throw StateError('Product $productId is not available in the store.');
    }
    try {
      final result =
          await Purchases.purchase(PurchaseParams.storeProduct(product));
      // A purchase uses the trial up, whatever the last check said.
      _trialEligible = false;
      return _toAccount(result.customerInfo);
    } on PlatformException catch (error) {
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelled();
      }
      rethrow;
    }
  }

  @override
  Future<StoreAccount> restore() async {
    final info = await Purchases.restorePurchases();
    return _toAccount(info);
  }

  StoreAccount _toAccount(CustomerInfo info) {
    return StoreAccount(
      subscriptions: [
        for (final sub in info.subscriptionsByProductIdentifier.values)
          if (MembershipProducts.all.contains(sub.productIdentifier))
            StoreSubscription(
              productId: sub.productIdentifier,
              isActive: sub.isActive,
              expiresAt: _parseDate(sub.expiresDate),
              willRenew: sub.willRenew,
              isTrial: sub.periodType == PeriodType.trial,
            ),
      ],
      trialEligible: _trialEligible,
    );
  }

  static DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toLocal();

  static MembershipPlan _toPlan(StoreProduct product) {
    final yearly = MembershipProducts.isYearly(product.identifier);
    String? monthly;
    if (yearly) {
      monthly = product.pricePerMonthString ??
          NumberFormat.simpleCurrency(name: product.currencyCode)
              .format(product.price / 12);
    }
    return MembershipPlan(
      productId: product.identifier,
      price: product.price,
      currencyCode: product.currencyCode,
      priceString: product.priceString,
      monthlyEquivalentString: monthly,
      trialDays: _trialDays(product.introductoryPrice),
    );
  }

  /// The free trial's length in days, 0 unless the intro offer is free.
  static int _trialDays(IntroductoryPrice? intro) {
    if (intro == null || intro.price != 0) return 0;
    final units = intro.periodNumberOfUnits * intro.cycles.clamp(1, 1 << 20);
    return switch (intro.periodUnit) {
      PeriodUnit.day => units,
      PeriodUnit.week => units * 7,
      PeriodUnit.month => units * 30,
      PeriodUnit.year => units * 365,
      PeriodUnit.unknown => 0,
    };
  }
}
