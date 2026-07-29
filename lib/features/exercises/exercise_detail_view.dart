import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/exercise_coaching_catalog.dart';
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailNavBar(onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: TypeTitle(
                exercise.name,
                size: 30,
                sub: '${skillCategory?.title ?? exercise.category.label} · '
                    '${_branchLabel(exercise.branchId)}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
              child: TypeWordTabs(
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
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 44),
      children: [
        _DemoMedia(exercise: exercise),
        const TypeSectionLabel('How to'),
        // Numbered lines: the count is the only colour, and the step itself
        // is read at body size rather than boxed.
        for (var i = 0; i < coachData.steps.length; i++)
          Container(
            padding: const EdgeInsets.only(top: 15, bottom: 16),
            decoration: BoxDecoration(
              border: i == coachData.steps.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${i + 1}',
                    style: monoStyle(
                      size: 13,
                      color: AppColors.accentPrimary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    coachData.steps[i],
                    style: const TextStyle(
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const TypeSectionLabel('Form check'),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Every rep should pass these.',
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        for (var i = 0; i < coachData.formChecks.length; i++)
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 17),
            decoration: BoxDecoration(
              border: i == coachData.formChecks.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Text(
              coachData.formChecks[i],
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.34,
                height: 1.35,
              ),
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
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 44),
      children: [
        // The chart keeps a surface — a plot needs a field to sit on, the
        // way the month grid does.
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${metricLabel.toUpperCase()} · '
                '${windowLabel.toUpperCase()}',
                style: monoStyle(size: 11, letterSpacing: 1.4),
              ),
              const SizedBox(height: 5),
              Text(
                metricDef,
                style: const TextStyle(
                  fontSize: 12,
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
        const TypeSectionLabel('Personal records'),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Personal records appear after your first logged session.',
              style: TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          )
        else
          for (var i = 0; i < records.length; i++)
            TypeSettingRow(
              name: records[i].$1,
              value: records[i].$2,
              valueColor: AppColors.textPrimary,
              chevron: false,
              last: i == records.length - 1,
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Text(
            widget.isTimed
                ? 'Holds are tracked as time, not volume.'
                : 'Only completed working sets count toward these numbers.',
            style: const TextStyle(
              fontSize: 12.5,
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
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 44),
          children: [child],
        );
      },
    );
  }
}

/// Bare back chevron — the exercise names itself in the title below.
class _DetailNavBar extends StatelessWidget {
  final VoidCallback onBack;

  const _DetailNavBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 10, 22, 0),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The demo at the top of "How to": the exercise's YouTube clip, playing in
/// place.
///
/// The player shows the clip's own poster frame and play button until it is
/// started, so nothing autoplays and nothing costs data until asked. Where
/// there is no player to build — no clip, or a platform with no web view,
/// which is every widget test — the still stands in.
class _DemoMedia extends StatefulWidget {
  final Exercise exercise;

  const _DemoMedia({required this.exercise});

  @override
  State<_DemoMedia> createState() => _DemoMediaState();
}

class _DemoMediaState extends State<_DemoMedia> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = ExerciseCoachingCatalog.findById(widget.exercise.id)?.videoId;
    if (videoId == null || !_playerIsAvailable) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        // Keep the follow-on suggestions to the same channel: a form demo
        // should not end on whatever YouTube feels like next.
        strictRelatedVideos: true,
      ),
    );
  }

  /// The player is a web view, and there is no web view in a widget test.
  bool get _playerIsAvailable => WebViewPlatform.instance != null;

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: YoutubePlayer(controller: controller, aspectRatio: 16 / 9),
      );
    }

    final imageUrl = ExerciseCoachingCatalog.findById(widget.exercise.id)
            ?.imageUrl ??
        widget.exercise.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
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

/// What the footage will sit in until there is footage: an outline and a
/// mono note, rather than a filled panel pretending to be media.
class _DemoPlaceholder extends StatelessWidget {
  const _DemoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              size: 30,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              'DEMO COMING SOON',
              style: monoStyle(
                size: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.55,
              ),
            ),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < logs.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: i == logs.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatShortDate(logs[i].loggedAt),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _setsLabel(logs[i]),
                  style: monoStyle(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            isTimed
                ? 'Hold per set · most recent first'
                : 'Reps per set · most recent first',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
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

/// Coaching for this exact movement where the exercise sheet has it, and the
/// movement pattern's generic advice where it does not.
_ExerciseCoachData _coachDataFor(Exercise exercise) {
  final coaching = ExerciseCoachingCatalog.findById(exercise.id);
  if (coaching != null) {
    return _ExerciseCoachData(
      steps: coaching.howTo,
      formChecks: coaching.formChecks,
    );
  }
  return _patternCoachDataFor(exercise);
}

_ExerciseCoachData _patternCoachDataFor(Exercise exercise) {
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
    case ExerciseCategory.other:
      return const _ExerciseCoachData(
        steps: [
          'Set the load and the position before the first rep, not during it.',
          'Move through the range you can control, and own both ends of it.',
          'Keep the tempo the same from the first rep to the last.',
          'End the set while the technique still looks like the first rep.',
        ],
        formChecks: [
          'The setup is the same every set.',
          'Nothing swings or shortens to finish a rep.',
          'The last rep looks like the first.',
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
