import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/services/auth_service.dart';

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
      // _AppEntry listens to auth state and swaps to the shell on success.
      await method();
    } on SignInWithAppleAuthorizationException catch (e) {
      // User dismissed the Apple sign-in sheet — not an error.
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please try again.')),
      );
    } catch (e) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: _BrandMark(),
              ),
              // Full-bleed: the graph runs past the page margin on both sides.
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
                    const SizedBox(height: 30),
                    // The pressed state stays on the page: the button reports
                    // itself rather than opening a spinner over everything.
                    if (_isLoading)
                      const _SigningInButton()
                    else
                      _AppleButton(
                        onTap: () =>
                            _signIn(() => _authService.signInWithApple()),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      _isLoading
                          ? 'Apple is confirming your account.'
                          : 'By continuing you agree to our Terms and '
                              'Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
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
  final VoidCallback onTap;

  const _AppleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, size: 22, color: Colors.black),
            SizedBox(width: 9),
            Text(
              'Continue with Apple',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: -0.17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SigningInButton extends StatelessWidget {
  const _SigningInButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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

  @override
  void initState() {
    super.initState();
    _run = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
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
