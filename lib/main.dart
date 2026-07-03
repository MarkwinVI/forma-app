import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        textTheme: GoogleFonts.ibmPlexSansTextTheme(),
        primaryTextTheme: GoogleFonts.ibmPlexSansTextTheme(),
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
