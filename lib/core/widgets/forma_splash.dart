import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Forma animated splash — "next node" motion.
///
/// Frame 0 is the FULLY LIT mark, pixel-identical to the native static splash
/// (the OS draws the same lit mark on #111016), so the takeover is invisible.
/// The mark keeps the storyboard's size rule (53% of screen width, capped by
/// 24% of screen height) and its exact centering — the wordmark is overlaid
/// below without shifting the mark. The sequence per cycle:
///   1. Hold the lit mark.
///   2. The constellation slides forward one node (884/1360 of the mark
///      width): the old node exits at the mark's edge, a dim track reveals
///      ahead.
///   3. The charge fills the new segment — bar, ring lap, node flood.
///   4. Ends fully lit again, so the loop (and a one-shot run) is seamless.
///
///   FormaSplash(onDone: () => Navigator.of(context).pushReplacement(...))
///
/// Leave [onDone] null to loop forever.
class FormaSplash extends StatefulWidget {
  final VoidCallback? onDone;
  final Duration duration;
  final bool showWordmark;

  const FormaSplash({
    super.key,
    this.onDone,
    this.duration = const Duration(milliseconds: 2500),
    this.showWordmark = true,
  });

  static const Color ink = Color(0xFF111016);
  static const Color blue = Color(0xFF3C7DFF);
  static const Color unlit = Color(0xFF1B2A4E);

  @override
  State<FormaSplash> createState() => _FormaSplashState();
}

class _FormaSplashState extends State<FormaSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.onDone == null) {
      _run.repeat();
    } else {
      _run.forward().whenComplete(widget.onDone!);
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    // The storyboard's rule: 53% of the width, capped so the mark's height
    // never passes 24% of the screen. Matching it keeps the handover from
    // the static splash invisible.
    final markWidth = math.min(
      viewport.width * 0.53,
      viewport.height * 0.24 * _MarkPainter.boxW / _MarkPainter.boxH,
    );
    final markHeight = markWidth * _MarkPainter.boxH / _MarkPainter.boxW;

    // Material, not ColoredBox: this widget is the app's `home`, and without
    // a Material ancestor the wordmark falls back to the framework's error
    // text style — yellow double-underline included.
    return Material(
      color: FormaSplash.ink,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The mark alone is centred — exactly where the storyboard puts
          // the static image.
          Center(
            child: AnimatedBuilder(
              animation: _run,
              builder: (_, __) => SizedBox(
                width: markWidth,
                height: markHeight,
                child: CustomPaint(
                  painter: _MarkPainter(
                    _run.value,
                    blue: FormaSplash.blue,
                    unlit: FormaSplash.unlit,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showWordmark)
            Center(
              child: Transform.translate(
                // Overlaid under the mark: half the mark, the gap, and half
                // the wordmark's own line — the mark itself never moves.
                offset: Offset(
                  0,
                  markHeight / 2 + markWidth * 0.12 + markWidth * 0.05,
                ),
                child: AnimatedBuilder(
                  animation: _run,
                  builder: (_, __) {
                    final t = _run.value;
                    final opacity = t < 0.14
                        ? 0.0
                        : t < 0.30
                            ? (t - 0.14) / 0.16
                            : t < 0.96
                                ? 1.0
                                : 1 - (t - 0.96) / 0.04;
                    return Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Text(
                        'FORMA',
                        style: TextStyle(
                          fontSize: markWidth * 0.078,
                          fontWeight: FontWeight.w800,
                          letterSpacing: markWidth * 0.028,
                          color: const Color(0xFFFAFAFA),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t, {required this.blue, required this.unlit});

  final double t;
  final Color blue;
  final Color unlit;

  static const boxW = 1360.0, boxH = 480.0;
  static const _step = 884.0; // node-to-node spacing = slide distance
  // segment 1 (lit at frame 0)
  static const _discC = Offset(234, 240), _discR = 236.5;
  static const _node1C = Offset(1118, 240);
  static const _bar1X1 = 374.0, _bar1X2 = 960.0;
  // segment 2 (revealed ahead, then filled)
  static const _node2C = Offset(2002, 240);
  static const _bar2X1 = 1258.0, _bar2X2 = 1844.0;
  static const _ringR = 199.0, _ringW = 75.0;
  static const _barY = 240.0, _barW = 130.0;
  static const _holeR = 160.0, _floodR = 236.5;

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  // cubic-bezier(x1,y1,x2,y2), Newton-solved — same curves as the CSS/SVG
  // version of the splash.
  static double _bez(double x, double x1, double y1, double x2, double y2) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    double c(double p) => 3 * p;
    double b(double p, double q) => 3 * (q - p) - c(p);
    double a(double p, double q) => 1 - c(p) - b(p, q);
    double calc(double u, double p, double q) =>
        ((a(p, q) * u + b(p, q)) * u + c(p)) * u;
    double slope(double u, double p, double q) =>
        3 * a(p, q) * u * u + 2 * b(p, q) * u + c(p);
    var u = x;
    for (var i = 0; i < 5; i++) {
      final s = slope(u, x1, x2);
      if (s == 0) break;
      u -= (calc(u, x1, x2) - x) / s;
    }
    return calc(u, y1, y2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / boxW;
    canvas.save();
    canvas.scale(k);
    // the mark's own bounds clip the exiting node — the "clean exit"
    canvas.clipRect(const Rect.fromLTWH(0, 0, boxW, boxH));

    final dx = -_step * _bez(_seg(t, 0.12, 0.34), .55, 0, .15, 1);
    final trackO = _seg(t, 0.10, 0.16);
    final pBar = _bez(_seg(t, 0.36, 0.58), .4, 0, .4, 1);
    final pArc = _bez(_seg(t, 0.54, 0.78), .35, 0, .4, 1);
    final pFill = _bez(_seg(t, 0.76, 0.90), .32, 1.25, .6, 1);

    canvas.translate(dx, 0);

    // the link never enters the next node's hole
    final barClip = Path()
      ..addRect(const Rect.fromLTWH(0, 0, 3000, boxH))
      ..addOval(Rect.fromCircle(center: _node2C, radius: _holeR))
      ..fillType = PathFillType.evenOdd;

    // dim track ahead (bar + ring), fading in as the slide begins
    if (trackO > 0) {
      final trackPaint = Paint()..color = unlit.withValues(alpha: trackO);
      canvas.save();
      canvas.clipPath(barClip);
      canvas.drawLine(
        const Offset(_bar2X1, _barY),
        const Offset(_bar2X2, _barY),
        trackPaint..strokeWidth = _barW,
      );
      canvas.restore();
      canvas.drawCircle(
        _node2C,
        _ringR,
        Paint()
          ..color = unlit.withValues(alpha: trackO)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringW,
      );
    }

    // lit link of the previous segment — fades out at the end of the slide
    // so no stub of it peeks past the anchor disc at the mark's left edge
    final linkO = 1 - _seg(t, 0.28, 0.34);
    if (linkO > 0) {
      canvas.drawLine(
        const Offset(_bar1X1, _barY),
        const Offset(_bar1X2, _barY),
        Paint()
          ..color = blue.withValues(alpha: linkO)
          ..strokeWidth = _barW,
      );
    }

    // ring lap on the next node — starts at the base, where the link meets
    // the ring, and sweeps a full clockwise lap (the SVG rotates the dashed
    // circle 180° for the same reason)
    if (pArc > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: _node2C, radius: _ringR),
        math.pi,
        pArc * 2 * math.pi,
        false,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringW
          ..strokeCap = StrokeCap.round,
      );
    }

    // charge along the new link
    if (pBar > 0) {
      canvas.save();
      canvas.clipPath(barClip);
      canvas.drawLine(
        const Offset(_bar2X1, _barY),
        Offset(_bar2X1 + (_bar2X2 - _bar2X1) * pBar, _barY),
        Paint()
          ..color = blue
          ..strokeWidth = _barW,
      );
      canvas.restore();
    }

    // lit node of the previous segment (the new anchor after the slide)
    canvas.drawCircle(_node1C, _floodR, Paint()..color = blue);

    // the next node floods, blooming from its centre like the SVG's
    // scale(0)→scale(1) flood
    if (pFill > 0) {
      canvas.drawCircle(_node2C, _floodR * pFill, Paint()..color = blue);
    }

    // mastered disc (exits during the slide)
    canvas.drawCircle(_discC, _discR, Paint()..color = blue);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t;
}
