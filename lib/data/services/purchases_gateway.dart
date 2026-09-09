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

  /// Ties purchases to the signed-in account. The email rides along as a
  /// customer attribute so a person is findable by it in the dashboard.
  Future<void> logIn(String userId, {String? email});

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

  /// Sends the purchases already on this device to the store's backend
  /// under the current identity — the quiet half of [restore], with no
  /// App Store prompt. How a subscription follows someone to a new
  /// account.
  Future<StoreAccount> syncPurchases();

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
  Future<void> logIn(String userId, {String? email}) async {
    await Purchases.logIn(userId);
    if (email != null && email.isNotEmpty) await Purchases.setEmail(email);
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
    var products = await Purchases.getProducts(MembershipProducts.all);
    // A store that only exposes its products through an offering (the
    // Test Store, an App Store Connect product not yet attached to a
    // version) answers the direct lookup with nothing.
    if (products.isEmpty) products = await _productsFromOfferings();
    if (products.isEmpty) {
      throw StateError(
        'The store returned none of ${MembershipProducts.all.join(', ')}. '
        'Check the products exist for this app in RevenueCat (the Test '
        'Store app in debug builds) and in App Store Connect.',
      );
    }
    final plans = <MembershipPlan>[];
    for (final product in products) {
      _productsById[product.identifier] = product;
      plans.add(_toPlan(product));
    }
    // Yearly first, the way the sheet lists them.
    plans.sort((a, b) => a.isYearly ? -1 : (b.isYearly ? 1 : 0));
    return plans;
  }

  Future<List<StoreProduct>> _productsFromOfferings() async {
    final offerings = await Purchases.getOfferings();
    final seen = <String>{};
    return [
      for (final offering in [
        if (offerings.current != null) offerings.current!,
        ...offerings.all.values,
      ])
        for (final package in offering.availablePackages)
          if (MembershipProducts.isKnown(package.storeProduct.identifier) &&
              seen.add(package.storeProduct.identifier))
            package.storeProduct,
    ];
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

  @override
  Future<StoreAccount> syncPurchases() async {
    await Purchases.syncPurchases();
    return _toAccount(await Purchases.getCustomerInfo());
  }

  StoreAccount _toAccount(CustomerInfo info) {
    final entitlement = info.entitlements.all[MembershipProducts.entitlement];
    return StoreAccount(
      entitlement: entitlement == null
          ? null
          : StoreEntitlement(
              isActive: entitlement.isActive,
              productId: entitlement.productIdentifier,
              expiresAt: _parseDate(entitlement.expirationDate),
              willRenew: entitlement.willRenew,
              isTrial: entitlement.periodType == PeriodType.trial,
              isGranted: entitlement.store == Store.promotional,
            ),
      subscriptions: [
        for (final sub in info.subscriptionsByProductIdentifier.values)
          if (MembershipProducts.isKnown(sub.productIdentifier))
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
      // Apple's own per-month string when it is a real twelfth; the Test
      // Store hands back the full yearly price here, so anything not
      // smaller than the price is recomputed.
      final perMonth = product.pricePerMonth;
      monthly = perMonth != null &&
              perMonth > 0 &&
              perMonth < product.price &&
              product.pricePerMonthString != null
          ? product.pricePerMonthString
          : NumberFormat.simpleCurrency(name: product.currencyCode)
              .format(product.price / 12);
    }
    return MembershipPlan(
      productId: product.identifier,
      price: product.price,
      currencyCode: product.currencyCode,
      priceString: product.priceString,
      monthlyEquivalentString: monthly,
      trialDays: _trialDays(product),
      debugInfo: kDebugMode ? _describe(product) : null,
    );
  }

  /// The free trial's length in days, 0 when the product carries none.
  ///
  /// Apple reports it as the introductory price; other stores (the Test
  /// Store among them) as a free pricing phase on a subscription option,
  /// or as a zero-priced discount. All three are read.
  static int _trialDays(StoreProduct product) {
    final intro = product.introductoryPrice;
    if (intro != null && intro.price == 0) {
      return _days(
        intro.periodUnit,
        intro.periodNumberOfUnits * intro.cycles.clamp(1, 1 << 20),
      );
    }
    for (final option in [
      if (product.defaultOption != null) product.defaultOption!,
      ...?product.subscriptionOptions,
    ]) {
      final free = option.freePhase;
      final period = free?.billingPeriod;
      if (period != null) {
        final days = _days(period.unit, period.value);
        if (days > 0) return days;
      }
    }
    for (final discount
        in product.discounts ?? const <StoreProductDiscount>[]) {
      if (discount.price != 0) continue;
      final unit = PeriodUnit.values
          .where((u) => u.name == discount.periodUnit.toLowerCase())
          .firstOrNull;
      if (unit == null) continue;
      final days = _days(
        unit,
        discount.periodNumberOfUnits * discount.cycles.clamp(1, 1 << 20),
      );
      if (days > 0) return days;
    }
    return 0;
  }

  static int _days(PeriodUnit unit, int units) => switch (unit) {
        PeriodUnit.day => units,
        PeriodUnit.week => units * 7,
        PeriodUnit.month => units * 30,
        PeriodUnit.year => units * 365,
        PeriodUnit.unknown => 0,
      };

  /// One line of what the store reported, for the debug paywall.
  static String _describe(StoreProduct product) {
    final intro = product.introductoryPrice;
    final option = product.defaultOption;
    return '${product.identifier}: period=${product.subscriptionPeriod ?? '?'}'
        ' intro=${intro == null ? 'none' : '${intro.priceString}/${intro.periodNumberOfUnits}${intro.periodUnit.name}×${intro.cycles}'}'
        ' free=${option?.freePhase?.billingPeriod?.iso8601 ?? 'none'}'
        ' discounts=${product.discounts?.length ?? 0}'
        ' options=${product.subscriptionOptions?.length ?? 0}';
  }
}
