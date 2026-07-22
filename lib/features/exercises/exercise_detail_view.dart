import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/exercise_progression_service.dart';
import '../../data/services/workout_rest_preferences_service.dart';

/// Which tab the exercise detail view opens on. Live workout and the skill
/// tree open on "How to", the Data tab opens on "Summary".
enum ExerciseDetailTab { howTo, summary, history }

Future<T?> openExerciseDetailView<T>(
  BuildContext context, {
  required Exercise exercise,
  Color accentColor = AppColors.accentPrimary,
  String? skillCategoryId,
  ExerciseDetailTab initialTab = ExerciseDetailTab.howTo,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => ExerciseDetailView(
        exercise: exercise,
        accentColor: accentColor,
        skillCategoryId: skillCategoryId,
        initialTab: initialTab,
      ),
    ),
  );
}

/// Exercise detail page in the polished design language, split into
/// "How to" (demo, steps, form checks), "Summary" (progress chart and
/// personal records), and "History" (logged sessions) tabs.
class ExerciseDetailView extends StatefulWidget {
  final Exercise exercise;
  final Color accentColor;
  final String? skillCategoryId;
  final ExerciseDetailTab initialTab;

  const ExerciseDetailView({
    super.key,
    required this.exercise,
    this.accentColor = AppColors.accentPrimary,
    this.skillCategoryId,
    this.initialTab = ExerciseDetailTab.howTo,
  });

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  static const _tabs = [
    ExerciseDetailTab.howTo,
    ExerciseDetailTab.summary,
    ExerciseDetailTab.history,
  ];

  final _exerciseLogService = ExerciseLogService();
  final _restPreferencesService = WorkoutRestPreferencesService();

  late Future<List<ExerciseLog>> _logsFuture;
  late ExerciseDetailTab _tab;
  int _restSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _logsFuture = _loadLogs();
    _loadRestPreference();
  }

  Future<List<ExerciseLog>> _loadLogs() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return const [];
    return _exerciseLogService.fetchForExercise(userId, widget.exercise.id);
  }

  Future<void> _loadRestPreference() async {
    final stored = await _restPreferencesService.loadRestIntervals();
    if (!mounted) return;
    setState(() => _restSeconds = stored[widget.exercise.id] ?? 0);
  }

  String get _resolvedSkillCategoryId {
    final requestedId = widget.skillCategoryId;
    if (requestedId != null && requestedId.isNotEmpty) {
      return requestedId;
    }
    return ExerciseCatalog.skillCategoryIdForExercise(widget.exercise);
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final skillCategory =
        SkillCategoryCatalog.findById(_resolvedSkillCategoryId);
    final isTimed = _isTimedExercise(exercise);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DetailNavBar(
              title: exercise.name,
              subtitle: '${skillCategory?.title ?? exercise.category.label} · '
                  '${_branchLabel(exercise.branchId)}',
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedTabs(
                labels: const ['How to', 'Summary', 'History'],
                selectedIndex: _tabs.indexOf(_tab),
                onChanged: (index) => setState(() => _tab = _tabs[index]),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                ExerciseDetailTab.howTo => _HowToTab(
                    exercise: exercise,
                    restSeconds: _restSeconds,
                  ),
                ExerciseDetailTab.summary => _SummaryTab(
                    logsFuture: _logsFuture,
                    isTimed: isTimed,
                  ),
                ExerciseDetailTab.history => _HistoryTab(
                    logsFuture: _logsFuture,
                    isTimed: isTimed,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── How to tab ────────────────────────────────────────────────────────

class _HowToTab extends StatelessWidget {
  final Exercise exercise;
  final int restSeconds;

  const _HowToTab({
    required this.exercise,
    required this.restSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final coachData = _coachDataFor(exercise);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 44),
      children: [
        _DemoMedia(exercise: exercise),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'Demo · ${exercise.name} shown at working tempo',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'How to'),
        SurfaceCard(
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < coachData.steps.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i > 0
                        ? const Border(
                            top: BorderSide(
                              color: AppColors.divider,
                            ),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentPrimary,
                            height: 1.45,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          coachData.steps[i],
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Form check',
          sub: 'Every rep should pass these',
        ),
        SurfaceCard(
          clip: true,
          child: Column(
            children: [
              for (var i = 0; i < coachData.formChecks.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i > 0
                        ? const Border(
                            top: BorderSide(
                              color: AppColors.divider,
                            ),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 21,
                        height: 21,
                        margin: const EdgeInsets.only(top: 0.5),
                        decoration: const BoxDecoration(
                          color: AppColors.greenSoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          coachData.formChecks[i],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Summary tab ───────────────────────────────────────────────────────

enum _SummaryMetric { sessionTotal, bestSet }

class _SummaryTab extends StatefulWidget {
  final Future<List<ExerciseLog>> logsFuture;
  final bool isTimed;

  const _SummaryTab({
    required this.logsFuture,
    required this.isTimed,
  });

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  _SummaryMetric _metric = _SummaryMetric.sessionTotal;

  int _sessionTotal(ExerciseLog log) {
    if (widget.isTimed) {
      return log.sets.fold(0, (sum, set) => sum + set.durationSeconds);
    }
    return log.sets.fold(0, (sum, set) => sum + set.reps);
  }

  int _bestSet(ExerciseLog log) {
    var best = 0;
    for (final set in log.sets) {
      final value = widget.isTimed ? set.durationSeconds : set.reps;
      if (value > best) best = value;
    }
    return best;
  }

  String _formatValue(int value) =>
      widget.isTimed ? _formatSeconds(value) : '$value';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExerciseLog>>(
      future: widget.logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: LoadingIndicator());
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 44),
            children: const [
              _MessageCard(
                message: 'Couldn’t load your history. Pull back and try '
                    'again in a moment.',
              ),
            ],
          );
        }
        return _buildSummary(snapshot.data ?? const <ExerciseLog>[]);
      },
    );
  }

  Widget _buildSummary(List<ExerciseLog> logs) {
    // Logs arrive newest-first — the chart wants oldest-first.
    final ordered = logs.reversed.toList();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    var window = ordered.where((log) => log.loggedAt.isAfter(cutoff)).toList();
    var windowLabel = 'Last 3 months';
    if (window.length < 2 && ordered.isNotEmpty) {
      window =
          ordered.length > 12 ? ordered.sublist(ordered.length - 12) : ordered;
      windowLabel = 'All sessions';
    }

    final metricLabel = _metric == _SummaryMetric.sessionTotal
        ? 'Session total'
        : 'Most reps (set)';
    final metricDef = _metric == _SummaryMetric.sessionTotal
        ? (widget.isTimed
            ? 'Total hold time per training session'
            : 'Total reps per training session')
        : (widget.isTimed
            ? 'Longest single hold per session'
            : 'Highest rep count in a single set');
    final series = window
        .map(
          (log) => _metric == _SummaryMetric.sessionTotal
              ? _sessionTotal(log)
              : _bestSet(log),
        )
        .toList();

    final bestSetAllTime = logs.fold<int>(
        0, (best, log) => _bestSet(log) > best ? _bestSet(log) : best);
    final bestSessionAllTime = logs.fold<int>(0,
        (best, log) => _sessionTotal(log) > best ? _sessionTotal(log) : best);
    final records = logs.isEmpty
        ? const <(String, String)>[]
        : <(String, String)>[
            (
              widget.isTimed ? 'Longest hold' : 'Most reps in a set',
              _formatValue(bestSetAllTime),
            ),
            (
              widget.isTimed ? 'Best session time' : 'Best session total',
              _formatValue(bestSessionAllTime),
            ),
            ('Sessions logged', '${logs.length}'),
            ('Last session', _formatShortDate(logs.first.loggedAt)),
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 44),
      children: [
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${metricLabel.toUpperCase()} · '
                '${windowLabel.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metricDef,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (series.length < 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    logs.isEmpty
                        ? 'No sessions logged yet — your trend appears '
                            'after your first workout.'
                        : 'Log one more session to see your trend here.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                )
              else
                _TrendChart(
                  values: series,
                  dates: window.map((log) => log.loggedAt).toList(),
                  formatValue: _formatValue,
                ),
              const SizedBox(height: 14),
              SegmentedTabs(
                labels: const ['Session total', 'Most reps (set)'],
                selectedIndex: _metric == _SummaryMetric.sessionTotal ? 0 : 1,
                onChanged: (index) => setState(() {
                  _metric = index == 0
                      ? _SummaryMetric.sessionTotal
                      : _SummaryMetric.bestSet;
                }),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Personal records'),
        if (records.isEmpty)
          const SurfaceCard(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Text(
              'Personal records appear after your first logged session.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          )
        else
          SurfaceCard(
            clip: true,
            child: Column(
              children: [
                for (var i = 0; i < records.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i > 0
                          ? const Border(
                              top: BorderSide(color: AppColors.divider),
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            records[i].$1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          records[i].$2,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(
            widget.isTimed
                ? 'Holds are tracked as time, not volume.'
                : 'Only completed working sets count toward these numbers.',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Line chart in the polished language: soft gridlines with min/mid/max
/// labels, accent polyline with dots, and a value chip on the last point.
class _TrendChart extends StatelessWidget {
  final List<int> values;
  final List<DateTime> dates;
  final String Function(int) formatValue;

  const _TrendChart({
    required this.values,
    required this.dates,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendChartPainter(
          values: values,
          dates: dates,
          formatValue: formatValue,
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<int> values;
  final List<DateTime> dates;
  final String Function(int) formatValue;

  _TrendChartPainter({
    required this.values,
    required this.dates,
    required this.formatValue,
  });

  static const _months = [
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

  TextPainter _text(
    String value, {
    required Color color,
    double fontSize = 9.5,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 16.0;
    const padBottom = 22.0;
    const padRight = 14.0;

    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final span = (max - min) == 0 ? 1 : max - min;
    final gridValues = [max, ((max + min) / 2).round(), min];

    final labelPainters = [
      for (final value in gridValues)
        _text(formatValue(value), color: AppColors.textMuted),
    ];
    final padLeft = labelPainters.fold<double>(
          0,
          (widest, painter) => painter.width > widest ? painter.width : widest,
        ) +
        10;

    final chartWidth = size.width - padLeft - padRight;
    final chartHeight = size.height - padTop - padBottom;
    double xAt(int i) =>
        padLeft +
        (values.length == 1 ? 0 : i * chartWidth / (values.length - 1));
    double yAt(num value) => padTop + (1 - (value - min) / span) * chartHeight;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i < gridValues.length; i++) {
      final y = yAt(gridValues[i]);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        gridPaint,
      );
      labelPainters[i].paint(
        canvas,
        Offset(padLeft - 6 - labelPainters[i].width,
            y - labelPainters[i].height / 2),
      );
    }

    final linePaint = Paint()
      ..color = AppColors.accentPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(xAt(i), yAt(values[i]));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotFill = Paint()..color = AppColors.surface;
    final dotStroke = Paint()
      ..color = AppColors.accentPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < values.length; i++) {
      final point = Offset(xAt(i), yAt(values[i]));
      if (i == values.length - 1) {
        canvas.drawCircle(
          point,
          4.5,
          Paint()..color = AppColors.accentPrimary,
        );
      } else {
        canvas.drawCircle(point, 3, dotFill);
        canvas.drawCircle(point, 3, dotStroke);
      }
    }

    // Value chip above the last point.
    final chipText = _text(
      formatValue(values.last),
      color: AppColors.bg,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );
    final chipWidth = chipText.width + 14;
    final lastPoint = Offset(xAt(values.length - 1), yAt(values.last));
    var chipLeft = lastPoint.dx - chipWidth / 2;
    if (chipLeft + chipWidth > size.width) chipLeft = size.width - chipWidth;
    final chipTop =
        (lastPoint.dy - 27).clamp(0.0, size.height - padBottom - 17);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(chipLeft, chipTop, chipWidth, 17),
        const Radius.circular(6),
      ),
      Paint()..color = AppColors.accentPrimary,
    );
    chipText.paint(
      canvas,
      Offset(chipLeft + (chipWidth - chipText.width) / 2,
          chipTop + (17 - chipText.height) / 2),
    );

    // First / last date labels along the bottom.
    String dateLabel(DateTime date) => '${_months[date.month - 1]} ${date.day}';
    final firstLabel = _text(
      dateLabel(dates.first),
      color: AppColors.textMuted,
    );
    firstLabel.paint(canvas, Offset(padLeft, size.height - firstLabel.height));
    final lastLabel = _text(
      dateLabel(dates.last),
      color: AppColors.textMuted,
    );
    lastLabel.paint(
      canvas,
      Offset(size.width - padRight - lastLabel.width,
          size.height - lastLabel.height),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.dates != dates;
}

// ── History tab ───────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final Future<List<ExerciseLog>> logsFuture;
  final bool isTimed;

  const _HistoryTab({
    required this.logsFuture,
    required this.isTimed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExerciseLog>>(
      future: logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: LoadingIndicator());
        }
        Widget child;
        if (snapshot.hasError) {
          child = const _MessageCard(
            message: 'Couldn’t load your history. Pull back and try '
                'again in a moment.',
          );
        } else {
          final logs = snapshot.data ?? const <ExerciseLog>[];
          child = logs.isEmpty
              ? const _MessageCard(
                  message: 'Log this exercise in a finished workout and '
                      'your sessions will show up here.',
                )
              : _HistoryCard(logs: logs, isTimed: isTimed);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 44),
          children: [child],
        );
      },
    );
  }
}

class _DetailNavBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _DetailNavBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
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

class _DemoMedia extends StatelessWidget {
  final Exercise exercise;

  const _DemoMedia({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final imageUrl = exercise.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(kCardRadius),
      child: SizedBox(
        height: 208,
        width: double.infinity,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _DemoPlaceholder(),
              )
            : const _DemoPlaceholder(),
      ),
    );
  }
}

class _DemoPlaceholder extends StatelessWidget {
  const _DemoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo coming soon',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<ExerciseLog> logs;
  final bool isTimed;

  const _HistoryCard({required this.logs, required this.isTimed});

  String _setsLabel(ExerciseLog log) {
    final values = log.sets
        .map(
          (set) => isTimed ? '${set.durationSeconds}s' : '${set.reps}',
        )
        .join(' · ');
    return isTimed ? values : '$values reps';
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          for (var i = 0; i < logs.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i > 0
                    ? const Border(top: BorderSide(color: AppColors.divider))
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatShortDate(logs[i].loggedAt),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _setsLabel(logs[i]),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
            child: Text(
              isTimed
                  ? 'Hold per set · most recent first'
                  : 'Reps per set · most recent first',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coach content & helpers ───────────────────────────────────────────

class _ExerciseCoachData {
  final List<String> steps;
  final List<String> formChecks;

  const _ExerciseCoachData({
    required this.steps,
    required this.formChecks,
  });
}

_ExerciseCoachData _coachDataFor(Exercise exercise) {
  switch (exercise.category) {
    case ExerciseCategory.verticalPull:
      return const _ExerciseCoachData(
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

bool _isTimedExercise(Exercise exercise) =>
    ExerciseProgressionService.isTimedExercise(exercise);

String _branchLabel(String branchId) {
  if (branchId.isEmpty || branchId == 'main') return 'Main line';
  return branchId
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatSeconds(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  if (remainder == 0) return '${minutes}m';
  return '${minutes}m ${remainder}s';
}

String _formatShortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}';
}
