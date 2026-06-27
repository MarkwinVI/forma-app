import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';

const _detailBg = AppColors.bgSecondary;
const _detailCard = Color(0xFF0D0D10);
const _detailSurface = Color(0x08FFFFFF);
const _detailSurfaceBorder = Color(0x14FFFFFF);
const _detailBad = Color(0xFFFF6B57);
const _detailGood = AppColors.accentBright;

Future<T?> openExerciseDetailView<T>(
  BuildContext context, {
  required Exercise exercise,
  Color accentColor = AppColors.accentPrimary,
  String? skillCategoryId,
  List<String>? focusChips,
  bool autoScrollToProgress = false,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => ExerciseDetailView(
        exercise: exercise,
        accentColor: accentColor,
        skillCategoryId: skillCategoryId,
        focusChips: focusChips,
        autoScrollToProgress: autoScrollToProgress,
      ),
    ),
  );
}

class ExerciseDetailView extends StatefulWidget {
  final Exercise exercise;
  final Color accentColor;
  final String? skillCategoryId;
  final List<String>? focusChips;
  final bool autoScrollToProgress;

  const ExerciseDetailView({
    super.key,
    required this.exercise,
    this.accentColor = AppColors.accentPrimary,
    this.skillCategoryId,
    this.focusChips,
    this.autoScrollToProgress = false,
  });

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  final _exerciseLogService = ExerciseLogService();
  final _scrollController = ScrollController();
  final _progressKey = GlobalKey();

  late Future<List<ExerciseLog>> _logsFuture;
  String? _openLogId;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadLogs();
    if (widget.autoScrollToProgress) {
      _logsFuture.whenComplete(() {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToProgress();
        });
      });
    }
  }

  Future<List<ExerciseLog>> _loadLogs() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return const [];
    return _exerciseLogService.fetchForExercise(userId, widget.exercise.id);
  }

  String get _resolvedSkillCategoryId {
    final requestedId = widget.skillCategoryId;
    if (requestedId != null && requestedId.isNotEmpty) {
      return requestedId;
    }
    return ExerciseCatalog.skillCategoryIdForExercise(widget.exercise);
  }

  Future<void> _scrollToProgress() async {
    final context = _progressKey.currentContext;
    if (context == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject == null) return;
    await _scrollController.position.ensureVisible(
      renderObject,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final skillCategory =
        SkillCategoryCatalog.findById(_resolvedSkillCategoryId);
    final coachData = _coachDataFor(exercise);
    final targetPlan = _targetPlanFor(exercise);
    final branchLabel = _branchLabel(exercise.branchId);

    return Scaffold(
      backgroundColor: _detailBg,
      body: FutureBuilder<List<ExerciseLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <ExerciseLog>[];
          final summary = logs.isEmpty
              ? null
              : _ExerciseHistorySummary.fromLogs(
                  logs: logs,
                  isTimed: _isTimedExercise(exercise),
                );

          if (_openLogId == null && logs.isNotEmpty) {
            _openLogId = logs.first.id;
          }

          return SafeArea(
            bottom: false,
            child: Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 28),
                  children: [
                    _DemoCard(
                      exercise: exercise,
                      color: widget.accentColor,
                    ),
                    _PeekStrip(
                      summary: summary,
                      accentColor: widget.accentColor,
                      onTap: _scrollToProgress,
                    ),
                    _HeaderBlock(
                      exercise: exercise,
                      trackLabel:
                          skillCategory?.title ?? exercise.category.label,
                      branchLabel: branchLabel,
                      targetPlan: targetPlan,
                    ),
                    _HowToSection(
                      steps: coachData.steps,
                      accentColor: widget.accentColor,
                    ),
                    _FormCheckSection(
                      cues: coachData.formChecks,
                      accentColor: widget.accentColor,
                    ),
                    Container(
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            widget.accentColor.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                    KeyedSubtree(
                      key: _progressKey,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                        child: _ProgressBlock(
                          logs: logs,
                          summary: summary,
                          isTimed: _isTimedExercise(exercise),
                          accentColor: widget.accentColor,
                          loading:
                              snapshot.connectionState != ConnectionState.done,
                          hasError: snapshot.hasError,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _HistorySection(
                        logs: logs,
                        openLogId: _openLogId,
                        accentColor: widget.accentColor,
                        isTimed: _isTimedExercise(exercise),
                        onToggle: (logId) {
                          setState(() {
                            _openLogId = _openLogId == logId ? null : logId;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: _BackPill(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;

  const _BackPill({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.48),
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: _detailSurfaceBorder),
        ),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
      label: Text(
        'BACK',
        style: GoogleFonts.ibmPlexSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final Exercise exercise;
  final Color color;

  const _DemoCard({
    required this.exercise,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: _detailCard,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    const Color(0xFF080809),
                    const Color(0xFF050505),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DemoGridPainter(
                  accentColor: color.withValues(alpha: 0.14),
                ),
              ),
            ),
            if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  exercise.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.55, 1.0],
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

class _PeekStrip extends StatelessWidget {
  final _ExerciseHistorySummary? summary;
  final Color accentColor;
  final VoidCallback onTap;

  const _PeekStrip({
    required this.summary,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalLabel = summary == null
        ? '--'
        : summary!.isTimed
            ? _formatSecondsCompact(summary!.latestPrimary)
            : '${summary!.latestPrimary}';
    final deltaLabel = summary == null
        ? ''
        : '${summary!.primaryDelta >= 0 ? '↑' : '↓'}${summary!.isTimed ? _formatSecondsCompact(summary!.primaryDelta.abs()) : summary!.primaryDelta.abs()}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
          decoration: BoxDecoration(
            border: const Border(
              top: BorderSide(color: _detailSurfaceBorder),
              bottom: BorderSide(color: _detailSurfaceBorder),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalLabel,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      summary?.isTimed == true ? 'HOLD' : 'REPS',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (deltaLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        deltaLabel,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: summary!.primaryDelta >= 0
                              ? _detailGood
                              : _detailBad,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: summary == null
                    ? const SizedBox.shrink()
                    : _MiniSparkline(
                        values: summary!.timelineValues,
                        color: accentColor,
                      ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PROGRESS',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scroll for history',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<int> values;
  final Color color;

  const _MiniSparkline({
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  final Exercise exercise;
  final String trackLabel;
  final String branchLabel;
  final _ExerciseTargetPlan targetPlan;

  const _HeaderBlock({
    required this.exercise,
    required this.trackLabel,
    required this.branchLabel,
    required this.targetPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${trackLabel.toUpperCase()} / ${branchLabel.toUpperCase()}',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 0.94,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _detailSurfaceBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeaderMetric(
                    label: 'Target',
                    value: targetPlan.targetLabel,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow('Level'),
                      const SizedBox(height: 6),
                      Text(
                        _levelLabel(exercise.difficulty).toUpperCase(),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.robotoMono(
        fontSize: 12,
        color: AppColors.textMuted,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _HowToSection extends StatelessWidget {
  final List<String> steps;
  final Color accentColor;

  const _HowToSection({
    required this.steps,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('How to'),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FormCheckSection extends StatelessWidget {
  final List<String> cues;
  final Color accentColor;

  const _FormCheckSection({
    required this.cues,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Form check'),
          const SizedBox(height: 12),
          ...cues.map(
            (cue) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                      ),
                      color: accentColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cue,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final List<ExerciseLog> logs;
  final _ExerciseHistorySummary? summary;
  final bool isTimed;
  final Color accentColor;
  final bool loading;
  final bool hasError;

  const _ProgressBlock({
    required this.logs,
    required this.summary,
    required this.isTimed,
    required this.accentColor,
    required this.loading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _SimpleMessageCard(
        title: 'Your progress',
        body: 'Loading exercise history…',
      );
    }

    if (hasError) {
      return const _SimpleMessageCard(
        title: 'Your progress',
        body: 'Workout history could not be loaded right now.',
      );
    }

    if (summary == null) {
      return const _SimpleMessageCard(
        title: 'Your progress',
        body:
            'Once you log this exercise in finished workouts, your chart and session history will show up here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Eyebrow('Your progress'),
            Text(
              '${logs.length} SESSIONS',
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                color: AppColors.textMuted,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              summary!.latestPrimaryLabel,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 0.9,
                letterSpacing: -1.8,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                isTimed ? 'HOLD TOTAL' : 'REPS TOTAL',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                summary!.primaryDeltaLabel,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: summary!.primaryDelta >= 0 ? _detailGood : _detailBad,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isTimed
              ? 'Top hold this cycle: ${summary!.topSetLabel}'
              : 'Top set this cycle: ${summary!.topSetLabel}',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 128,
          width: double.infinity,
          child: CustomPaint(
            painter: _ProgressChartPainter(
              values: summary!.timelineValues,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TinyMetricCard(
                label: 'SESSION VOLUME',
                value: summary!.latestVolumeLabel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TinyMetricCard(
                label: 'VOLUME CHANGE',
                value: summary!.volumeDeltaLabel,
                positive: summary!.volumeDelta >= 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TinyMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool? positive;

  const _TinyMetricCard({
    required this.label,
    required this.value,
    this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive == null
        ? AppColors.textPrimary
        : positive!
            ? _detailGood
            : _detailBad;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _detailSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _detailSurfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMessageCard extends StatelessWidget {
  final String title;
  final String body;

  const _SimpleMessageCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _detailSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _detailSurfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<ExerciseLog> logs;
  final String? openLogId;
  final bool isTimed;
  final Color accentColor;
  final ValueChanged<String> onToggle;

  const _HistorySection({
    required this.logs,
    required this.openLogId,
    required this.isTimed,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: _Eyebrow('History'),
          ),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'No sessions logged yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...logs.map((log) {
              final isOpen = openLogId == log.id;
              final topSet = _topSetValue(log, isTimed);
              final totalValue = isTimed ? _totalDuration(log) : log.totalReps;

              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _detailSurfaceBorder),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => onToggle(log.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 64,
                                    child: Text(
                                      _formatShortDate(log.loggedAt),
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 11,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  if (_isPersonalBest(logs, log, isTimed))
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        '● PR',
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 10,
                                          color: accentColor,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${log.sets.length}×${isTimed ? _formatSecondsCompact(topSet) : topSet}',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isTimed
                                  ? '${_formatSecondsCompact(totalValue)} total'
                                  : '$totalValue total',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOpen)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(log.sets.length, (index) {
                              final set = log.sets[index];
                              final label = set.durationSeconds > 0
                                  ? _formatSecondsCompact(set.durationSeconds)
                                  : '${set.reps}r';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: _detailSurfaceBorder),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${index + 1} ',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      TextSpan(text: label),
                                      if (set.weightKg > 0)
                                        TextSpan(
                                          text:
                                              ' @ ${set.weightKg.toStringAsFixed(1)}kg',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<int> values;
  final Color color;

  const _ProgressChartPainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padLeft = 4.0;
    const padRight = 4.0;
    const padTop = 8.0;
    const padBottom = 18.0;
    final innerWidth = size.width - padLeft - padRight;
    final innerHeight = size.height - padTop - padBottom;
    final maxValue =
        values.fold<int>(1, (best, value) => math.max(best, value));

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = padLeft + (i / math.max(values.length - 1, 1)) * innerWidth;
      final y = padTop + innerHeight - (values[i] / maxValue) * innerHeight;
      points.add(Offset(x, y));
    }

    final baselineY = padTop + innerHeight;
    final baselinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padLeft, baselineY),
      Offset(size.width - padRight, baselineY),
      baselinePaint,
    );

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, baselineY)
      ..lineTo(points.first.dx, baselineY)
      ..close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.24),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < points.length; i++) {
      final radius = i == points.length - 1 ? 4.0 : 2.5;
      canvas.drawCircle(points[i], radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;

  const _SparklinePainter({
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxValue =
        values.fold<int>(1, (best, value) => math.max(best, value));
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (values[i] / maxValue) * (size.height - 2);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    canvas.drawCircle(points.last, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _DemoGridPainter extends CustomPainter {
  final Color accentColor;

  const _DemoGridPainter({
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 1;
    const gap = 18.0;

    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DemoGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}

class _ExerciseTargetPlan {
  final int sets;
  final int primaryTarget;
  final bool isTimed;

  const _ExerciseTargetPlan({
    required this.sets,
    required this.primaryTarget,
    required this.isTimed,
  });

  String get targetLabel =>
      isTimed ? '$sets × ${primaryTarget}s' : '$sets × $primaryTarget';
}

class _ExerciseCoachData {
  final List<String> phaseLabels;
  final List<String> steps;
  final List<String> formChecks;

  const _ExerciseCoachData({
    required this.phaseLabels,
    required this.steps,
    required this.formChecks,
  });
}

class _ExerciseHistorySummary {
  final bool isTimed;
  final int latestPrimary;
  final int topSet;
  final double latestVolume;
  final int primaryDelta;
  final double volumeDelta;
  final List<int> timelineValues;

  const _ExerciseHistorySummary({
    required this.isTimed,
    required this.latestPrimary,
    required this.topSet,
    required this.latestVolume,
    required this.primaryDelta,
    required this.volumeDelta,
    required this.timelineValues,
  });

  factory _ExerciseHistorySummary.fromLogs({
    required List<ExerciseLog> logs,
    required bool isTimed,
  }) {
    final ordered = logs.toList().reversed.toList();
    final timelineValues = ordered
        .map((log) => isTimed ? _totalDuration(log) : log.totalReps)
        .toList();
    final latestPrimary =
        isTimed ? _totalDuration(logs.first) : logs.first.totalReps;
    final previousPrimary = logs.length > 1
        ? (isTimed ? _totalDuration(logs[1]) : logs[1].totalReps)
        : latestPrimary;
    final latestVolume = logs.first.totalVolumeKg;
    final previousVolume =
        logs.length > 1 ? logs[1].totalVolumeKg : latestVolume;

    return _ExerciseHistorySummary(
      isTimed: isTimed,
      latestPrimary: latestPrimary,
      topSet: _topSetAcrossLogs(logs, isTimed),
      latestVolume: latestVolume,
      primaryDelta: latestPrimary - previousPrimary,
      volumeDelta: latestVolume - previousVolume,
      timelineValues: timelineValues,
    );
  }

  String get latestPrimaryLabel =>
      isTimed ? _formatSecondsCompact(latestPrimary) : '$latestPrimary';

  String get topSetLabel =>
      isTimed ? _formatSecondsCompact(topSet) : '$topSet reps';

  String get latestVolumeLabel => '${latestVolume.toStringAsFixed(0)} kg';

  String get primaryDeltaLabel {
    final prefix = primaryDelta >= 0 ? '↑ ' : '↓ ';
    final value = isTimed
        ? _formatSecondsCompact(primaryDelta.abs())
        : '${primaryDelta.abs()} vs last';
    return isTimed ? '$prefix$value vs last' : '$prefix$value';
  }

  String get volumeDeltaLabel {
    final prefix = volumeDelta >= 0 ? '+ ' : '− ';
    return '$prefix${volumeDelta.abs().toStringAsFixed(0)} kg';
  }
}

_ExerciseTargetPlan _targetPlanFor(Exercise exercise) {
  final isTimed = _isTimedExercise(exercise);
  final sets = switch (exercise.programSection) {
    ExerciseProgramSection.warmup => 2,
    ExerciseProgramSection.skillWork => 3,
    ExerciseProgramSection.mainExercises => exercise.difficulty >= 4 ? 4 : 3,
    ExerciseProgramSection.coolDown => 2,
  };

  final target = isTimed
      ? (exercise.difficulty <= 1
          ? 30
          : exercise.difficulty <= 3
              ? 20
              : 12)
      : (exercise.difficulty <= 1
          ? 12
          : exercise.difficulty <= 3
              ? 8
              : 5);

  return _ExerciseTargetPlan(
    sets: sets,
    primaryTarget: target,
    isTimed: isTimed,
  );
}

_ExerciseCoachData _coachDataFor(Exercise exercise) {
  switch (exercise.category) {
    case ExerciseCategory.verticalPull:
      return const _ExerciseCoachData(
        phaseLabels: ['Set shoulders', 'Drive elbows', 'Own the lowering'],
        steps: [
          'Take your grip, create tension first, and pack the shoulder before the pull starts.',
          'Pull by driving the elbows down toward your ribs instead of reaching the chin forward.',
          'Keep ribs tucked and legs quiet so the rep stays clean without swing.',
          'Pause the top briefly, then lower under control for a full eccentric.',
        ],
        formChecks: [
          'Bottom position stays active instead of hanging passively.',
          'Neck stays neutral and the ribs do not flare mid-rep.',
          'Every descent is controlled instead of dropping out of the bar.',
        ],
      );
    case ExerciseCategory.verticalPush:
      return const _ExerciseCoachData(
        phaseLabels: [
          'Stack the line',
          'Press through shoulders',
          'Lock out tall'
        ],
        steps: [
          'Set the hands, brace the trunk, and build a straight line before pressing.',
          'Keep wrists, elbows, and shoulders stacked as you move upward.',
          'Move slowly enough that you can control the bottom and the lockout.',
          'Finish tall with active shoulders instead of arching to find range.',
        ],
        formChecks: [
          'Ribs stay down while the shoulders keep reaching.',
          'The line stays clean instead of bending through the lower back.',
          'You can pause the hardest position without collapsing.',
        ],
      );
    case ExerciseCategory.horizontalPull:
      return const _ExerciseCoachData(
        phaseLabels: [
          'Open the chest',
          'Pull to the body',
          'Squeeze and return'
        ],
        steps: [
          'Set your torso angle and keep the chest open before the first rep.',
          'Start the pull with the upper back, then bring the elbows toward the body.',
          'Pause the squeezed position instead of bouncing through it.',
          'Return with control and keep the same body angle from rep to rep.',
        ],
        formChecks: [
          'Shoulders stay away from the ears at the finish.',
          'Torso angle stays steady with no jerking or twisting.',
          'Each rep finishes with the back doing the work, not just the hands moving.',
        ],
      );
    case ExerciseCategory.horizontalPush:
      return const _ExerciseCoachData(
        phaseLabels: ['Brace the plank', 'Lower with control', 'Drive evenly'],
        steps: [
          'Set a clean plank before bending the elbows.',
          'Lower under control so the chest, shoulders, and triceps stay loaded.',
          'Press the floor away evenly with both hands on the way up.',
          'Finish each rep without losing the rib-to-hip connection.',
        ],
        formChecks: [
          'Head, ribs, hips, and heels stay in one line.',
          'Elbows track consistently instead of flaring wider every rep.',
          'The bottom position is controlled instead of bounced.',
        ],
      );
    case ExerciseCategory.squat:
      return const _ExerciseCoachData(
        phaseLabels: [
          'Set the feet',
          'Sit between the hips',
          'Stand through mid-foot'
        ],
        steps: [
          'Build pressure through the whole foot before you descend.',
          'Let knees and hips bend together so you stay centered.',
          'Reach depth with control instead of dropping into the bottom.',
          'Stand by driving through the full foot and finishing tall.',
        ],
        formChecks: [
          'Heels stay planted through the whole rep.',
          'Knees track with the toes instead of collapsing inward.',
          'The torso stays organized instead of folding suddenly at the bottom.',
        ],
      );
    case ExerciseCategory.hinge:
      return const _ExerciseCoachData(
        phaseLabels: ['Brace and hinge', 'Load the hips', 'Finish stacked'],
        steps: [
          'Push the hips back first and keep the spine long as you hinge.',
          'Feel the hamstrings load before changing direction.',
          'Drive the floor away and extend the hips to stand up.',
          'Finish tall without leaning back at lockout.',
        ],
        formChecks: [
          'Back position stays steady throughout the full rep.',
          'The movement comes from the hips, not just the knees moving.',
          'You can feel tension in the posterior chain before standing up.',
        ],
      );
    case ExerciseCategory.core:
      return const _ExerciseCoachData(
        phaseLabels: [
          'Set the brace',
          'Hold the line',
          'Breathe under tension'
        ],
        steps: [
          'Exhale just enough to lock the ribs down before the set starts.',
          'Keep the trunk rigid while breathing quietly into the brace.',
          'Stay organized through the shoulders and hips instead of sagging.',
          'Stop the set when position changes, not only when the timer ends.',
        ],
        formChecks: [
          'Lower back position stays consistent throughout the set.',
          'Shoulders and hips stay level instead of rotating.',
          'Breathing happens without losing trunk tension.',
        ],
      );
    case ExerciseCategory.skill:
      return const _ExerciseCoachData(
        phaseLabels: ['Own the setup', 'Move precisely', 'Finish controlled'],
        steps: [
          'Treat the first rep like practice and build the same setup every time.',
          'Move deliberately enough that you can feel the balance and line.',
          'Pause key positions so you actually own them instead of passing through them.',
          'End the set while the movement still looks sharp.',
        ],
        formChecks: [
          'Your start position is repeatable from set to set.',
          'Line, rhythm, and balance stay predictable through the rep.',
          'You can pause important positions without losing control.',
        ],
      );
  }
}

bool _isTimedExercise(Exercise exercise) {
  final name = exercise.name.toLowerCase();
  final description = exercise.description.toLowerCase();
  return name.contains('hold') ||
      name.contains('hang') ||
      name.contains('plank') ||
      name.contains('lever') ||
      name.contains('handstand') ||
      description.contains('for time');
}

String _branchLabel(String branchId) {
  if (branchId.isEmpty || branchId == 'main') return 'Main line';
  return branchId
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _levelLabel(int difficulty) {
  if (difficulty <= 2) return 'Beginner';
  if (difficulty <= 5) return 'Intermediate';
  if (difficulty <= 7) return 'Advanced';
  return 'Expert';
}

int _totalDuration(ExerciseLog log) {
  return log.sets.fold(0, (sum, set) => sum + set.durationSeconds);
}

int _topSetValue(ExerciseLog log, bool isTimed) {
  return log.sets.fold<int>(
    0,
    (best, set) => math.max(
      best,
      isTimed ? set.durationSeconds : set.reps,
    ),
  );
}

int _topSetAcrossLogs(List<ExerciseLog> logs, bool isTimed) {
  return logs.fold<int>(
    0,
    (best, log) => math.max(best, _topSetValue(log, isTimed)),
  );
}

bool _isPersonalBest(List<ExerciseLog> logs, ExerciseLog target, bool isTimed) {
  final targetValue = isTimed ? _totalDuration(target) : target.totalReps;
  final maxValue = logs.fold<int>(
    0,
    (best, log) =>
        math.max(best, isTimed ? _totalDuration(log) : log.totalReps),
  );
  return targetValue == maxValue && maxValue > 0;
}

String _formatSecondsCompact(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (minutes == 0) return '${remainder}s';
  return '${minutes}m ${remainder}s';
}

String _formatShortDate(DateTime date) {
  return '${_monthShort(date.month)} ${date.day.toString().padLeft(2, '0')}';
}

String _monthShort(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
