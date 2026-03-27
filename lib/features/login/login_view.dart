import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/services/auth_service.dart';
import '../shell/shell_view.dart';

// Local opacity variants not in the global palette (specific to this screen)
const _heroTextDim = Color(0x99FFFFFF);    // white 60%
const _subtitleDim = Color(0x66FFFFFF);    // white 40%
const _iconBg      = Color(0x1AFF6900);    // accent 10%
const _iconBorder  = Color(0x4DFF6900);    // accent 30%

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _authService = AuthService();
  bool _isLoading = false;

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
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 34),
              const _BrandLogo(),
              const SizedBox(height: 46),
              const _HeroText(),
              const Spacer(),
              const _FeatureItem(
                icon: Icons.sports_gymnastics,
                title: 'Learn cool calisthenics skills',
                description: 'Custom programs based on your current abilities and goals.',
              ),
              const SizedBox(height: 16),
              const _FeatureItem(
                icon: Icons.show_chart,
                title: 'Track progress',
                description: 'See real improvements as you work towards elite skills.',
              ),
              const SizedBox(height: 16),
              const _FeatureItem(
                icon: Icons.workspace_premium_outlined,
                title: 'Get world class advice',
                description: 'Master advanced skills through proven progressions.',
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const Center(child: LoadingIndicator())
              else
                ..._buildButtons(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 16 / 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtons() {
    return [
      _AppleButton(onPressed: () => _signIn(() => _authService.signInWithApple())),
      if (kDebugMode) ...[
        const SizedBox(height: 12),
        _DevButton(onPressed: () => _signIn(() => _authService.signInAnonymously())),
      ],
    ];
  }
}

// ---------------------------------------------------------------------------

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'FORMA',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 46 / 44,
            ),
            children: const [
              TextSpan(text: 'Level up\n', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'your body.', style: TextStyle(color: _heroTextDim)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Calisthenics decoded. A clear path from foundation to mastery.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _subtitleDim,
            letterSpacing: -0.15,
            height: 23 / 14,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _iconBg,
            border: Border.all(color: _iconBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: AppColors.accentPrimary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.44,
                  height: 27 / 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.15,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AppleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 20, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              'Continue with Apple',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.3125,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DevButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Center(
          child: Text(
            'Dev Login (anonymous)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
