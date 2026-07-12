import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/loading_indicator.dart';
import 'data/services/auth_service.dart';
import 'data/services/onboarding_service.dart';
import 'features/login/login_view.dart';
import 'features/onboarding/onboarding_view.dart';
import 'features/shell/shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const FormaApp());
}

class FormaApp extends StatelessWidget {
  const FormaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentPrimary,
          brightness: Brightness.dark,
          surface: AppColors.bg,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const _AppEntry(),
    );
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
/// onboarding profile, then into the main app.
class _OnboardingGate extends StatefulWidget {
  final String userId;

  const _OnboardingGate({super.key, required this.userId});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<bool> _completed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    _completed = OnboardingService().hasCompletedOnboarding(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _completed,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not load your profile.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(_check),
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
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }
        if (snapshot.data!) return const ShellView();
        return OnboardingView(
          // Block body: the arrow form would return the assigned Future out
          // of the setState callback, which setState rejects.
          onFinished: () => setState(() {
            _completed = Future.value(true);
          }),
        );
      },
    );
  }
}
