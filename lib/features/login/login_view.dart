import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const _values = [
    (
      'Learn cool calisthenics skills',
      'A program built around your level and goals.',
    ),
    (
      'Track progress',
      'Watch your strength climb toward elite skills.',
    ),
    (
      'Get world class advice',
      'Every skill broken into steps that work.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The pitch scrolls if it must; the sign-in block below never
            // moves.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: _BrandMark(),
                    ),
                    // Full-bleed: the graph runs past the page margin on
                    // both sides.
                    const _ConstellationHero(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _HeroText(),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColors.divider),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < _values.length; i++)
                                  _ValueRow(
                                    name: _values[i].$1,
                                    sub: _values[i].$2,
                                    last: i == _values.length - 1,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.76,
              height: 0.98,
              color: AppColors.textPrimary,
            ),
            children: [
              TextSpan(text: 'Level up\n'),
              TextSpan(
                text: 'your body.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String name;
  final String sub;
  final bool last;

  const _ValueRow({required this.name, required this.sub, required this.last});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 13, bottom: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.37,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
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

  static final termsUrl = Uri.parse('https://tryforma.co/terms');
  static final privacyUrl = Uri.parse('https://tryforma.co/privacy');

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

// ── Hero constellation ────────────────────────────────────────────────

/// The app's own progression graph as the hero: the spine draws itself in and
/// the nodes light one by one up to a haloed skill still ahead, so "level up"
/// happens on screen rather than being claimed in copy. The run loops.
class _ConstellationHero extends StatefulWidget {
  const _ConstellationHero();

  @override
  State<_ConstellationHero> createState() => _ConstellationHeroState();
}

class _ConstellationHeroState extends State<_ConstellationHero>
    with TickerProviderStateMixin {
  /// One pass of the drawing sequence, then a hold before it runs again.
  late final AnimationController _run;

  /// The halo on the node still ahead, and the glow behind everything — both
  /// keep breathing after the draw finishes so the screen is never fully
  /// still.
  late final AnimationController _halo;
  late final AnimationController _glow;

  /// Whether the loops have been started (or deliberately held) — decided
  /// once, on the first build, when MediaQuery can say if motion is reduced.
  var _started = false;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    );
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduce Motion: the graph fully drawn, the halo at mid-breath and the
      // glow at its peak — the frame the loop keeps returning to, held.
      _run.value = 1;
      _halo.value = 0.5;
      _glow.value = 0.25;
      return;
    }
    _run.repeat();
    _halo.repeat();
    _glow.repeat();
  }

  @override
  void dispose() {
    _run.dispose();
    _halo.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 165,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_run, _halo, _glow]),
        builder: (context, _) => CustomPaint(
          painter: _ConstellationPainter(
            seconds: _run.value * 7.2,
            halo: _halo.value,
            glow: _glow.value,
          ),
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  /// Elapsed seconds into the current run — every element starts from its own
  /// offset, which is what makes the graph build rather than appear.
  final double seconds;
  final double halo;
  final double glow;

  const _ConstellationPainter({
    required this.seconds,
    required this.halo,
    required this.glow,
  });

  /// Laid out on the design's 402 × 230 grid. The first and last nodes sit
  /// past the edges, so the graph reads as part of something larger.
  static const _nodes = [
    Offset(-8, 214),
    Offset(58, 196),
    Offset(124, 168),
    Offset(190, 176),
    Offset(256, 130),
    Offset(322, 96),
    Offset(392, 44),
    Offset(150, 96),
    Offset(300, 190),
  ];
  static const _links = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 5),
    (5, 6),
    (2, 7),
    (4, 8),
  ];

  /// The node the sequence climbs to — it stays haloed, a skill still ahead.
  static const _peak = 6;

  @override
  void paint(Canvas canvas, Size size) {
    // The layout is drawn on a 402 × 230 grid but the box may be shorter —
    // the graph compresses vertically to fit rather than clipping.
    final scale = size.width / 402;
    final scaleY = size.height / 230;
    Offset at(Offset point) => Offset(point.dx * scale, point.dy * scaleY);

    // Blue bloom behind the graph, breathing on its own cycle.
    final glowOpacity = 0.55 + 0.35 * math.sin(glow * 2 * math.pi);
    canvas.drawCircle(
      at(const Offset(300, 90)),
      180 * scale,
      Paint()
        ..color = AppColors.accentPrimary.withValues(alpha: 0.20 * glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    for (var i = 0; i < _links.length; i++) {
      final (from, to) = _links[i];
      // Links off the spine are the paths not taken yet: dashed, unlit.
      final isSpine = to == from + 1;
      final progress = _phase(start: 0.12 + i * 0.14, duration: 1.5);
      if (progress <= 0) continue;

      final a = at(_nodes[from]);
      final b = at(_nodes[to]);
      final head = Offset.lerp(a, b, progress)!;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isSpine ? 1.4 : 1.1
        ..color = isSpine
            ? AppColors.accentPrimary.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.12);

      if (isSpine) {
        canvas.drawLine(a, head, paint);
      } else {
        _dashedLine(canvas, a, head, paint);
      }
    }

    for (var i = 0; i < _nodes.length; i++) {
      final center = at(_nodes[i]);
      final lit = Curves.easeOut.transform(
        _phase(start: 0.3 + i * 0.16, duration: 0.9),
      );
      final radius = (i == _peak ? 12.0 : 9.5) * scale;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Color.lerp(
            AppColors.bg.withValues(alpha: 0.7),
            AppColors.accentPrimary.withValues(alpha: 0.16),
            lit,
          )!,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = Color.lerp(
            Colors.white.withValues(alpha: 0.16),
            AppColors.accentPrimary,
            lit,
          )!,
      );

      // The peak keeps a slow ring pushing outward once it is lit.
      if (i == _peak && lit > 0) {
        canvas.drawCircle(
          center,
          radius * (1 + 1.1 * halo),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = AppColors.accentPrimary
                .withValues(alpha: 0.5 * (1 - halo) * lit),
        );
      }
    }
  }

  /// 0 before [start], 1 once [duration] has passed, linear between.
  double _phase({required double start, required double duration}) {
    return ((seconds - start) / duration).clamp(0.0, 1.0);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0, gap = 5.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final step = (b - a) / total;
    for (var travelled = 0.0; travelled < total; travelled += dash + gap) {
      final end = math.min(travelled + dash, total);
      canvas.drawLine(a + step * travelled, a + step * end, paint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      oldDelegate.halo != halo ||
      oldDelegate.glow != glow;
}
