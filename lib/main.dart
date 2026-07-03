import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'data/services/auth_service.dart';
import 'features/login/login_view.dart';
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
        return user != null ? const ShellView() : const LoginView();
      },
    );
  }
}
