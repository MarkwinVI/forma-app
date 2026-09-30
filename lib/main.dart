import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_theme.dart';
import 'core/widgets/forma_splash.dart';
import 'core/widgets/loading_indicator.dart';
import 'data/services/analytics_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/dev_tools_service.dart';
import 'data/services/membership_service.dart';
import 'data/services/onboarding_service.dart';
import 'data/services/training_program_store_service.dart';
import 'data/services/weight_unit_service.dart';
import 'features/home/program_setup_completion.dart';
import 'features/home/program_setup_view.dart';
import 'features/login/login_view.dart';
import 'features/onboarding/onboarding_view.dart';
import 'features/progress/skill_wheel_bundle.dart';
import 'features/shell/shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    // Every screen is designed portrait. The platform has to allow landscape
    // so a video can turn sideways for fullscreen, so the lock lives here
    // instead of in the manifests, and the player lifts it for as long as it
    // needs it.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]),
    Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    ),
    // The remembered kg/lbs choice, restored before any weight is rendered.
    WeightUnitService.load(),
  ]);

  // After Supabase: both read the restored auth session. Neither throws.
  await Future.wait([
    AnalyticsService.setup(),
    MembershipService.instance.setup(),
  ]);

  _warmStartupData();

  runApp(const FormaApp());
}

/// Fires a signed-in user's startup queries so they run behind the splash
/// animation instead of after it. The gates and the landing tab then resolve
/// from work that is already done — the caches involved make sure the app,
/// not this warm-up, stays the owner of every result.
void _warmStartupData() {
  final userId = AuthService().currentUser?.id;
  if (userId == null) return;

  OnboardingService().hasCompletedOnboarding(userId).ignore();
  // Membership resolves behind the splash too — the shell waits for it
  // before its first frame, so a locked tab never flashes unlocked.
  MembershipService.instance.load(userId).ignore();
  // Also seeds TrainingProgramStoreService's logic cache, which the shell
  // reads to pick the landing tab.
  warmSkillWheelBundle(userId);
}

class FormaApp extends StatelessWidget {
  const FormaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forma',
      debugShowCheckedModeBanner: false,
      // The copy is English; dates, month names and the 12/24-hour clock
      // follow the device. Every Material locale is accepted so the device
      // locale resolves instead of falling back to en_US.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [
        for (final tag in kMaterialSupportedLanguages) Locale(tag),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentPrimary,
          brightness: Brightness.dark,
          surface: AppColors.bg,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        splashFactory: NoSplash.splashFactory,
        textTheme: formaTextTheme,
      ),
      // Dynamic Type follows the reader's setting up to 1.6×. Past that the
      // fixed-height rows and pinned buttons start swallowing their own
      // text; below 1.0 the type is already as small as it is designed to go.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.6,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  var _splashComplete = false;

  void _finishSplash() {
    if (!mounted) return;
    setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_splashComplete) return const _AppEntry();
    return FormaSplash(onDone: _finishSplash);
  }
}

/// Switches between the login and main app based on the auth session,
/// reacting to sign-in, sign-out, and session expiry.
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().onAuthStateChange,
      builder: (context, snapshot) {
        final user = AuthService().currentUser;
        if (user == null) return const LoginView();
        // Keyed by user id so a different account (e.g. re-registration
        // after deleting an account) re-checks onboarding from scratch.
        return _OnboardingGate(key: ValueKey(user.id), userId: user.id);
      },
    );
  }
}

/// Routes a signed-in user through onboarding until they have a saved
/// onboarding profile, then on to [_ProgramGate].
class _OnboardingGate extends StatefulWidget {
  final String userId;

  const _OnboardingGate({super.key, required this.userId});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<bool> _completed;

  /// Set when onboarding finishes right here, so the gate goes straight on
  /// without a frame of loader while a resolved future settles.
  var _finishedHere = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    _completed = OnboardingService().hasCompletedOnboarding(widget.userId);
    // The program gate asks next; start its lookup behind onboarding so the
    // answer is usually in by the time onboarding is.
    TrainingProgramStoreService().fetchProgramLogic(widget.userId).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final programGate = _ProgramGate(userId: widget.userId);
    if (_finishedHere) return programGate;
    return FutureBuilder<bool>(
      future: _completed,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _GateLoadFailed(
            message: 'Could not load your profile.',
            onRetry: () => setState(_check),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }
        if (snapshot.data!) return programGate;
        return OnboardingView(
          // Block body: the arrow form would return the assigned Future out
          // of the setState callback, which setState rejects.
          onFinished: () => setState(() {
            _completed = Future.value(true);
            _finishedHere = true;
          }),
        );
      },
    );
  }
}

/// Routes an onboarded user into the setup wizard until they have a
/// training program, then into the main app. The tabs have no screens for an
/// account without a program, so the shell is never shown before one exists.
class _ProgramGate extends StatefulWidget {
  final String userId;

  const _ProgramGate({required this.userId});

  @override
  State<_ProgramGate> createState() => _ProgramGateState();
}

class _ProgramGateState extends State<_ProgramGate> {
  late Future<bool> _hasProgram;

  /// Set when the wizard finishes right here, so the gate goes straight on
  /// to the shell without re-reading what it just wrote.
  var _builtHere = false;

  @override
  void initState() {
    super.initState();
    _check();
    DevToolsService.resetSignal.addListener(_onReset);
  }

  @override
  void dispose() {
    DevToolsService.resetSignal.removeListener(_onReset);
    super.dispose();
  }

  void _check() {
    _hasProgram = TrainingProgramStoreService()
        .fetchProgramLogic(widget.userId)
        .then((logic) => logic != null);
  }

  /// A dev reset deleted the program out from under the shell: back to the
  /// wizard.
  void _onReset() {
    if (!mounted) return;
    setState(() {
      _builtHere = false;
      _check();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_builtHere) return const ShellView();
    return FutureBuilder<bool>(
      future: _hasProgram,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _GateLoadFailed(
            message: 'Could not load your program.',
            onRetry: () => setState(_check),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }
        if (snapshot.data!) return const ShellView();
        return ProgramSetupView(
          onComplete: (result) => completeProgramSetup(
            userId: widget.userId,
            result: result,
          ),
          onDone: () => setState(() => _builtHere = true),
        );
      },
    );
  }
}

/// What a gate shows when its lookup failed: the problem, and Retry.
class _GateLoadFailed extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GateLoadFailed({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.accentPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
