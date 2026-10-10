import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'analytics_service.dart';
import 'membership_service.dart';

/// Meta's SDK, there for the app-install campaigns. It gives Meta the three
/// things a server cannot: the install and every return to the foreground
/// (what an ad gets attributed to), the start of a free trial (Apple's
/// SKAdNetwork postback can only encode what the SDK saw on the device),
/// and the anonymous id it lends RevenueCat, so the conversions and
/// renewals RevenueCat sends Meta server-side land on the same person.
///
/// The SDK's automatic logging is off in both manifests, so it never logs a
/// purchase of its own: RevenueCat is the one source for those, and Meta
/// would otherwise count each twice. That leaves activateApp to be called
/// here — on launch and on every return to the foreground.
///
/// Never throws. Meta is a side channel; a failure here must cost the user
/// nothing.
class MetaAdsService with WidgetsBindingObserver {
  MetaAdsService._();

  /// The app-wide instance.
  static final instance = MetaAdsService._();

  final _events = FacebookAppEvents();

  /// Only the phones have the SDK behind the plugin; tests and desktop
  /// builds do not.
  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Starts the session with Meta and hands RevenueCat the anonymous id.
  /// Safe before sign-in: the membership service keeps the id until the
  /// store SDK is up.
  Future<void> setup() async {
    if (!_supported) return;
    WidgetsBinding.instance.addObserver(this);
    try {
      await _events.activateApp();
      final anonymousId = await _events.getAnonymousId();
      await MembershipService.instance
          .attachAdvertisingIdentity(metaAnonymousId: anonymousId);
    } catch (error) {
      debugPrint('Meta SDK setup failed: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _events.activateApp().catchError((Object error) {
      debugPrint('Meta activateApp failed: $error');
    });
  }

  // ── Tracking permission ──

  /// Whether onboarding should ask: iOS, and the system dialog has never
  /// been shown for this app. Android has no such prompt.
  Future<bool> shouldAskTracking() async {
    if (!_supported || !Platform.isIOS) return false;
    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus ==
          TrackingStatus.notDetermined;
    } catch (error) {
      debugPrint('Tracking status lookup failed: $error');
      return false;
    }
  }

  /// Shows the system tracking dialog and passes the answer on. Meta's SDK
  /// reads it from the system itself; RevenueCat is told by collecting the
  /// device identifiers again, which now include the IDFA when allowed,
  /// and the consent status either way. Returns the answer, or null when
  /// the dialog could not be shown; the caller moves on regardless.
  Future<TrackingStatus?> requestTracking() async {
    if (!_supported || !Platform.isIOS) return null;
    final TrackingStatus status;
    try {
      status = await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (error) {
      debugPrint('Tracking request failed: $error');
      return null;
    }
    AnalyticsService.capture('tracking_permission_answered', properties: {
      'status': status.name,
    });
    await MembershipService.instance.attachAdvertisingIdentity();
    return status;
  }

  // ── Events ──

  /// A free trial started on this device: the one subscription event Meta
  /// hears from the app rather than from RevenueCat, because the
  /// SKAdNetwork conversion value can only carry what was logged here.
  /// RevenueCat still reports it server-side under a name of its own, so
  /// Meta's StartTrial counts it once.
  Future<void> logTrialStarted({
    required String productId,
    required double price,
    required String currency,
    required String orderId,
  }) async {
    if (!_supported) return;
    try {
      await _events.logStartTrial(
        price: price,
        currency: currency,
        orderId: orderId,
        parameters: {'product_id': productId},
      );
    } catch (error) {
      debugPrint('Meta StartTrial failed: $error');
    }
  }
}
