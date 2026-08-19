import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/catalog/exercise_coaching_catalog.dart';
import '../../data/models/exercise_log_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/exercise_log_service.dart';
import '../../data/services/weight_unit_service.dart';
import '../../data/services/workout_rest_preferences_service.dart';
import 'exercise_summary_metrics.dart';

/// Which tab the exercise detail view opens on. Live workout and the skill
/// tree open on "How to", while logged exercise links open on "Trends".
enum ExerciseDetailTab { howTo, trends }

/// Height of the back bar. The page is inset by it and then scrolls under it.
const _detailNavBarHeight = 44.0;

Future<T?> openExerciseDetailView<T>(
  BuildContext context, {
  required Exercise exercise,
  Color accentColor = AppColors.accentPrimary,
  String? skillCategoryId,
  ExerciseDetailTab initialTab = ExerciseDetailTab.howTo,
  ValueListenable<List<ExerciseSet>>? liveSetsListenable,
  DateTime? liveSessionStartedAt,
}) {
  // Full screen, above the tab shell: the page is a thing of its own, and
  // the tab bar under it would only mislead about where you are.
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(
      builder: (_) => ExerciseDetailView(
        exercise: exercise,
        accentColor: accentColor,
        skillCategoryId: skillCategoryId,
        initialTab: initialTab,
        liveSetsListenable: liveSetsListenable,
        liveSessionStartedAt: liveSessionStartedAt,
      ),
    ),
  );
}

/// Exercise detail page in the polished design language, split into
/// "How to" (demo, steps, form checks) and "Trends" (progress charts and
/// logged sessions) tabs.
class ExerciseDetailView extends StatefulWidget {
  final Exercise exercise;
  final Color accentColor;

  /// Which tree the caller came from. The page no longer prints it — the
  /// heading names the movement and what it works — but callers still pass
  /// it, and it is what a per-tree view here would need.
  final String? skillCategoryId;
  final ExerciseDetailTab initialTab;
  final ValueListenable<List<ExerciseSet>>? liveSetsListenable;
  final DateTime? liveSessionStartedAt;

  const ExerciseDetailView({
    super.key,
    required this.exercise,
    this.accentColor = AppColors.accentPrimary,
    this.skillCategoryId,
    this.initialTab = ExerciseDetailTab.howTo,
    this.liveSetsListenable,
    this.liveSessionStartedAt,
  });

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  static const _tabs = [
    ExerciseDetailTab.howTo,
    ExerciseDetailTab.trends,
  ];

  final _exerciseLogService = ExerciseLogService();
  final _restPreferencesService = WorkoutRestPreferencesService();

  late Future<List<ExerciseLog>> _logsFuture;
  late ExerciseDetailTab _tab;

  /// The page's outer scroll: once the heading has gone under the bar, the
  /// bar carries the name instead.
  final _scrollController = ScrollController();
  bool _headingScrolledOff = false;
  int _restSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _scrollController.addListener(_onScroll);
    _logsFuture = _loadLogs();
    _loadRestPreference();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// The heading is the first thing under the bar; once the page has moved
  /// past it, the bar takes the name over.
  void _onScroll() {
    final scrolledOff = _scrollController.hasClients &&
        _scrollController.offset > _headingHeight;
    if (scrolledOff != _headingScrolledOff) {
      setState(() => _headingScrolledOff = scrolledOff);
    }
  }

  /// About where the exercise's name ends: the title, at its size and line
  /// height, plus the padding above it.
  static const double _headingHeight = 14 + 36;

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

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        // The bar is drawn over the page rather than above it, so the page
        // scrolls under it — which is why it is opaque.
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The name, what it works and the demo scroll away together; the
            // tabs stop at the top and stay there, with their own content
            // running on underneath. Reading the steps should not cost you
            // the ability to switch tabs.
            Padding(
              padding: const EdgeInsets.only(top: _detailNavBarHeight),
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TypeTitle(exercise.name, size: 30),
                          const SizedBox(height: 10),
                          _ExerciseBrief(exercise: exercise),
                          const SizedBox(height: 22),
                          _DemoMedia(exercise: exercise),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedTabs(
                      selectedIndex: _tabs.indexOf(_tab),
                      onChanged: (index) => setState(() => _tab = _tabs[index]),
                    ),
                  ),
                ],
                body: switch (_tab) {
                  ExerciseDetailTab.howTo => _HowToTab(
                      exercise: exercise,
                      restSeconds: _restSeconds,
                    ),
                  ExerciseDetailTab.trends => ExerciseTrendsTab(
                      logsFuture: _logsFuture,
                      exercise: exercise,
                      liveSetsListenable: widget.liveSetsListenable,
                      liveSessionStartedAt: widget.liveSessionStartedAt,
                    ),
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _DetailNavBar(
                onBack: () => Navigator.of(context).pop(),
                title: exercise.name,
                showTitle: _headingScrolledOff,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tabs, held at the top once the demo above them has scrolled away, so
/// that reading the steps never costs you the ability to switch tabs.
class _PinnedTabs extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _PinnedTabs({required this.selectedIndex, required this.onChanged});

  static const _height = 60.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ColoredBox(
      color: AppColors.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
        child: TypeWordTabs(
          labels: const ['How to', 'Trends'],
          selectedIndex: selectedIndex,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedTabs oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}

/// What the movement works, under its name: the muscles it is chosen for,
/// and the ones it takes along.
class _ExerciseBrief extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseBrief({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exercise.primaryMuscles.isNotEmpty)
          _MuscleLine(label: 'Primary', muscles: exercise.primaryMuscles),
        if (exercise.secondaryMuscles.isNotEmpty)
          _MuscleLine(label: 'Secondary', muscles: exercise.secondaryMuscles),
      ],
    );
  }
}

class _MuscleLine extends StatelessWidget {
  final String label;
  final List<String> muscles;

  const _MuscleLine({required this.label, required this.muscles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            TextSpan(text: muscles.join(', ')),
          ],
        ),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.45,
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
    // The page runs under the tab bar, so the list keeps that much clear
    // under its last line — or the end can never be scrolled into view.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(22, 4, 22, 44 + bottomInset),
      children: [
        // The demo is not here: it sits above the tabs, where it is what the
        // page opens on whichever tab you are reading.
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
        for (var i = 0; i < coachData.formChecks.length; i++)
          Container(
            padding: const EdgeInsets.only(top: 15, bottom: 16),
            decoration: BoxDecoration(
              border: i == coachData.formChecks.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Text(
              coachData.formChecks[i],
              style: const TextStyle(
                fontSize: 15.5,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Trends tab ────────────────────────────────────────────────────────

class _SummarySession {
  final DateTime loggedAt;
  final List<ExerciseSet> sets;
  final bool isLive;

  const _SummarySession({
    required this.loggedAt,
    required this.sets,
    this.isLive = false,
  });
}

class ExerciseTrendsTab extends StatefulWidget {
  final Future<List<ExerciseLog>> logsFuture;
  final Exercise exercise;
  final ValueListenable<List<ExerciseSet>>? liveSetsListenable;
  final DateTime? liveSessionStartedAt;

  const ExerciseTrendsTab({
    super.key,
    required this.logsFuture,
    required this.exercise,
    this.liveSetsListenable,
    this.liveSessionStartedAt,
  });

  @override
  State<ExerciseTrendsTab> createState() => _ExerciseTrendsTabState();
}

class _ExerciseTrendsTabState extends State<ExerciseTrendsTab> {
  late ExerciseSummaryMetric _metric;

  @override
  void initState() {
    super.initState();
    _metric = summaryMetricsFor(widget.exercise).first;
  }

  @override
  void didUpdateWidget(covariant ExerciseTrendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final metrics = summaryMetricsFor(widget.exercise);
    if (!metrics.contains(_metric)) {
      _metric = metrics.first;
    }
  }

  String _formatValue(double value) => _formatValueFor(_metric, value);

  /// "Aug 25" — the day a session was logged, as the x axis names it.
  static String _dateLabel(DateTime date) {
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

  String _formatValueFor(ExerciseSummaryMetric metric, double value) {
    switch (metric) {
      case ExerciseSummaryMetric.bestTime:
      case ExerciseSummaryMetric.totalTime:
        return _formatSeconds(value.round());
      case ExerciseSummaryMetric.heaviestWeight:
      case ExerciseSummaryMetric.totalVolume:
        return WeightUnitService.label(value);
      case ExerciseSummaryMetric.totalReps:
      case ExerciseSummaryMetric.bestSet:
        return '${value.round()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveSetsListenable = widget.liveSetsListenable;
    if (liveSetsListenable == null) {
      return _buildLogs(const <ExerciseSet>[]);
    }
    return ValueListenableBuilder<List<ExerciseSet>>(
      valueListenable: liveSetsListenable,
      builder: (context, liveSets, _) => _buildLogs(liveSets),
    );
  }

  Widget _buildLogs(List<ExerciseSet> liveSets) {
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
        return _buildSummary(
          snapshot.data ?? const <ExerciseLog>[],
          liveSets,
        );
      },
    );
  }

  Widget _buildSummary(List<ExerciseLog> logs, List<ExerciseSet> liveSets) {
    // Logs arrive newest-first — the chart wants oldest-first.
    final ordered = [
      for (final log in logs.reversed)
        _SummarySession(loggedAt: log.loggedAt, sets: log.sets),
      if (liveSets.isNotEmpty)
        _SummarySession(
          loggedAt: widget.liveSessionStartedAt ?? DateTime.now(),
          sets: liveSets,
          isLive: true,
        ),
    ];
    // The last twelve months of sessions, all fitted to the width — a year
    // trained three times a week is still a line the thumb can read along.
    // Older sessions stay in the history list below.
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final window =
        ordered.where((session) => !session.loggedAt.isBefore(cutoff)).toList();
    final metrics = summaryMetricsFor(widget.exercise);
    final series = window
        .map((session) => summaryMetricValue(_metric, session.sets))
        .toList();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(22, 4, 22, 44 + bottomInset),
      children: [
        // The chart sits on the page, not on a card — the room is the
        // plot's, and the gridlines are field enough.
        TypeSectionLabel(_metric.label),
        Text(
          _metric.definition,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        if (series.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No completed sets yet — finish a set and this graph '
              'will update immediately.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          )
        else
          _TrendChart(
            values: series,
            sessionLabels: [
              for (final session in window)
                session.isLive ? 'Live' : _dateLabel(session.loggedAt),
            ],
            formatValue: _formatValue,
            repaintKey: _metric,
          ),
        const SizedBox(height: 16),
        SegmentedTabs(
          labels: metrics.map((metric) => metric.label).toList(),
          selectedIndex: metrics.indexOf(_metric),
          onChanged: (index) => setState(() => _metric = metrics[index]),
        ),
        const TypeSectionLabel('History'),
        if (logs.isEmpty)
          const _MessageCard(
            message: 'Log this exercise in a finished workout and your '
                'sessions will show up here.',
          )
        else
          _HistoryCard(logs: logs, exercise: widget.exercise),
      ],
    );
  }
}

/// Line chart in the polished language: soft gridlines with min/mid/max
/// labels and an accent polyline with dots. Every session fits the width;
/// press and drag along it to read each point — a guide drops on the
/// nearest session and its value and date sit above the line.
class _TrendChart extends StatefulWidget {
  final List<double> values;
  final List<String> sessionLabels;
  final String Function(double) formatValue;
  final Object repaintKey;

  const _TrendChart({
    required this.values,
    required this.sessionLabels,
    required this.formatValue,
    required this.repaintKey,
  });

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  /// The session under the finger, or null when nothing is being read.
  int? _scrubIndex;
  double _width = 0;

  void _scrubTo(Offset local) {
    if (_width <= 0) return;
    final index = _TrendChartPainter.indexAt(
      local.dx,
      width: _width,
      count: widget.values.length,
    );
    if (index != _scrubIndex) setState(() => _scrubIndex = index);
  }

  void _release() {
    if (_scrubIndex != null) setState(() => _scrubIndex = null);
  }

  @override
  void didUpdateWidget(covariant _TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values.length != widget.values.length) _scrubIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Exercise sessions chart',
      value: [
        for (var i = 0; i < widget.values.length; i++)
          '${widget.sessionLabels[i]} ${widget.formatValue(widget.values[i])}',
      ].join(', '),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // A press-and-hold reads the chart; a plain vertical drag still
              // scrolls the page, since only the long press claims the
              // gesture.
              onLongPressStart: (d) => _scrubTo(d.localPosition),
              onLongPressMoveUpdate: (d) => _scrubTo(d.localPosition),
              onLongPressEnd: (_) => _release(),
              onLongPressCancel: _release,
              onTapDown: (d) => _scrubTo(d.localPosition),
              onTapUp: (_) => _release(),
              onTapCancel: _release,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  values: widget.values,
                  sessionLabels: widget.sessionLabels,
                  formatValue: widget.formatValue,
                  repaintKey: widget.repaintKey,
                  scrubIndex: _scrubIndex,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> sessionLabels;
  final String Function(double) formatValue;
  final Object repaintKey;
  final int? scrubIndex;

  _TrendChartPainter({
    required this.values,
    required this.sessionLabels,
    required this.formatValue,
    required this.repaintKey,
    this.scrubIndex,
  });

  static const _padTop = 30.0;
  static const _padBottom = 22.0;
  static const _padRight = 14.0;

  /// Room between the y-axis labels and the plot.
  static const _labelGap = 12.0;

  /// The y axis' gutter, fixed: the plot keeps its width from one metric to
  /// the next rather than breathing with the digits in the labels. Wide
  /// enough for "2880kg" or "12m 30s".
  static const _axisWidth = 46.0;
  static const _padLeft = _axisWidth + _labelGap;

  static TextPainter _text(
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

  /// The plot's y-scale: the axis' three labels, and the space they take on
  /// the left. Static so the scrub can find x positions the same way paint
  /// lays them out.
  static ({List<double> grid, double chartMin, double span}) _scale(
    List<double> values,
  ) {
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final isFlat = max == min;
    final flatPadding = max == 0 ? 1.0 : max.abs() * 0.1;
    final chartMax = isFlat ? max + flatPadding : max;
    final chartMin = isFlat ? math.max(0.0, min - flatPadding) : min;
    return (
      grid: [chartMax, (chartMax + chartMin) / 2, chartMin],
      chartMin: chartMin,
      span: chartMax - chartMin,
    );
  }

  static double _xAt(int i,
          {required double padLeft,
          required double plotWidth,
          required int count}) =>
      count == 1
          ? padLeft + plotWidth / 2
          : padLeft + i * plotWidth / (count - 1);

  /// The session nearest an x position — what a finger at [dx] is reading.
  static int indexAt(double dx, {required double width, required int count}) {
    if (count <= 1) return 0;
    final plotWidth = width - _padLeft - _padRight;
    final t = ((dx - _padLeft) / plotWidth).clamp(0.0, 1.0);
    return (t * (count - 1)).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scale(values);
    const padLeft = _padLeft;
    final chartWidth = size.width - padLeft - _padRight;
    final chartHeight = size.height - _padTop - _padBottom;
    double xAt(int i) =>
        _xAt(i, padLeft: padLeft, plotWidth: chartWidth, count: values.length);
    double yAt(num value) =>
        _padTop + (1 - (value - scale.chartMin) / scale.span) * chartHeight;

    // Gridlines and their labels, a gap away from the plot.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (final value in scale.grid) {
      final y = yAt(value);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - _padRight, y),
        gridPaint,
      );
      final label = _text(formatValue(value), color: AppColors.textMuted);
      label.paint(
        canvas,
        Offset(_axisWidth - label.width, y - label.height / 2),
      );
    }

    // The line, then its points.
    final linePaint = Paint()
      ..color = AppColors.accentPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(xAt(i), yAt(values[i]));
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotFill = Paint()..color = AppColors.bg;
    final dotStroke = Paint()
      ..color = AppColors.accentPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Dots only when they have room to be dots; a dense line stays a line.
    final drawDots =
        values.length == 1 || chartWidth / (values.length - 1) >= 12;
    if (drawDots) {
      for (var i = 0; i < values.length; i++) {
        final point = Offset(xAt(i), yAt(values[i]));
        canvas.drawCircle(point, 3, dotFill);
        canvas.drawCircle(point, 3, dotStroke);
      }
    }

    // The x axis: dates, as many as fit without touching. The first and last
    // always; between them every k-th, so no label runs into its neighbour.
    final labels = [
      for (final s in sessionLabels)
        _text(s,
            color: s == 'Live' ? AppColors.accentPrimary : AppColors.textMuted),
    ];
    final widest = labels.map((l) => l.width).reduce(math.max) + 10;
    final perLabel =
        values.length == 1 ? chartWidth : chartWidth / (values.length - 1);
    final every = math.max(1, (widest / perLabel).ceil());
    for (var i = 0; i < labels.length; i++) {
      final isEnd = i == 0 || i == labels.length - 1;
      final onStep = (labels.length - 1 - i) % every == 0;
      if (!isEnd && !onStep) continue;
      // An end label too close to a stepped one gives way to the end.
      if (!isEnd &&
          (i < every ~/ 2 + 1 || labels.length - 1 - i < every ~/ 2 + 1) &&
          every > 1) {
        continue;
      }
      final label = labels[i];
      label.paint(
        canvas,
        Offset(
          (xAt(i) - label.width / 2).clamp(0, size.width - label.width),
          size.height - label.height,
        ),
      );
    }

    // The point being read: a guide down to the axis, the point lit, and
    // its value and date above the line.
    final scrub = scrubIndex;
    if (scrub != null && scrub >= 0 && scrub < values.length) {
      final point = Offset(xAt(scrub), yAt(values[scrub]));
      canvas.drawLine(
        Offset(point.dx, _padTop - 6),
        Offset(point.dx, size.height - _padBottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(point, 5, Paint()..color = AppColors.accentPrimary);
      canvas.drawCircle(
          point,
          5,
          Paint()
            ..color = AppColors.bg
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      final value = _text(
        formatValue(values[scrub]),
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      );
      final date = _text(sessionLabels[scrub], color: AppColors.textSecondary);
      final chipWidth = math.max(value.width, date.width) + 16;
      const chipHeight = 32.0;
      var chipLeft = point.dx - chipWidth / 2;
      chipLeft = chipLeft.clamp(0.0, size.width - chipWidth);
      final chipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chipLeft, 0, chipWidth, chipHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(chipRect, Paint()..color = AppColors.surface2);
      value.paint(
        canvas,
        Offset(chipLeft + (chipWidth - value.width) / 2, 3),
      );
      date.paint(
        canvas,
        Offset(chipLeft + (chipWidth - date.width) / 2, 3 + value.height + 1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.sessionLabels != sessionLabels ||
      oldDelegate.repaintKey != repaintKey ||
      oldDelegate.scrubIndex != scrubIndex;
}

/// Bare back chevron — the exercise names itself in the title below.
class _DetailNavBar extends StatelessWidget {
  final VoidCallback onBack;

  /// The exercise's name, shown in the middle of the bar once the heading
  /// under it has scrolled away — so the page never loses its name.
  final String title;
  final bool showTitle;

  const _DetailNavBar({
    required this.onBack,
    required this.title,
    required this.showTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Opaque, because the page scrolls underneath it rather than stopping at
    // it — including the demo, which would otherwise show through.
    return Container(
      height: _detailNavBarHeight,
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(19, 10, 22, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: AnimatedOpacity(
                opacity: showTitle ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Padding(
                  // Clear of the back chevron on either side, so a long name
                  // ellipsises rather than running under it.
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Pressable(
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
          ),
        ],
      ),
    );
  }
}

/// The demo at the top of "How to": the exercise's YouTube clip, playing in
/// place with YouTube's own controls — the player everyone already knows,
/// rather than a hand-rolled imitation of it.
///
/// Until it is tapped this is an ordinary image — the clip's own thumbnail
/// with a play button on it — so the page costs no web view, and no data,
/// until somebody wants to watch. When the clip ends, the image comes back,
/// which also means YouTube's end screen of suggested videos never shows.
///
/// The player is mounted inside an [Overlay] of its own. That is not
/// decoration: the package renders the web view through an [OverlayPortal],
/// which puts it in the *nearest* enclosing overlay. Left to find the route's
/// overlay it would sit above the whole page, clipped by nothing, and ride up
/// over the tabs and the back bar as the page scrolled. Given an overlay here,
/// it renders inside this box, where the list clips it and the pinned tabs
/// stay above it.
///
/// Fullscreen is the one thing the native controls cannot do from inside that
/// containment, so the package's interception of YouTube's fullscreen button
/// is pointed at [_FullscreenDemoPage]: a page of its own whose player picks
/// up where this one paused, handing the position back on the way out.
///
/// Where there is no web view — which is every widget test — the still
/// stands in.
class _DemoMedia extends StatefulWidget {
  final Exercise exercise;

  const _DemoMedia({required this.exercise});

  @override
  State<_DemoMedia> createState() => _DemoMediaState();
}

/// Player parameters shared by the inline demo and its fullscreen page, so
/// the two are the same player in different boxes. YouTube's controls stay
/// on; what the sheet's clips must not become is a doorway to the rest of
/// YouTube, which [_hideSuggestionShelfJs] and the ended-to-poster behaviour
/// take care of.
const _demoPlayerParams = YoutubePlayerParams(
  showControls: true,
  showFullscreenButton: true,
  strictRelatedVideos: true,
);

YoutubePlayerController _createDemoController({
  required String videoId,
  double? startSeconds,
}) {
  return YoutubePlayerController.fromVideoId(
    videoId: videoId,
    autoPlay: true,
    startSeconds: startSeconds,
    params: _demoPlayerParams,
  );
}

/// Hides the "More videos" shelf YouTube pushes into a paused frame. No
/// player parameter turns it off, but the page the package hosts the iframe
/// in is same-origin with it — the package's own fullscreen handling relies
/// on that — so a stylesheet can reach inside. The selectors are YouTube's,
/// not ours: if a redesign renames them the shelf comes back, and the player
/// still works.
///
/// Injected once the player reports its first event, when the frame is known
/// to exist; the retry loop covers it arriving late.
const _hideSuggestionShelfJs = """
(function () {
  var css = [
    // The modern mobile player: suggested-video tiles the creator pinned to
    // the end of the clip, the end grid, and the related-videos entry point
    // in the control bar. Observed live on device — these are tag names.
    'ytm-endscreen-video-renderer',
    'ytm-fullscreen-related-videos-entry-point-view-model',
    'ytm-autonav-toggle-button',
    // The classic player's names for the same furniture, kept in case
    // YouTube serves it.
    '.ytp-pause-overlay',
    '.ytp-pause-overlay-container',
    '.ytp-endscreen-content',
    '.ytp-ce-element',
    '.ytp-related-on-error-overlay'
  ].join(', ') + ' { display: none !important; }';

  function inject() {
    try {
      var frame = document.getElementsByTagName('iframe')[0];
      if (!frame || !frame.contentWindow) return false;
      var doc = frame.contentWindow.document;
      if (!doc || !doc.head) return false;
      if (doc.getElementById('forma-hide-shelf')) return true;
      var style = doc.createElement('style');
      style.id = 'forma-hide-shelf';
      style.textContent = css;
      doc.head.appendChild(style);
      return true;
    } catch (e) {
      return false;
    }
  }

  if (inject()) return;
  var tries = 0;
  var timer = setInterval(function () {
    if (inject() || ++tries > 50) clearInterval(timer);
  }, 300);
})();
""";

class _DemoMediaState extends State<_DemoMedia> {
  YoutubePlayerController? _controller;
  String? _videoId;
  StreamSubscription<YoutubePlayerValue>? _stateSubscription;
  bool _shelfHidden = false;
  bool _fullScreenOpen = false;

  @override
  void initState() {
    super.initState();
    final videoId =
        ExerciseCoachingCatalog.forExercise(widget.exercise)?.videoId;
    if (videoId == null || !_playerIsAvailable) return;
    _videoId = videoId;
  }

  /// The player is a web view, and there is no web view in a widget test.
  bool get _playerIsAvailable => WebViewPlatform.instance != null;

  /// Builds the player and starts it. Called on the tap, not before.
  void _play() {
    final videoId = _videoId;
    if (videoId == null || _controller != null) return;

    final controller = _createDemoController(videoId: videoId)
      ..setFullScreenListener(_onFullScreenRequested);
    _stateSubscription = controller.stream.listen((value) {
      if (value.playerState == PlayerState.ended) {
        _closePlayer();
        return;
      }
      // The first event is proof the player page is up and its frame exists.
      if (!_shelfHidden) {
        _shelfHidden = true;
        controller.webViewController.runJavaScript(_hideSuggestionShelfJs);
      }
    });
    setState(() => _controller = controller);
  }

  /// Tears the player down and lets the poster stand again.
  void _closePlayer() {
    if (_controller == null) return;
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _shelfHidden = false;
    _controller?.close();
    setState(() => _controller = null);
  }

  /// YouTube's fullscreen button, redirected. The package flips its own
  /// fullscreen state — which cannot render from inside the containment
  /// overlay — so the state is treated as a request: this player pauses, the
  /// fullscreen page runs its own player from the same position, and on the
  /// way back the state is reset and playback resumes where that one got to.
  Future<void> _onFullScreenRequested(bool isFullScreen) async {
    if (!isFullScreen || _fullScreenOpen || !mounted) return;
    final controller = _controller;
    final videoId = _videoId;
    if (controller == null || videoId == null) return;

    _fullScreenOpen = true;
    try {
      final position = await controller.currentTime;
      await controller.pauseVideo();
      if (!mounted) return;

      // Fullscreen video must cover the tab bar too, so it goes on the
      // root navigator even when this page lives inside a tab's stack.
      final resumeAt =
          await Navigator.of(context, rootNavigator: true).push<double>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _FullscreenDemoPage(
            videoId: videoId,
            startSeconds: position,
          ),
        ),
      );

      _controller?.exitFullScreen();
      if (!mounted || _controller == null) return;

      if (resumeAt == _endedSentinel) {
        _closePlayer();
        return;
      }
      // A fresh load rather than seek-and-play: while the fullscreen page's
      // web view was on top, iOS suspended this one's media pipeline, and a
      // suspended player told to play sticks in buffering over a black
      // frame. Loading again from the handed-back position starts clean.
      await _controller?.loadVideoById(
        videoId: videoId,
        startSeconds: resumeAt ?? position,
      );
    } finally {
      _fullScreenOpen = false;
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoId = _videoId;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: switch ((controller, videoId)) {
          (final YoutubePlayerController controller, _) => Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => YoutubePlayer(
                    controller: controller,
                    aspectRatio: 16 / 9,
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          (_, final String videoId) => Pressable(
              onTap: _play,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The clip's own thumbnail, so the still the page shows is
                  // the frame the video opens on.
                  Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _still(),
                  ),
                  const _PlayBadge(),
                ],
              ),
            ),
          _ => _still(),
        },
      ),
    );
  }

  /// What stands in for the clip: the sheet's still, the exercise's own
  /// picture, or the outline that says there is no footage yet.
  Widget _still() {
    final still =
        ExerciseCoachingCatalog.forExercise(widget.exercise)?.imageUrl;
    final imageUrl =
        (still == null || still.isEmpty) ? widget.exercise.imageUrl : still;

    return imageUrl == null
        ? const _DemoPlaceholder()
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _DemoPlaceholder(),
          );
  }
}

/// What a fullscreen page returns when the clip played to the end — the
/// inline player closes rather than resuming a finished video.
const _endedSentinel = -1.0;

/// The demo, filling the screen sideways: a page of its own with its own
/// player, started where the inline one paused. YouTube's fullscreen button
/// here means "done" — the page pops with the position it reached, or
/// [_endedSentinel] when the clip finished.
/// Turns the player page sideways from the inside. The web view itself stays
/// an ordinary portrait platform view — rotating that is exactly what iOS
/// would not do reliably — while the page's own body is quarter-turned by
/// CSS, which browsers hit-test through, so YouTube's controls keep working.
/// The player is resized to the swapped dimensions and the package's resize
/// handler is replaced with a swapped one.
const _rotatePlayerPageJs = """
(function () {
  var body = document.body;
  body.style.position = 'absolute';
  body.style.transformOrigin = 'left top';
  body.style.transform = 'rotate(90deg) translateY(-100%)';
  function fit() {
    var w = window.innerWidth, h = window.innerHeight;
    body.style.width = h + 'px';
    body.style.height = w + 'px';
    if (window.player && player.setSize) player.setSize(h, w);
  }
  window.onresize = fit;
  fit();
})();
""";

class _FullscreenDemoPage extends StatefulWidget {
  final String videoId;
  final double startSeconds;

  const _FullscreenDemoPage({
    required this.videoId,
    required this.startSeconds,
  });

  @override
  State<_FullscreenDemoPage> createState() => _FullscreenDemoPageState();
}

class _FullscreenDemoPageState extends State<_FullscreenDemoPage> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _stateSubscription;
  bool _shelfHidden = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = _createDemoController(
      videoId: widget.videoId,
      startSeconds: widget.startSeconds,
    )..setFullScreenListener((_) => _close());
    _stateSubscription = _controller.stream.listen((value) {
      if (value.playerState == PlayerState.ended && mounted) {
        Navigator.of(context).pop(_endedSentinel);
        return;
      }
      if (!_shelfHidden) {
        _shelfHidden = true;
        _controller.webViewController
          ..runJavaScript(_hideSuggestionShelfJs)
          ..runJavaScript(_rotatePlayerPageJs);
      }
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    final position = await _controller.currentTime;
    if (mounted) Navigator.of(context).pop(position);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _stateSubscription?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The page is portrait; the sideways-ness happens inside the web view,
    // which [_rotatePlayerPageJs] quarter-turns — rotating the platform view
    // itself is what iOS would not do. Out here the player is only asked to
    // fill the screen, whatever shape that is: the aspect ratio handed over
    // is the screen's own, and the rotated page inside decides what the
    // video fills.
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) => YoutubePlayer(
          controller: _controller,
          aspectRatio: constraints.maxWidth / constraints.maxHeight,
          backgroundColor: Colors.black,
          autoFullScreen: false,
          enableFullScreenOnVerticalDrag: false,
        ),
      ),
    );
  }
}

/// The play button over a thumbnail. Dark scrim behind it so a white triangle
/// reads on a bright frame.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        child: const Padding(
          // The glyph's own bearing sits it left of centre in the circle.
          padding: EdgeInsets.only(left: 3),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
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
  final Exercise exercise;

  const _HistoryCard({required this.logs, required this.exercise});

  /// The columns a set is read in, in the live workout's order: its load
  /// where it carries one — headed KG or LBS, whichever the app is set to
  /// — then what the exercise is measured in.
  List<String> get _columns => [
        if (exercise.isWeighted)
          WeightUnitService.unit == WeightUnit.lb ? 'LBS' : 'KG',
        if (exercise.isTimed) 'TIME' else 'REPS',
      ];

  List<String> _cells(ExerciseSet set) => [
        if (exercise.isWeighted) WeightUnitService.displayText(set.weightKg),
        if (exercise.isTimed)
          _formatSeconds(set.durationSeconds)
        else
          '${set.reps}',
      ];

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // One block per session, most recent first: the day as its heading,
        // then a row per set under the columns it is measured in.
        for (var i = 0; i < logs.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          Text(
            _formatShortDate(logs[i].loggedAt),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.16,
            ),
          ),
          const SizedBox(height: 8),
          _historyRow(
            leading: 'SET',
            cells: columns,
            style: monoStyle(size: 10, letterSpacing: 1.4),
            divider: true,
          ),
          for (var n = 0; n < logs[i].sets.length; n++)
            _historyRow(
              leading: '${n + 1}',
              cells: _cells(logs[i].sets[n]),
              style: monoStyle(
                size: 14,
                weight: FontWeight.w500,
                letterSpacing: 0,
                color: AppColors.textPrimary,
              ),
              divider: n < logs[i].sets.length - 1,
            ),
        ],
      ],
    );
  }

  static Widget _historyRow({
    required String leading,
    required List<String> cells,
    required TextStyle style,
    required bool divider,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(leading, style: style)),
          for (final cell in cells)
            Expanded(
              child: Text(cell, textAlign: TextAlign.right, style: style),
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

/// Coaching for this exact movement where the exercise sheet has it, and the
/// movement pattern's generic advice where it does not.
_ExerciseCoachData _coachDataFor(Exercise exercise) {
  final coaching = ExerciseCoachingCatalog.forExercise(exercise);
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
