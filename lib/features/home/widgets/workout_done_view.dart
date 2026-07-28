import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../home_dashboard_metrics.dart';

/// Post-workout "session complete" state of the Train tab — a celebratory
/// burst (expanding rings, twinkling sparks, a popping check) over a green
/// glow, the finished session's stats, a "view workout" action, and the next
/// session. The insight block is rendered separately by the caller.
class WorkoutDoneView extends StatefulWidget {
  final HomeCompletedWorkoutSummary completed;

  /// Next training session title (e.g. "Upper Day") and how far away it is
  /// (e.g. "tomorrow"). Both null hides the "next up" row.
  final String? nextTitle;
  final String? nextWhen;
  final VoidCallback? onViewWorkout;

  const WorkoutDoneView({
    super.key,
    required this.completed,
    this.nextTitle,
    this.nextWhen,
    this.onViewWorkout,
  });

  @override
  State<WorkoutDoneView> createState() => _WorkoutDoneViewState();
}

class _WorkoutDoneViewState extends State<WorkoutDoneView>
    with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final AnimationController _rings;
  late final AnimationController _sparks;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _sparks = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _pop.dispose();
    _rings.dispose();
    _sparks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.completed;
    final stats = '${c.durationMinutes} min · ${c.setCount} sets';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Celebration burst — the green glow lives inside the burst and fades
        // to transparent before the edges, so it never seams against the
        // week strip above.
        const SizedBox(height: 8),
        SizedBox(
          height: 244,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pop, _rings, _sparks]),
            builder: (context, _) => _Burst(
              pop: _pop.value,
              rings: _rings.value,
              sparks: _sparks.value,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Left-aligned from here down: the finish reads as a statement, not a
        // certificate.
        Text(
          'SESSION COMPLETE',
          style: monoStyle(size: 11, letterSpacing: 1.65, color: AppColors.green),
        ),
        const SizedBox(height: 12),
        Text(
          '${c.title}, done',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.4,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          stats,
          style: const TextStyle(
            fontSize: 15.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 30),
        if (widget.onViewWorkout != null)
          Pressable(
            onTap: widget.onViewWorkout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              alignment: Alignment.center,
              child: const Text(
                'View workout',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.17,
                ),
              ),
            ),
          ),
        if (widget.nextTitle != null) _nextUpRow(),
      ],
    );
  }

  /// Static line — what comes next is context for the session just finished,
  /// not somewhere to go from here.
  Widget _nextUpRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('NEXT UP', style: monoStyle(size: 10.5, letterSpacing: 1.5)),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: widget.nextTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.32,
                ),
                children: [
                  if (widget.nextWhen != null)
                    TextSpan(
                      text: ' · ${widget.nextWhen}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The animated celebration: expanding rings, twinkling sparks, and a check
/// that pops in. All phases come from the parent's controllers.
class _Burst extends StatelessWidget {
  // (fractional x, fractional y, diameter, color, phase 0-1)
  static final _sparks = <(double, double, double, Color, double)>[
    (0.189, 0.414, 4, AppColors.accentPrimary, 0.00),
    (0.323, 0.228, 3, _light, 0.15),
    (0.498, 0.152, 5, AppColors.green, 0.30),
    (0.706, 0.248, 3, AppColors.accentPrimary, 0.075),
    (0.821, 0.448, 4, _light, 0.40),
    (0.139, 0.690, 3, AppColors.green, 0.225),
    (0.861, 0.724, 3, AppColors.accentPrimary, 0.50),
    (0.274, 0.869, 4, _light, 0.35),
    (0.726, 0.890, 4, AppColors.green, 0.125),
  ];
  static const _light = Color(0xFFDDE3FF);

  final double pop;
  final double rings;
  final double sparks;

  const _Burst({required this.pop, required this.rings, required this.sparks});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft green glow, transparent well before the edges — no seam.
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 0.46,
              colors: [Color(0xFF17251D), Colors.transparent],
            ),
          ),
        ),
        // Expanding ring pulses.
        for (var i = 0; i < 3; i++) _ring((rings + i / 3) % 1),
        // Twinkling sparks.
        for (final s in _sparks) _spark(s),
        // Popping check badge.
        Transform.scale(
          scale: Curves.easeOutBack.transform(pop.clamp(0.0, 1.0)),
          child: Opacity(
            opacity: (pop * 2).clamp(0.0, 1.0),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greenSoft,
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: AppColors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ring(double phase) {
    final scale = 0.5 + phase;
    final opacity = (0.5 * (1 - phase)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.green.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _spark((double, double, double, Color, double) s) {
    final (fx, fy, size, color, phase) = s;
    final local = (sparks + phase) % 1;
    final tri = 1 - (2 * local - 1).abs(); // 0 → 1 → 0
    final opacity = (0.15 + 0.8 * tri).clamp(0.0, 1.0);
    final dy = -8.0 * tri;
    return Align(
      alignment: Alignment(fx * 2 - 1, fy * 2 - 1),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}
