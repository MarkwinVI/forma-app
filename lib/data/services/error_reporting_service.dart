import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import 'auth_service.dart';

/// Crash and error reporting, wrapped so the rest of the app never talks to
/// Sentry directly. [run] starts the SDK before anything else in `main`, so
/// a throw anywhere in startup is reported like any other. With no DSN
/// configured the SDK stays off and every call here is a silent no-op, so
/// error reporting can never take the app down with it.
class ErrorReportingService {
  /// Starts Sentry, then runs [startApp] inside its error zone. Uncaught
  /// Flutter errors — a build that throws — and uncaught Dart errors are
  /// reported without further wiring. The release is the bundle id at the
  /// version and build (`tryforma.co@1.1.4+17` on iOS, `co.tryforma.app@…`
  /// on Android) and the environment is `debug`, `profile` or `production`
  /// by build mode, both set by the SDK.
  static Future<void> run(FutureOr<void> Function() startApp) {
    return SentryFlutter.init(
      (options) {
        options
          ..dsn = AppConfig.sentryDsn
          // Tracing: app start and screen navigation timing. Every run in a
          // debug build, one in ten in production so it stays within quota.
          ..tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
        // sendDefaultPii stays off: no IP address on reports. The one
        // personal field attached is the account id, from [bindUser].
      },
      appRunner: startApp,
    );
  }

  /// Tags every report with the signed-in Supabase account — the id only,
  /// so an issue can be matched to a user row without carrying the email —
  /// and clears it on sign-out. Call once Supabase is initialised.
  static void bindUser() {
    _setUser(AuthService().currentUser);
    AuthService().onAuthStateChange.listen((state) {
      // A signed-out state carries no session, so this also clears the id.
      _setUser(state.session?.user);
    });
  }

  static void _setUser(User? user) {
    Sentry.configureScope(
      (scope) => scope.setUser(user == null ? null : SentryUser(id: user.id)),
    );
  }

  /// Reports an error the app caught and carried on from, so a failure that
  /// is swallowed on purpose still shows up in Sentry.
  static void report(Object error, StackTrace? stackTrace) {
    unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  }
}
