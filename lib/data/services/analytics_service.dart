import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import 'auth_service.dart';

/// Product analytics, wrapped so the rest of the app never talks to PostHog
/// directly. Screens call [capture] with an event name and go on with their
/// work: if setup never ran (tests, or setup failed on device) every call is
/// a silent no-op, so analytics can never take the app down with it.
class AnalyticsService {
  static var _enabled = false;

  /// Starts PostHog and ties its identity to the Supabase session: events
  /// belong to the signed-in account, and sign-out cuts the link so the next
  /// account on this device starts a fresh profile.
  static Future<void> setup() async {
    try {
      final config = PostHogConfig(AppConfig.posthogApiKey)
        ..host = AppConfig.posthogHost
        ..debug = kDebugMode
        ..captureApplicationLifecycleEvents = true;
      await Posthog().setup(config);
      _enabled = true;
    } catch (error) {
      debugPrint('PostHog setup failed, analytics disabled: $error');
      return;
    }

    final signedIn = AuthService().currentUser;
    if (signedIn != null) {
      unawaited(Posthog().identify(userId: signedIn.id));
    }
    AuthService().onAuthStateChange.listen((state) {
      final user = state.session?.user;
      if (state.event == AuthChangeEvent.signedOut) {
        unawaited(Posthog().reset());
      } else if (user != null) {
        // Re-identifying with the same id is a no-op inside the SDK, so
        // token refreshes cost nothing.
        unawaited(Posthog().identify(userId: user.id));
      }
    });
  }

  static void capture(String event, {Map<String, Object>? properties}) {
    if (!_enabled) return;
    unawaited(Posthog().capture(eventName: event, properties: properties));
  }
}
