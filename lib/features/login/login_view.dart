import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_links.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.screen('login');
  }

  /// Apple's button on Apple's platform; everywhere else the account most
  /// people already have on the device is Google.
  static bool get _usesApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _signIn(Future<dynamic> Function() method) async {
    setState(() => _isLoading = true);
    try {
      // _AppEntry listens to auth state and swaps to the shell on success.
      await method();
    } on SignInWithAppleAuthorizationException catch (e) {
      // User dismissed the Apple sign-in sheet — not an error.
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please try again.')),
      );
    } on GoogleSignInException catch (e) {
      // Likewise for the Google account sheet.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('Google sign in failed: ${e.code} ${e.description}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please try again.')),
      );
    } catch (e) {
      debugPrint('Sign in failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: _BrandMark(),
            ),
            // The headline sits centred in the space between the mark and the
            // sign-in block, and scrolls if it must; the sign-in block below
            // never moves.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_WelcomeHeadline()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Pinned to the bottom of the page: the sign-in button and the
            // terms line, wherever the pitch above ends.
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The pressed state stays on the page: the button reports
                  // itself rather than opening a spinner over everything.
                  if (_isLoading)
                    const _SigningInButton()
                  else if (_usesApple)
                    _AppleButton(
                      onPressed: () =>
                          _signIn(() => _authService.signInWithApple()),
                    )
                  else
                    _GoogleButton(
                      onPressed: () =>
                          _signIn(() => _authService.signInWithGoogle()),
                    ),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    Text(
                      _usesApple
                          ? 'Apple is confirming your account.'
                          : 'Google is confirming your account.',
                      textAlign: TextAlign.center,
                      style: _footerStyle,
                    )
                  else
                    const _PrivacyFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FORMA',
          style: monoStyle(
            size: 12,
            letterSpacing: 3.1,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// "From your first <skill> to <skill>" — real moves only, cycling for as
/// long as the page is up.
class _WelcomeHeadline extends StatefulWidget {
  const _WelcomeHeadline();

  @override
  State<_WelcomeHeadline> createState() => _WelcomeHeadlineState();
}

class _WelcomeHeadlineState extends State<_WelcomeHeadline> {
  static const _pairs = [
    ('pull-up', 'muscle-up'),
    ('push-up', 'handstand'),
    ('squat', 'l-sit'),
  ];
  static const _style = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1.06,
    color: AppColors.textPrimary,
  );

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// Cycles for as long as the page is on screen — it never settles.
  void _schedule() {
    _timer = Timer(
      Duration(milliseconds: _index == 0 ? 1250 : 1450),
      () {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % _pairs.length);
        _schedule();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _slot(String word) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      child: Text(
        word,
        key: ValueKey(word),
        style: _style.copyWith(color: AppColors.accentPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = _pairs[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('From your first', style: _style),
        _slot(pair.$1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('to ', style: _style),
            Flexible(child: _slot(pair.$2)),
          ],
        ),
      ],
    );
  }
}

class _AppleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AppleButton({required this.onPressed});

  /// The HIG's recommended height; the title is 43% of it, the logo
  /// artwork runs the full height, and the page's pill radius is allowed.
  static const double _height = 44;
  static const double _fontSize = _height * 0.43;

  @override
  Widget build(BuildContext context) {
    // A custom Sign in with Apple button, built to the HIG's proportions:
    // white fill on the dark page, black system-font title at 43% of the
    // height, the Apple logo from the official artwork (the package's
    // painter) at the button's height, title centred, "Continue with Apple"
    // as one of the sanctioned labels. The package's own widget sets the
    // title in the regular weight, which reads thin next to the page's
    // type; the HIG allows a custom button to adjust the weight.
    return Pressable(
      onTap: onPressed,
      semanticLabel: 'Continue with Apple',
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The logo file's proportions: the glyph is 25:31 at the title
            // size and sits a touch above the baseline.
            Padding(
              padding: EdgeInsets.only(
                bottom: _height * 4 / 44,
                right: _fontSize * 0.3,
              ),
              child: SizedBox(
                width: _fontSize * 25 / 31,
                height: _fontSize,
                child: CustomPaint(
                  painter: AppleLogoPainter(color: Colors.black),
                ),
              ),
            ),
            // Titles vary in length by locale; the HIG asks for at least 8%
            // of the width clear on the right, so a long one scales down
            // rather than clipping.
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Continue with Apple',
                    maxLines: 1,
                    style: TextStyle(
                      inherit: false,
                      fontFamily: '.SF Pro Text',
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.41,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _footerStyle = TextStyle(
  fontSize: 12.5,
  color: AppColors.textMuted,
  height: 1.5,
);

/// The consent line under the sign-in button. "Terms" and "Privacy Policy"
/// link to the published pages; they open in the browser so the sign-in
/// flow stays where it is.
class _PrivacyFooter extends StatefulWidget {
  const _PrivacyFooter();

  static final termsUrl = AppLinks.terms;
  static final privacyUrl = AppLinks.privacy;

  @override
  State<_PrivacyFooter> createState() => _PrivacyFooterState();
}

class _PrivacyFooterState extends State<_PrivacyFooter> {
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => _open(_PrivacyFooter.termsUrl, 'terms');
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => _open(_PrivacyFooter.privacyUrl, 'privacy policy');

  static const _linkStyle = TextStyle(
    color: AppColors.textPrimary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textMuted,
  );

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(Uri url, String label) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Couldn't open the $label.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: _footerStyle,
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(text: 'Terms', recognizer: _termsTap, style: _linkStyle),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            recognizer: _privacyTap,
            style: _linkStyle,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  static const double _height = _AppleButton._height;
  static const double _fontSize = _AppleButton._fontSize;

  @override
  Widget build(BuildContext context) {
    // The Apple button's twin for Android: same white pill and height, the
    // Google "G" at the title size and a "Continue with Google" title, so
    // the page reads the same on both platforms.
    return Pressable(
      onTap: onPressed,
      semanticLabel: 'Continue with Google',
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: _fontSize * 0.45),
              child: SizedBox(
                width: _fontSize,
                height: _fontSize,
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Continue with Google',
                    maxLines: 1,
                    style: TextStyle(
                      inherit: false,
                      fontFamily: 'Roboto',
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google's four-colour "G", drawn as a ring in the brand colours with the
/// blue bar across the opening, so no bitmap asset is needed.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final d = math.min(size.width, size.height);
    final stroke = d * 0.2;
    final rect = Rect.fromLTWH(
      (size.width - d) / 2 + stroke / 2,
      (size.height - d) / 2 + stroke / 2,
      d - stroke,
      d - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Degrees run clockwise from 3 o'clock. The opening at the top right
    // (between red and the bar) is what makes it a G rather than an O.
    void arc(Color color, double from, double to) {
      paint.color = color;
      canvas.drawArc(
        rect,
        from * math.pi / 180,
        (to - from) * math.pi / 180,
        false,
        paint,
      );
    }

    arc(_blue, 0, 48);
    arc(_green, 48, 135);
    arc(_yellow, 135, 225);
    arc(_red, 225, 315);

    // The bar: from the centre to the ring's outer edge, as tall as the
    // ring is thick, sitting on the horizontal centre line.
    final barPaint = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTRB(
        rect.center.dx,
        rect.center.dy - stroke / 2,
        rect.right + stroke / 2,
        rect.center.dy + stroke / 2,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SigningInButton extends StatelessWidget {
  const _SigningInButton();

  @override
  Widget build(BuildContext context) {
    // Same height as the Apple button it stands in for, so nothing jumps.
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'SIGNING IN…',
        style: monoStyle(
          size: 12.5,
          letterSpacing: 1.75,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
