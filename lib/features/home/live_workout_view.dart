import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';

const _workoutCard = Color(0xFF09090B);
const _workoutBg = _workoutCard;
const _workoutSurface = Color(0x08FFFFFF);
const _workoutSurfaceBorder = Color(0x0DFFFFFF);

class LiveWorkoutView extends StatefulWidget {
  final DailyTrainingRecommendation recommendation;

  const LiveWorkoutView({
    super.key,
    required this.recommendation,
  });

  @override
  State<LiveWorkoutView> createState() => _LiveWorkoutViewState();
}

class _LiveWorkoutViewState extends State<LiveWorkoutView>
    with WidgetsBindingObserver {
  static const _sectionOrder = [
    ExerciseProgramSection.warmup,
    ExerciseProgramSection.skillWork,
    ExerciseProgramSection.mainExercises,
    ExerciseProgramSection.coolDown,
  ];

  late final DateTime _startedAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  String _formatElapsed() {
    final elapsed = DateTime.now().difference(_startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }

    final totalMinutes = elapsed.inMinutes;
    return '${twoDigits(totalMinutes)}:${twoDigits(seconds)}';
  }

  List<TrainingRecommendationItem> _itemsForSection(
    ExerciseProgramSection section,
  ) {
    return widget.recommendation.items
        .where((item) => item.exercise.programSection == section)
        .toList();
  }

  void _finishWorkout() {
    Navigator.of(context).pop();
  }

  void _openExerciseDetail(
    TrainingRecommendationItem item,
    Color sectionColor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseDetailSheet(
        item: item,
        sectionColor: sectionColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visibleSections = _sectionOrder
        .map((section) => (section: section, items: _itemsForSection(section)))
        .where((entry) => entry.items.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: _workoutBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: keyboardOpen
            ? const _HideKeyboardButton()
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _LiveWorkoutTopBar(
              title: widget.recommendation.sessionLabel,
              elapsed: _formatElapsed(),
              onFinish: _finishWorkout,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  if (visibleSections.isEmpty)
                    const _EmptyWorkoutState()
                  else
                    ...visibleSections.map(
                      (entry) => _LiveSectionBlock(
                        section: entry.section,
                        items: entry.items,
                        onOpenDetail: _openExerciseDetail,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HideKeyboardButton extends StatelessWidget {
  const _HideKeyboardButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'hide-workout-keyboard',
      onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
      backgroundColor: AppColors.accentPrimary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.keyboard_hide_rounded, size: 18),
      label: Text(
        'Hide keyboard',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LiveWorkoutTopBar extends StatelessWidget {
  final String title;
  final String elapsed;
  final VoidCallback onFinish;

  const _LiveWorkoutTopBar({
    required this.title,
    required this.elapsed,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _TimerPill(elapsed: elapsed),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onFinish,
            style: TextButton.styleFrom(
              backgroundColor: _workoutSurface,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Text(
              'Finish',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String elapsed;

  const _TimerPill({
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        elapsed,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.accentPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _LiveSectionBlock extends StatelessWidget {
  final ExerciseProgramSection section;
  final List<TrainingRecommendationItem> items;
  final void Function(TrainingRecommendationItem item, Color sectionColor)
      onOpenDetail;

  const _LiveSectionBlock({
    required this.section,
    required this.items,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final sectionColor = _sectionColor(section);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: sectionColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  section.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${items.length} exercises',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.borderPrimary,
                    ),
                  _LiveExerciseCard(
                    key: ValueKey(items[index].exercise.id),
                    item: items[index],
                    sectionColor: sectionColor,
                    onOpenDetail: () => onOpenDetail(
                      items[index],
                      sectionColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveExerciseCard extends StatefulWidget {
  final TrainingRecommendationItem item;
  final Color sectionColor;
  final VoidCallback onOpenDetail;

  const _LiveExerciseCard({
    super.key,
    required this.item,
    required this.sectionColor,
    required this.onOpenDetail,
  });

  @override
  State<_LiveExerciseCard> createState() => _LiveExerciseCardState();
}

class _LiveExerciseCardState extends State<_LiveExerciseCard> {
  late List<_WorkoutSetDraft> _sets;

  @override
  void initState() {
    super.initState();
    _sets = List.generate(
      _defaultSetCount(widget.item),
      (index) => _WorkoutSetDraft(
        number: index + 1,
        target: _defaultTarget(widget.item),
        previousLabel: '-',
      ),
    );
  }

  bool get _isTimed => _isTimedExercise(widget.item.exercise);
  int get _completedCount => _sets.where((set) => set.completed).length;
  bool get _allDone => _sets.isNotEmpty && _completedCount == _sets.length;

  void _toggleSet(int number) {
    setState(() {
      _sets = _sets
          .map(
            (set) => set.number == number
                ? set.copyWith(completed: !set.completed)
                : set,
          )
          .toList();
    });
  }

  void _addSet() {
    setState(() {
      final target =
          _sets.isEmpty ? _defaultTarget(widget.item) : _sets.last.target;
      _sets = [
        ..._sets,
        _WorkoutSetDraft(
          number: _sets.length + 1,
          target: target,
          previousLabel: '-',
        ),
      ];
    });
  }

  void _removeSet(int number) {
    if (_sets.length <= 1) return;

    setState(() {
      final remaining = _sets.where((set) => set.number != number).toList();
      _sets = [
        for (var index = 0; index < remaining.length; index++)
          remaining[index].copyWith(number: index + 1),
      ];
    });
  }

  Future<void> _openTimedSetTimer(_WorkoutSetDraft set) async {
    final seconds = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimedSetTimerSheet(
        accentColor: widget.sectionColor,
        exerciseName: widget.item.exercise.name,
        initialTarget: set.target,
        setNumber: set.number,
      ),
    );

    if (seconds == null || !mounted) return;

    setState(() {
      _sets = _sets
          .map(
            (draft) => draft.number == set.number
                ? draft.copyWith(target: seconds, completed: true)
                : draft,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.item.exercise;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _allDone
            ? AppColors.accentPrimary.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onOpenDetail,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  _ExerciseTypeBadge(
                    color: widget.sectionColor,
                    isTimed: _isTimed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                exercise.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (_allDone) ...[
                              const SizedBox(width: 7),
                              _DoneChip(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.item.track.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _workoutSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _workoutSurfaceBorder),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                _SetHeader(
                  label: _isTimed ? 'Sec' : 'Reps',
                  hasTimer: _isTimed,
                ),
                const SizedBox(height: 4),
                ..._sets.map(
                  (set) => _SetRow(
                    key: ValueKey('${exercise.id}-${set.number}'),
                    set: set,
                    hasTimer: _isTimed,
                    timerColor: widget.sectionColor,
                    onOpenTimer:
                        _isTimed ? () => _openTimedSetTimer(set) : null,
                    onToggle: () => _toggleSet(set.number),
                    onRemove:
                        _sets.length > 1 ? () => _removeSet(set.number) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AddSetButton(onPressed: _addSet),
                    ),
                    const SizedBox(width: 8),
                    const _SwapExerciseButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTypeBadge extends StatelessWidget {
  final Color color;
  final bool isTimed;

  const _ExerciseTypeBadge({
    required this.color,
    required this.isTimed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(
        isTimed ? Icons.timer_outlined : Icons.bar_chart_rounded,
        size: 16,
        color: color,
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'DONE',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SetHeader extends StatelessWidget {
  final String label;
  final bool hasTimer;

  const _SetHeader({
    required this.label,
    required this.hasTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'SET',
              textAlign: TextAlign.center,
              style: _setHeaderStyle(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              'PREV',
              textAlign: TextAlign.center,
              style: _setHeaderStyle(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: _setHeaderStyle(),
            ),
          ),
          const Spacer(),
          SizedBox(width: hasTimer ? 124 : 80),
        ],
      ),
    );
  }

  static TextStyle _setHeaderStyle() {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: AppColors.textMuted,
      letterSpacing: 0.8,
    );
  }
}

class _SetRow extends StatefulWidget {
  final _WorkoutSetDraft set;
  final bool hasTimer;
  final Color timerColor;
  final VoidCallback? onOpenTimer;
  final VoidCallback onToggle;
  final VoidCallback? onRemove;

  const _SetRow({
    super.key,
    required this.set,
    required this.hasTimer,
    required this.timerColor,
    this.onOpenTimer,
    required this.onToggle,
    this.onRemove,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.set.target.toString());
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextText = widget.set.target.toString();
    if (nextText != _controller.text) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.set.completed;

    return Opacity(
      opacity: completed ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                widget.set.number.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color:
                      completed ? AppColors.accentPrimary : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(
                widget.set.previousLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: completed
                      ? AppColors.accentPrimary.withValues(alpha: 0.08)
                      : _workoutSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: completed
                          ? AppColors.accentPrimary.withValues(alpha: 0.24)
                          : AppColors.borderPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Spacer(),
            SizedBox(
              width: widget.hasTimer ? 124 : 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.hasTimer) ...[
                    IconButton(
                      onPressed: widget.onOpenTimer,
                      tooltip: 'Open timer',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            widget.timerColor.withValues(alpha: 0.12),
                        fixedSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: widget.timerColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    onPressed: widget.onToggle,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: completed
                          ? AppColors.accentPrimary
                          : Colors.white.withValues(alpha: 0.07),
                      fixedSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: completed ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (widget.onRemove != null)
                    IconButton(
                      onPressed: widget.onRemove,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        fixedSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TimedSetTimerSheet extends StatefulWidget {
  final Color accentColor;
  final String exerciseName;
  final int initialTarget;
  final int setNumber;

  const _TimedSetTimerSheet({
    required this.accentColor,
    required this.exerciseName,
    required this.initialTarget,
    required this.setNumber,
  });

  @override
  State<_TimedSetTimerSheet> createState() => _TimedSetTimerSheetState();
}

class _TimedSetTimerSheetState extends State<_TimedSetTimerSheet> {
  Timer? _ticker;
  int _countdown = 3;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        if (_countdown > 1) {
          _countdown -= 1;
        } else if (_countdown == 1) {
          _countdown = 0;
        } else {
          _elapsedSeconds += 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final countdownActive = _countdown > 0;

    return Container(
      decoration: const BoxDecoration(
        color: _workoutBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target ${widget.initialTarget} sec',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: _workoutSurface,
                      fixedSize: const Size(36, 36),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: countdownActive
                    ? Text(
                        _countdown.toString(),
                        key: ValueKey(_countdown),
                        style: GoogleFonts.inter(
                          fontSize: 86,
                          fontWeight: FontWeight.w900,
                          color: widget.accentColor,
                          height: 1,
                        ),
                      )
                    : Text(
                        _formatElapsed(),
                        key: const ValueKey('elapsed'),
                        style: GoogleFonts.inter(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: countdownActive
                      ? null
                      : () => Navigator.of(context).pop(_elapsedSeconds),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.black,
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.35),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddSetButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        minimumSize: const Size.fromHeight(38),
        side: const BorderSide(color: AppColors.borderPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(
        'ADD SET',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SwapExerciseButton extends StatelessWidget {
  const _SwapExerciseButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        minimumSize: const Size(84, 38),
        side: const BorderSide(color: AppColors.borderPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'SWAP',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _ExerciseDetailSheet extends StatefulWidget {
  final TrainingRecommendationItem item;
  final Color sectionColor;

  const _ExerciseDetailSheet({
    required this.item,
    required this.sectionColor,
  });

  @override
  State<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<_ExerciseDetailSheet> {
  bool _showProgressions = false;

  @override
  Widget build(BuildContext context) {
    final exercise = widget.item.exercise;
    final progressions = ExerciseCatalog.forCategory(exercise.category);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _workoutBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: _workoutSurface,
                        fixedSize: const Size(36, 36),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exercise.category.label} · ${_difficultyLabel(exercise.difficulty)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  children: [
                    _DemoPlaceholder(color: widget.sectionColor),
                    const SizedBox(height: 16),
                    _DetailTabs(
                      showProgressions: _showProgressions,
                      onChanged: (value) =>
                          setState(() => _showProgressions = value),
                    ),
                    const SizedBox(height: 16),
                    if (_showProgressions)
                      _ProgressionList(
                        exercise: exercise,
                        progressions: progressions,
                        color: widget.sectionColor,
                      )
                    else
                      _HowToList(
                          exercise: exercise, color: widget.sectionColor),
                    const SizedBox(height: 16),
                    _MuscleGroupCard(item: widget.item),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DemoPlaceholder extends StatelessWidget {
  final Color color;

  const _DemoPlaceholder({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.38),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'EXERCISE DEMO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final bool showProgressions;
  final ValueChanged<bool> onChanged;

  const _DetailTabs({
    required this.showProgressions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _workoutSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _DetailTabButton(
            label: 'How To',
            selected: !showProgressions,
            onTap: () => onChanged(false),
          ),
          _DetailTabButton(
            label: 'Progressions',
            selected: showProgressions,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _DetailTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DetailTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _HowToList extends StatelessWidget {
  final Exercise exercise;
  final Color color;

  const _HowToList({
    required this.exercise,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      exercise.description,
      'Move with control and keep every rep repeatable.',
      'Stop the set when form breaks down.',
    ];

    return Column(
      children: [
        for (var index = 0; index < tips.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NumberedTip(
              number: index + 1,
              text: tips[index],
              color: color,
            ),
          ),
      ],
    );
  }
}

class _NumberedTip extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _NumberedTip({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _workoutSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _workoutSurfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFD4D4D8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressionList extends StatelessWidget {
  final Exercise exercise;
  final List<Exercise> progressions;
  final Color color;

  const _ProgressionList({
    required this.exercise,
    required this.progressions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKILL LADDER - YOUR POSITION MARKED',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 10),
        ...progressions.map((progression) {
          final isCurrent = progression.id == exercise.id;
          final isPast = progression.treeOrder < exercise.treeOrder;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isCurrent ? color.withValues(alpha: 0.10) : _workoutSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? color.withValues(alpha: 0.42)
                      : _workoutSurfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast || isCurrent
                          ? color.withValues(alpha: 0.12)
                          : _workoutSurface,
                      border: Border.all(
                        color: isPast || isCurrent
                            ? color
                            : AppColors.borderPrimary,
                        width: 1.5,
                      ),
                    ),
                    child: isPast
                        ? Icon(Icons.check_rounded, size: 13, color: color)
                        : isCurrent
                            ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progression.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent
                            ? AppColors.textPrimary
                            : isPast
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'YOU ARE HERE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MuscleGroupCard extends StatelessWidget {
  final TrainingRecommendationItem item;

  const _MuscleGroupCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      item.sourceCategory.label,
      item.track.label,
      _difficultyLabel(item.exercise.difficulty),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _workoutSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _workoutSurfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAINING FOCUS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map(
                  (chip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderPrimary),
                    ),
                    child: Text(
                      chip,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _workoutCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Text(
        'No exercises queued for this session.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _WorkoutSetDraft {
  final int number;
  final int target;
  final String previousLabel;
  final bool completed;

  const _WorkoutSetDraft({
    required this.number,
    required this.target,
    required this.previousLabel,
    this.completed = false,
  });

  _WorkoutSetDraft copyWith({
    int? number,
    int? target,
    String? previousLabel,
    bool? completed,
  }) {
    return _WorkoutSetDraft(
      number: number ?? this.number,
      target: target ?? this.target,
      previousLabel: previousLabel ?? this.previousLabel,
      completed: completed ?? this.completed,
    );
  }
}

Color _sectionColor(ExerciseProgramSection section) {
  switch (section) {
    case ExerciseProgramSection.warmup:
      return const Color(0xFF4ECDC4);
    case ExerciseProgramSection.skillWork:
      return const Color(0xFFA78BFA);
    case ExerciseProgramSection.mainExercises:
      return AppColors.accentPrimary;
    case ExerciseProgramSection.coolDown:
      return const Color(0xFF34D399);
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

int _defaultSetCount(TrainingRecommendationItem item) {
  switch (item.exercise.programSection) {
    case ExerciseProgramSection.warmup:
      return 2;
    case ExerciseProgramSection.skillWork:
      return 3;
    case ExerciseProgramSection.mainExercises:
      return item.exercise.difficulty >= 4 ? 4 : 3;
    case ExerciseProgramSection.coolDown:
      return 2;
  }
}

int _defaultTarget(TrainingRecommendationItem item) {
  if (_isTimedExercise(item.exercise)) {
    if (item.exercise.difficulty <= 1) return 30;
    if (item.exercise.difficulty <= 3) return 20;
    return 12;
  }

  if (item.exercise.difficulty <= 1) return 12;
  if (item.exercise.difficulty <= 3) return 8;
  return 5;
}

String _difficultyLabel(int difficulty) {
  if (difficulty <= 1) return 'Beginner';
  if (difficulty <= 3) return 'Intermediate';
  return 'Advanced';
}
