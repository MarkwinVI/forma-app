import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../data/services/auth_service.dart';
import '../shell/shell_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleAppleSignIn() async {
    await _signIn(() => _authService.signInWithApple());
  }

  Future<void> _handleDevLogin() async {
    await _signIn(() => _authService.signInAnonymously());
  }

  Future<void> _signIn(Future<dynamic> Function() method) async {
    setState(() => _isLoading = true);
    try {
      await method();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellView()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Forma',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const LoadingIndicator()
              else
                ..._buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtons() {
    return [
      SignInWithAppleButton(onPressed: _handleAppleSignIn),
      if (kDebugMode) ...[
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _handleDevLogin,
          child: const Text('Dev Login (anonymous)'),
        ),
      ],
    ];
  }
}
