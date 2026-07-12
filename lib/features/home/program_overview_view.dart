import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import 'program_day_editor_view.dart';
import 'program_day_items.dart';
import 'program_setup_view.dart' show GoalSkillGroup, GoalSkillOption, kGoalSkillGroups, kGoalSkillOptions;

const _statusRed = Color(0xFFE5484D);

/// Balance status: green optimal, amber under target, red over target.
enum _BalanceStatus { under, ok, over }

Color _statusColor(_BalanceStatus status) {
  switch (status) {
    case _BalanceStatus.under:
      return AppColors.amber;
    case _BalanceStatus.ok:
      return AppColors.green;
    case _BalanceStatus.over:
      return _statusRed;
  }
}

/// Movement coverage: 1–2 exercises is optimal, 0 is a gap, more than 2 is
/// overloaded.
_BalanceStatus _coverageStatus(int count) {
  if (count == 0) return _BalanceStatus.under;
  if (count <= 2) return _BalanceStatus.ok;
  return _BalanceStatus.over;
}

_BalanceStatus _muscleStatus(int sets) {
  if (sets < kProgramSetsMin) return _BalanceStatus.under;
  if (sets <= kProgramSetsMax) return _BalanceStatus.ok;
  return _BalanceStatus.over;
}

const _muscleStatusText = {
  _BalanceStatus.under: 'Below target — add a set or two',
  _BalanceStatus.ok: 'In the optimal range',
  _BalanceStatus.over: 'More volume than you need',
};

const _weekTemplates = <int, List<int>>{
  2: [1, 0, 0, 1, 0, 0, 0],
  3: [1, 0, 1, 0, 1, 0, 0],
  4: [1, 1, 0, 1, 1, 0, 0],
  5: [1, 1, 1, 0, 1, 1, 0],
  6: [1, 1, 1, 1, 1, 1, 0],
};
const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class ProgramOverviewView extends StatefulWidget {
  final TrainingProgramLogicSnapshot initialLogic;
  final Map<String, ExerciseStatus> progressMap;
  final Future<TrainingProgramLogicSnapshot> Function({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
  }) onSave;

  const ProgramOverviewView({
    super.key,
    required this.initialLogic,
    required this.progressMap,
    required this.onSave,
  });

  @override
  State<ProgramOverviewView> createState() => _ProgramOverviewViewState();
}

class _ProgramOverviewViewState extends State<ProgramOverviewView> {
  final _programService = TrainingProgramService();

  late TrainingProgramLogicSnapshot _logic;
  String? _openBalance; // 'cov' | 'mus' | null

  @override
  void initState() {
    super.initState();
    _logic = widget.initialLogic;
  }

  Map<String, dynamic> get _sessionItemsConfig {
    final raw = _logic.program.variationRules['session_items_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Map<String, dynamic> get _setupAnswers {
    final raw = _logic.program.variationRules['program_setup_v1'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  List<String> get _goalSkillIds {
    final raw = _setupAnswers['skill_ids'];
    if (raw is List) return raw.whereType<String>().toList();
    return const [];
  }

  int get _trainingDaysPerWeek =>
      _logic.program.frequencyPerWeek.clamp(2, 6);

  Map<TrainingTrack, String> get _branchSelections => {
        ..._programService.defaultBranchSelections(),
        ..._logic.branchSelections,
      };

  List<TrainingSessionType> _weekPlan(int days, TrainingProgramType type) {
    final sequence = _programService.trainingDaysForProgramType(type);
    final template = _weekTemplates[days.clamp(2, 6)]!;
    var next = 0;
    return [
      for (final on in template)
        on == 1
            ? sequence[(next++) % sequence.length]
            : TrainingSessionType.rest,
    ];
  }

  Future<void> _saveLogic({
    TrainingProgramType? programType,
    Map<String, dynamic>? sessionItemsConfig,
    int? frequencyPerWeek,
    Map<String, dynamic>? setupAnswers,
    required String toast,
  }) async {
    final updated = await widget.onSave(
      programType: programType ?? _logic.program.programType,
      branchSelections: _branchSelections,
      repGoalProfile: _logic.repGoalProfile,
      sessionItemsConfig: sessionItemsConfig ?? _sessionItemsConfig,
      frequencyPerWeek: frequencyPerWeek,
      setupAnswers: setupAnswers,
    );
    if (!mounted) return;
    setState(() => _logic = updated);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(toast)));
  }

  Future<void> _openDayEditor(TrainingSessionType sessionType) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramDayEditorView(
          sessionType: sessionType,
          programType: _logic.program.programType,
          branchSelections: _branchSelections,
          progressMap: widget.progressMap,
          sessionItemsConfig: _sessionItemsConfig,
          onSave: (config) => _saveLogic(
            sessionItemsConfig: config,
            toast: '${programDayTitle(sessionType)} day updated',
          ),
        ),
      ),
    );
  }

  Future<void> _openDaysSheet() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _DaysSheet(
        current: _trainingDaysPerWeek,
        weekPlanBuilder: (days) =>
            _weekPlan(days, _logic.program.programType),
      ),
    );

    if (picked == null || picked == _trainingDaysPerWeek || !mounted) return;

    await _saveLogic(
      frequencyPerWeek: picked,
      setupAnswers: {..._setupAnswers, 'days_per_week': picked},
      toast: 'Schedule updated',
    );
  }

  Future<void> _openSplitSheet() async {
    final picked = await showModalBottomSheet<TrainingProgramType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _SplitSheet(current: _logic.program.programType),
    );

    if (picked == null || picked == _logic.program.programType || !mounted) {
      return;
    }

    // Changing the split rebuilds every day plan from the defaults for the
    // new split — an empty config makes the service fall back to them.
    await _saveLogic(
      programType: picked,
      sessionItemsConfig: const {},
      setupAnswers: {..._setupAnswers, 'split': picked.dbValue},
      toast: 'Split changed — sessions rebuilt',
    );
  }

  Future<void> _openSkillsSheet() async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _GoalSkillsSheet(picked: _goalSkillIds),
    );

    if (picked == null || !mounted) return;

    await _saveLogic(
      setupAnswers: {..._setupAnswers, 'skill_ids': picked},
      toast: 'Goal skills updated',
    );
  }

  @override
  Widget build(BuildContext context) {
    final programType = _logic.program.programType;
    final trainingDays = _programService.trainingDaysForProgramType(
      programType,
    );
    final coverage = ProgramSessionPlan.weeklyCoverage(
      service: _programService,
      sessionItemsConfig: _sessionItemsConfig,
      programType: programType,
      branchSelections: _branchSelections,
      progressMap: widget.progressMap,
    );
    final muscleSets = ProgramSessionPlan.weeklyMuscleSets(
      service: _programService,
      sessionItemsConfig: _sessionItemsConfig,
      programType: programType,
      branchSelections: _branchSelections,
      progressMap: widget.progressMap,
    );
    final goalSkills = [
      for (final id in _goalSkillIds)
        for (final option in kGoalSkillOptions)
          if (option.id == id) option,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Program settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Your program'),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    _ProgramRow(
                      first: true,
                      label: 'Training days',
                      value: '$_trainingDaysPerWeek days / week',
                      onTap: _openDaysSheet,
                    ),
                    _ProgramRow(
                      label: 'Split',
                      value: programType.label,
                      onTap: _openSplitSheet,
                    ),
                  ],
                ),
              ),
              const SectionHeader(
                title: 'Sessions',
                sub: 'Tap a day to edit its exercises',
              ),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    for (var i = 0; i < trainingDays.length; i++)
                      _SessionRow(
                        first: i == 0,
                        title: programDayTitle(trainingDays[i]),
                        items: ProgramSessionPlan.loadDay(
                          service: _programService,
                          sessionItemsConfig: _sessionItemsConfig,
                          programType: programType,
                          sessionType: trainingDays[i],
                          branchSelections: _branchSelections,
                          progressMap: widget.progressMap,
                        ),
                        onTap: () => _openDayEditor(trainingDays[i]),
                      ),
                  ],
                ),
              ),
              SectionHeader(
                title: 'Goal skills',
                action: 'Edit',
                onAction: _openSkillsSheet,
              ),
              SurfaceCard(
                onTap: _openSkillsSheet,
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                child: goalSkills.isEmpty
                    ? const Text(
                        'No specific skills picked — Forma keeps the program balanced across every movement pattern.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final skill in goalSkills)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 8, 13, 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        skill.icon,
                                        size: 16,
                                        color: AppColors.accentPrimary,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        skill.label,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Each session weaves in progressions toward these skills.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
              const SectionHeader(title: 'Weekly balance'),
              SurfaceCard(
                clip: true,
                child: Column(
                  children: [
                    _buildCoverageGroup(coverage),
                    _buildMuscleGroup(muscleSets),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverageGroup(
    Map<ExerciseCategory, List<ProgramDayItem>> coverage,
  ) {
    const categories = ProgramSessionPlan.coverageOrder;
    final missing =
        categories.where((category) => coverage[category]!.isEmpty).length;
    final over =
        categories.where((category) => coverage[category]!.length > 2).length;

    final String summary;
    final Color summaryColor;
    if (missing == 0 && over == 0) {
      summary = 'All ${categories.length} patterns covered';
      summaryColor = AppColors.green;
    } else {
      summary = [
        if (missing > 0) '$missing pattern${missing > 1 ? 's' : ''} missing',
        if (over > 0) '$over overloaded',
      ].join(' · ');
      summaryColor = missing > 0 ? AppColors.amber : _statusRed;
    }

    return _BalanceGroup(
      first: true,
      title: 'Movement coverage',
      summary: summary,
      summaryColor: summaryColor,
      statuses: [
        for (final category in categories)
          _coverageStatus(coverage[category]!.length),
      ],
      open: _openBalance == 'cov',
      onToggle: () => setState(
        () => _openBalance = _openBalance == 'cov' ? null : 'cov',
      ),
      footer: 'Exercises per movement · aim for 1–2',
      children: [
        for (final category in categories)
          _BalanceRow(
            icon: programPatternIcon(category),
            title: programPatternLabel(category),
            subtitle: coverage[category]!.isEmpty
                ? 'No exercises programmed'
                : coverage[category]!.map((item) => item.name).join(' · '),
            subtitleColor: coverage[category]!.isEmpty
                ? AppColors.amber
                : AppColors.textSecondary,
            ringValue: coverage[category]!.length,
            ringFraction: coverage[category]!.length / 2,
            ringColor: _statusColor(
              _coverageStatus(coverage[category]!.length),
            ),
          ),
      ],
    );
  }

  Widget _buildMuscleGroup(Map<String, int> muscleSets) {
    final under = kProgramMuscleGroups
        .where((group) => _muscleStatus(muscleSets[group]!) ==
            _BalanceStatus.under)
        .toList();
    final over = kProgramMuscleGroups
        .where(
            (group) => _muscleStatus(muscleSets[group]!) == _BalanceStatus.over)
        .toList();

    final String summary;
    final Color summaryColor;
    if (under.isEmpty && over.isEmpty) {
      summary = 'All muscle groups in range';
      summaryColor = AppColors.green;
    } else {
      summary = [...over, ...under].join(', ') +
          (over.isNotEmpty ? ' overworked' : ' below target');
      summaryColor = over.isNotEmpty ? _statusRed : AppColors.amber;
    }

    return _BalanceGroup(
      title: 'Muscle volume',
      summary: summary,
      summaryColor: summaryColor,
      statuses: [
        for (final group in kProgramMuscleGroups)
          _muscleStatus(muscleSets[group]!),
      ],
      open: _openBalance == 'mus',
      onToggle: () => setState(
        () => _openBalance = _openBalance == 'mus' ? null : 'mus',
      ),
      footer: 'Sets per week · aim for $kProgramSetsMin–$kProgramSetsMax',
      children: [
        for (final group in kProgramMuscleGroups)
          _BalanceRow(
            icon: programMuscleIcon(group),
            title: group,
            subtitle: _muscleStatusText[_muscleStatus(muscleSets[group]!)]!,
            subtitleColor: _muscleStatus(muscleSets[group]!) ==
                    _BalanceStatus.ok
                ? AppColors.textSecondary
                : _statusColor(_muscleStatus(muscleSets[group]!)),
            ringValue: muscleSets[group]!,
            ringFraction: muscleSets[group]! / kProgramSetsMax,
            ringColor: _statusColor(_muscleStatus(muscleSets[group]!)),
          ),
      ],
    );
  }
}

/// Plain settings row: label · value · chevron.
class _ProgramRow extends StatelessWidget {
  final bool first;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ProgramRow({
    this.first = false,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final bool first;
  final String title;
  final List<ProgramDayItem> items;
  final VoidCallback onTap;

  const _SessionRow({
    required this.first,
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${items.length} exercises',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items.map((item) => item.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible balance group: summary row with status dots → detail rows.
class _BalanceGroup extends StatelessWidget {
  final bool first;
  final String title;
  final String summary;
  final Color summaryColor;
  final List<_BalanceStatus> statuses;
  final bool open;
  final VoidCallback onToggle;
  final List<Widget> children;
  final String footer;

  const _BalanceGroup({
    this.first = false,
    required this.title,
    required this.summary,
    required this.summaryColor,
    required this.statuses,
    required this.open,
    required this.onToggle,
    required this.children,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Pressable(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: summaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final status in statuses)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(status),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            ...children,
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  footer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final int ringValue;
  final double ringFraction;
  final Color ringColor;

  const _BalanceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.ringValue,
    required this.ringFraction,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconTile(icon: icon, size: 36),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CountRing(
            value: ringValue,
            fraction: ringFraction,
            color: ringColor,
          ),
        ],
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  final int value;
  final double fraction;
  final Color color;

  const _CountRing({
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _RingPainter(fraction: fraction, color: color),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = Colors.white.withValues(alpha: 0.09);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = 2 * math.pi * fraction.clamp(0.02, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

/// Shared scrim + slide-up sheet chrome: grabber, title, close, content.
class _SheetShell extends StatelessWidget {
  final String title;
  final String sub;
  final Widget child;
  final Widget? footer;
  final bool expand;

  const _SheetShell({
    required this.title,
    required this.sub,
    required this.child,
    this.footer,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height - media.padding.top - 24;

    return Container(
      constraints: BoxConstraints(
        maxHeight: math.min(media.size.height * 0.88, maxHeight),
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: media.padding.bottom + 14),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (expand) Expanded(child: child) else Flexible(child: child),
          if (footer != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class _DaysSheet extends StatefulWidget {
  final int current;
  final List<TrainingSessionType> Function(int days) weekPlanBuilder;

  const _DaysSheet({required this.current, required this.weekPlanBuilder});

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  static const _dayOptions = [2, 3, 4, 5, 6];
  late int _days;

  @override
  void initState() {
    super.initState();
    _days = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _days != widget.current;
    final plan = widget.weekPlanBuilder(_days);

    return _SheetShell(
      title: 'Weekly schedule',
      sub: 'How many days a week you train',
      footer: PillButton(
        label: dirty ? 'Save schedule' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_days) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final option in _dayOptions)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == _dayOptions.last ? 0 : 8,
                      ),
                      child: Pressable(
                        onTap: () => setState(() => _days = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: option == _days
                                ? AppColors.accentPrimary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$option',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: option == _days
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'days',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: option == _days
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < plan.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == plan.length - 1 ? 0 : 5,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _weekdayLetters[i],
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: plan[i] == TrainingSessionType.rest
                                  ? AppColors.surface2
                                  : AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _dayAbbr(plan[i]),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: plan[i] == TrainingSessionType.rest
                                      ? AppColors.textMuted
                                      : AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Sessions repeat in order — miss one and it slots into your next training day.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayAbbr(TrainingSessionType type) {
    switch (type) {
      case TrainingSessionType.fullBody:
        return 'FB';
      case TrainingSessionType.push:
        return 'PU';
      case TrainingSessionType.pull:
        return 'PL';
      case TrainingSessionType.upper:
        return 'UP';
      case TrainingSessionType.lower:
        return 'LO';
      case TrainingSessionType.rest:
        return 'RE';
    }
  }
}

class _SplitSheet extends StatefulWidget {
  final TrainingProgramType current;

  const _SplitSheet({required this.current});

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  late TrainingProgramType _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  String _splitSub(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Every session trains everything';
      case TrainingProgramType.pushPull:
        return 'Alternate pushing and pulling days';
      case TrainingProgramType.upperLower:
        return 'Alternate upper- and lower-body days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _picked != widget.current;

    return _SheetShell(
      title: 'Split',
      sub: 'How each week is divided into sessions',
      footer: PillButton(
        label: dirty ? 'Save & rebuild sessions' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_picked) : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            for (final type in TrainingProgramType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Pressable(
                  onTap: () => setState(() => _picked = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: _picked == type
                          ? AppColors.accentSoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _picked == type
                            ? AppColors.accentPrimary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _picked == type
                                  ? AppColors.accentPrimary
                                  : Colors.white.withValues(alpha: 0.14),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _picked == type
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _splitSub(type),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (dirty)
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 2, 2, 0),
                child: Text(
                  'Changing the split resets your day plans to a fresh default — you can fine-tune each day afterwards.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalSkillsSheet extends StatefulWidget {
  final List<String> picked;

  const _GoalSkillsSheet({required this.picked});

  @override
  State<_GoalSkillsSheet> createState() => _GoalSkillsSheetState();
}

class _GoalSkillsSheetState extends State<_GoalSkillsSheet> {
  late List<String> _picked;

  @override
  void initState() {
    super.initState();
    _picked = List.of(widget.picked);
  }

  bool get _dirty {
    final a = [..._picked]..sort();
    final b = [...widget.picked]..sort();
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _dirty;

    return _SheetShell(
      title: 'Goal skills',
      sub: 'Pick anything that excites you — Forma builds the path from where you are today',
      expand: true,
      footer: PillButton(
        label: dirty ? 'Save goal skills' : 'No changes yet',
        onTap: dirty ? () => Navigator.of(context).pop(_picked) : null,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
            child: Text(
              '${_picked.length} picked',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _picked.isEmpty
                    ? AppColors.textMuted
                    : AppColors.accentPrimary,
              ),
            ),
          ),
          for (final group in kGoalSkillGroups) ..._buildGroup(group),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(GoalSkillGroup group) {
    final skills = kGoalSkillOptions
        .where((skill) => skill.group == group.id)
        .toList();
    if (skills.isEmpty) return const [];

    final rows = <Widget>[];
    for (var index = 0; index < skills.length; index += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSkillCard(skills[index])),
              const SizedBox(width: 8),
              Expanded(
                child: index + 1 < skills.length
                    ? _buildSkillCard(skills[index + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 9),
        child: Text(
          group.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      ...rows,
    ];
  }

  Widget _buildSkillCard(GoalSkillOption skill) {
    final on = _picked.contains(skill.id);

    return Pressable(
      onTap: () => _toggle(skill.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        decoration: BoxDecoration(
          color: on ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? AppColors.accentPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  skill.icon,
                  size: 22,
                  color: on
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                ),
                if (on)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              skill.label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                for (var dot = 1; dot <= 3; dot++)
                  Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.only(right: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot <= skill.difficulty + 1
                          ? (on
                              ? AppColors.accentPrimary
                              : AppColors.textSecondary)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
