import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Forma animated splash — the charge fills the link, runs one lap around the
/// open node, then floods it solid. Geometry matches the Forma brand mark.
class FormaSplash extends StatefulWidget {
  const FormaSplash({
    super.key,
    this.onDone,
    this.showWordmark = true,
    this.duration = const Duration(milliseconds: 3600),
  });

  final VoidCallback? onDone;
  final bool showWordmark;
  final Duration duration;

  @override
  State<FormaSplash> createState() => _FormaSplashState();
}

class _FormaSplashState extends State<FormaSplash>
    with SingleTickerProviderStateMixin {
  static const ink = Color(0xFF111016);
  static const blue = Color(0xFF3C7DFF);
  static const unlit = Color(0xFF1B2A4E);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.onDone == null) {
      _controller.repeat();
    } else {
      _controller.forward().whenComplete(widget.onDone!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final markWidth = math.min(viewport.width * 0.53, viewport.height * 0.24);

    // Material, not ColoredBox: this widget is the app's `home`, and without
    // a Material ancestor the wordmark falls back to the framework's error
    // text style — yellow double-underline included.
    return Material(
      color: ink,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => SizedBox(
                width: markWidth,
                height: markWidth * 480 / 1360,
                child: CustomPaint(
                  painter: _MarkPainter(
                    _controller.value,
                    blue: blue,
                    unlit: unlit,
                  ),
                ),
              ),
            ),
            if (widget.showWordmark) ...[
              SizedBox(height: markWidth * 0.12),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final progress = _controller.value;
                  final opacity = progress < 0.56
                      ? 0.0
                      : progress < 0.74
                          ? (progress - 0.56) / 0.18
                          : progress < 0.90
                              ? 1.0
                              : 1 - (progress - 0.90) / 0.10;
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
            ],
          ],
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.progress, {required this.blue, required this.unlit});

  final double progress;
  final Color blue;
  final Color unlit;

  static const _boxWidth = 1360.0;
  static const _boxHeight = 480.0;
  static const _discCenter = Offset(234, 240);
  static const _discRadius = 232.0;
  static const _ringCenter = Offset(1118, 240);
  static const _ringRadius = 199.0;
  static const _ringWidth = 75.0;
  static const _barY = 240.0;
  static const _barStart = 374.0;
  static const _barEnd = 960.0;
  static const _barWidth = 130.0;
  static const _holeRadius = 160.0;
  static const _floodRadius = 236.5;

  static double _segment(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0);

  static double _bezier(
    double x,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;

    double a(double p, double q) => 1 - 3 * q + 3 * p;
    double b(double p, double q) => 3 * q - 6 * p;
    double c(double p) => 3 * p;
    double calculate(double value, double p, double q) =>
        ((a(p, q) * value + b(p, q)) * value + c(p)) * value;
    double slope(double value, double p, double q) =>
        3 * a(p, q) * value * value + 2 * b(p, q) * value + c(p);

    var value = x;
    for (var i = 0; i < 8; i++) {
      final currentSlope = slope(value, x1, x2);
      if (currentSlope == 0) break;
      value -= (calculate(value, x1, x2) - x) / currentSlope;
    }
    return calculate(value, y1, y2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _boxWidth;
    canvas
      ..save()
      ..scale(scale);

    final alpha = progress < 0.92 ? 1.0 : 1 - _segment(progress, 0.92, 1);
    if (alpha < 1) {
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, _boxWidth, _boxHeight),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }

    final barClip = Path()
      ..addRect(const Rect.fromLTWH(0, 0, _boxWidth, _boxHeight))
      ..addOval(Rect.fromCircle(center: _ringCenter, radius: _holeRadius))
      ..fillType = PathFillType.evenOdd;

    canvas
      ..save()
      ..clipPath(barClip)
      ..drawLine(
        const Offset(_barStart, _barY),
        const Offset(_barEnd, _barY),
        Paint()
          ..color = unlit
          ..strokeWidth = _barWidth,
      )
      ..restore()
      ..drawCircle(
        _ringCenter,
        _ringRadius,
        Paint()
          ..color = unlit
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );

    final arcProgress = _bezier(
      _segment(progress, 0.30, 0.70),
      .35,
      0,
      .4,
      1,
    );
    if (arcProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: _ringCenter, radius: _ringRadius),
        math.pi,
        arcProgress * 2 * math.pi,
        false,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    final barProgress = _bezier(
      _segment(progress, 0, 0.32),
      .4,
      0,
      .4,
      1,
    );
    if (barProgress > 0) {
      canvas
        ..save()
        ..clipPath(barClip)
        ..drawLine(
          const Offset(_barStart, _barY),
          Offset(_barStart + (_barEnd - _barStart) * barProgress, _barY),
          Paint()
            ..color = blue
            ..strokeWidth = _barWidth,
        )
        ..restore();
    }

    final fillProgress = _bezier(
      _segment(progress, 0.70, 0.86),
      .32,
      1.25,
      .6,
      1,
    );
    if (fillProgress > 0) {
      canvas.drawCircle(
        _ringCenter,
        _floodRadius * fillProgress,
        Paint()..color = blue,
      );
    }

    canvas.drawCircle(_discCenter, _discRadius, Paint()..color = blue);

    if (alpha < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
