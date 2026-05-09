import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';

const _bg = Color(0xFF000000);
const _group = Color(0xFF1C1C1E);
const _sep = Color(0x14FFFFFF);
const _text = Color(0xFFF2F2F7);
const _text2 = Color(0xFF8E8E93);
const _text3 = Color(0xFF636366);
const _accent = Color(0xFFD4FF3A);
const _accentDim = Color(0x2ED4FF3A);
const _blue = Color(0xFF0A84FF);
const _red = Color(0xFFFF453A);
const _warm = Color(0xFF64D2FF);
const _skill = Color(0xFFBF5AF2);

class TrainingProgramLogicView extends StatefulWidget {
  final TrainingProgramLogicSnapshot initialLogic;
  final Map<String, ExerciseStatus> progressMap;
  final Future<void> Function({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
  }) onSave;

  const TrainingProgramLogicView({
    super.key,
    required this.initialLogic,
    required this.progressMap,
    required this.onSave,
  });

  @override
  State<TrainingProgramLogicView> createState() =>
      _TrainingProgramLogicViewState();
}

class _TrainingProgramLogicViewState extends State<TrainingProgramLogicView> {
  final _programService = TrainingProgramService();

  late TrainingProgramType _selectedProgramType;
  late Map<TrainingTrack, String> _selectedBranches;
  late RepGoalProfile _repGoalProfile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProgramType = widget.initialLogic.program.programType;
    _selectedBranches = {
      ..._programService.defaultBranchSelections(),
      ...widget.initialLogic.branchSelections,
    };
    _repGoalProfile = widget.initialLogic.repGoalProfile;
  }

  Map<TrainingTrack, TrainingBranchOption> get _resolvedBranches =>
      _programService.resolveSelectedBranches(_selectedBranches);

  List<TrainingTrack> get _strengthTracks => _programService
      .editableTracksForProgramType(_selectedProgramType)
      .where((track) => track != TrainingTrack.skillWork)
      .toList();

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await widget.onSave(
        programType: _selectedProgramType,
        branchSelections: _selectedBranches,
        repGoalProfile: _repGoalProfile,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save program logic: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final split = _selectedProgramType;
    final repGoal = _repGoalProfile;
    final skillOption = _resolvedBranches[TrainingTrack.skillWork]!;
    final skillExercise = _programService.currentExerciseForOption(
      skillOption,
      widget.progressMap,
    );
    final totalTracks = _strengthTracks.length + 1;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: _accent,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: LoadingIndicator(),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Program',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.1,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _programTitle(split),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _text2,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(text: 'Program'),
                    _SettingsGroup(
                      footer:
                          'Picks the rhythm of your week and the rep range each track is built around.',
                      children: [
                        _SettingsRow(
                          first: true,
                          icon: Icons.calendar_month_outlined,
                          iconColor: _blue,
                          title: 'Split',
                          value: _splitShort(split),
                          onTap: () => _openSplitScreen(context),
                        ),
                        _SettingsRow(
                          icon: Icons.adjust_outlined,
                          iconColor: _accent,
                          title: 'Rep Target',
                          value: repGoal.label,
                          onTap: () => _openRepGoalScreen(context),
                        ),
                        _SettingsRow(
                          last: true,
                          icon: Icons.view_timeline_outlined,
                          iconColor: _text2,
                          title: 'Block',
                          value: 'Program logic',
                          onTap: () => _openInfoScreen(
                            context,
                            title: 'Block',
                            footer:
                                'This screen explains how the current split, rep target, and branch choices combine into one active training plan.',
                            rows: const [
                              _StaticRowData(
                                title: 'Current focus',
                                value: 'Editable',
                              ),
                              _StaticRowData(
                                title: 'Scope',
                                value: 'Split · Rep target · Tracks',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel(text: 'Session'),
                    _SettingsGroup(
                      footer:
                          'Every session runs warm-up, skill work, strength, then cool-down.',
                      children: [
                        _SettingsRow(
                          first: true,
                          icon: Icons.wb_sunny_outlined,
                          iconColor: _warm,
                          title: 'Warm-up',
                          value: 'System',
                          onTap: () => _openInfoScreen(
                            context,
                            title: 'Warm-up',
                            footer:
                                'Joint-by-joint prep so the work surfaces are ready. Keep it short and specific.',
                            rows: const [
                              _StaticRowData(
                                title: 'Type',
                                value: 'Built in',
                              ),
                              _StaticRowData(
                                title: 'Purpose',
                                value: 'Prepare shoulders, wrists, hips',
                              ),
                            ],
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.auto_awesome_motion_outlined,
                          iconColor: _skill,
                          title: 'Skill Work',
                          sub: _trackSubline(
                            skillOption,
                            skillExercise,
                            _repGoalProfile,
                          ),
                          value: skillOption.title,
                          onTap: () => _openTrackScreen(
                            context,
                            track: TrainingTrack.skillWork,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.fitness_center_outlined,
                          iconColor: _accent,
                          title: 'Strength',
                          value: '$totalTracks tracks',
                          onTap: () => _openStrengthScreen(context),
                        ),
                        _SettingsRow(
                          last: true,
                          icon: Icons.airline_seat_flat_outlined,
                          iconColor: _warm,
                          title: 'Cool-down',
                          value: 'System',
                          onTap: () => _openInfoScreen(
                            context,
                            title: 'Cool-down',
                            footer:
                                'Down-regulate and lock in whatever mobility the session earned while the tissue is warm.',
                            rows: const [
                              _StaticRowData(
                                title: 'Type',
                                value: 'Built in',
                              ),
                              _StaticRowData(
                                title: 'Purpose',
                                value: 'Breathing · Mobility',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _SectionLabel(text: 'Schedule'),
                    _SettingsGroup(
                      footer:
                          '${_programService.scheduleCycleFor(programType: split).where((day) => day != TrainingSessionType.rest).length} training days per week.',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              for (final day
                                  in _programService.scheduleCycleFor(
                                programType: split,
                              ))
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: day == TrainingSessionType.rest
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : _accentDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: day == TrainingSessionType.rest
                                            ? Colors.transparent
                                            : _accent.withValues(alpha: 0.30),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        day == TrainingSessionType.rest
                                            ? 'Rest'
                                            : _shortDay(day),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: day == TrainingSessionType.rest
                                              ? _text3
                                              : _accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SettingsGroup(
                      children: [
                        _SettingsRow(
                          first: true,
                          title: 'Reset to defaults',
                          titleColor: _red,
                          accessory: _RowAccessory.none,
                          onTap: _resetToDefaults,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _programTitle(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Full body schedule with one active branch per slot';
      case TrainingProgramType.pushPull:
        return 'Push / pull split with one active branch per slot';
      case TrainingProgramType.upperLower:
        return 'Upper / lower split with one active branch per slot';
    }
  }

  String _splitShort(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Full Body';
      case TrainingProgramType.pushPull:
        return 'Push · Pull';
      case TrainingProgramType.upperLower:
        return 'Upper · Lower';
    }
  }

  String _repSub(RepGoalProfile profile) {
    switch (profile) {
      case RepGoalProfile.strength:
        return '3–5 sets · 3–8 reps · 2:30–3:30 rest';
      case RepGoalProfile.balanced:
        return '3–4 sets · 6–12 reps · 1:30–2:30 rest';
      case RepGoalProfile.volume:
        return '2–4 sets · 10–20 reps · 0:45–1:30 rest';
    }
  }

  String _trackSubline(
    TrainingBranchOption option,
    Exercise? currentExercise,
    RepGoalProfile profile,
  ) {
    final rep = switch (profile) {
      RepGoalProfile.strength => '3–8 reps',
      RepGoalProfile.balanced => '3x8 reps',
      RepGoalProfile.volume => '3x12 reps',
    };
    return '${option.trainingPathId} · ${currentExercise?.name ?? option.title} · $rep';
  }

  String _shortDay(TrainingSessionType type) {
    switch (type) {
      case TrainingSessionType.fullBody:
        return 'Full';
      case TrainingSessionType.push:
        return 'Push';
      case TrainingSessionType.pull:
        return 'Pull';
      case TrainingSessionType.upper:
        return 'Upper';
      case TrainingSessionType.lower:
        return 'Lower';
      case TrainingSessionType.rest:
        return 'Rest';
    }
  }

  Future<void> _openSplitScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<TrainingProgramType>(
      MaterialPageRoute(
        builder: (_) => _SplitSettingsView(
          current: _selectedProgramType,
        ),
      ),
    );

    if (result == null) return;
    setState(() => _selectedProgramType = result);
  }

  Future<void> _openRepGoalScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<RepGoalProfile>(
      MaterialPageRoute(
        builder: (_) => _RepGoalSettingsView(
          current: _repGoalProfile,
          subBuilder: _repSub,
        ),
      ),
    );

    if (result == null) return;
    setState(() => _repGoalProfile = result);
  }

  Future<void> _openStrengthScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StrengthSettingsView(
          tracks: _strengthTracks,
          resolvedBranches: _resolvedBranches,
          progressMap: widget.progressMap,
          programService: _programService,
          repGoalProfile: _repGoalProfile,
          onOpenTrack: (track) => _openTrackScreen(context, track: track),
        ),
      ),
    );
  }

  Future<void> _openTrackScreen(
    BuildContext context, {
    required TrainingTrack track,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _TrackSettingsView(
          track: track,
          selectedId: _selectedBranches[track]!,
          options: _programService.branchOptionsForTrack(track),
          currentExercise: _programService.currentExerciseForOption(
            _resolvedBranches[track]!,
            widget.progressMap,
          ),
          repGoalProfile: _repGoalProfile,
        ),
      ),
    );

    if (result == null) return;
    setState(() => _selectedBranches[track] = result);
  }

  Future<void> _openInfoScreen(
    BuildContext context, {
    required String title,
    required String footer,
    required List<_StaticRowData> rows,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InfoSettingsView(
          title: title,
          footer: footer,
          rows: rows,
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _selectedProgramType = widget.initialLogic.program.programType;
      _selectedBranches = {
        ..._programService.defaultBranchSelections(),
        ...widget.initialLogic.branchSelections,
      };
      _repGoalProfile = widget.initialLogic.repGoalProfile;
    });
  }
}

class _SplitSettingsView extends StatefulWidget {
  final TrainingProgramType current;

  const _SplitSettingsView({
    required this.current,
  });

  @override
  State<_SplitSettingsView> createState() => _SplitSettingsViewState();
}

class _SplitSettingsViewState extends State<_SplitSettingsView> {
  late TrainingProgramType _picked;
  final _programService = TrainingProgramService();

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _programService.scheduleCycleFor(programType: _picked);

    return _SettingsScreenScaffold(
      title: 'Split',
      onBack: () => Navigator.of(context).pop(),
      trailingText: 'Save',
      onTrailingTap: () => Navigator.of(context).pop(_picked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Choose'),
          _SettingsGroup(
            footer: _splitRationale(_picked),
            children: [
              for (var i = 0; i < TrainingProgramType.values.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == TrainingProgramType.values.length - 1,
                  title: _splitName(TrainingProgramType.values[i]),
                  sub:
                      '${_programService.scheduleCycleFor(programType: TrainingProgramType.values[i]).where((day) => day != TrainingSessionType.rest).length} training days',
                  accessory: _picked == TrainingProgramType.values[i]
                      ? _RowAccessory.check
                      : _RowAccessory.none,
                  onTap: () {
                    setState(() => _picked = TrainingProgramType.values[i]);
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(text: 'Preview'),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    for (final day in cycle)
                      Expanded(
                        child: Container(
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: day == TrainingSessionType.rest
                                ? Colors.white.withValues(alpha: 0.04)
                                : _accentDim,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              day == TrainingSessionType.rest
                                  ? '·'
                                  : _shortSplitPreview(day),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: day == TrainingSessionType.rest
                                    ? _text3
                                    : _accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _splitName(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Full Body';
      case TrainingProgramType.pushPull:
        return 'Push / Pull';
      case TrainingProgramType.upperLower:
        return 'Upper / Lower';
    }
  }

  String _splitRationale(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return '3 sessions per week hitting every pattern. Best for lower frequency and balanced trainees.';
      case TrainingProgramType.pushPull:
        return 'Alternates pressing and pulling emphasis while still keeping trunk and legs in the week.';
      case TrainingProgramType.upperLower:
        return 'Classic 4-day rhythm with more room for upper-body work and good recovery.';
    }
  }

  String _shortSplitPreview(TrainingSessionType type) {
    switch (type) {
      case TrainingSessionType.fullBody:
        return 'FB';
      case TrainingSessionType.push:
        return 'PUSH';
      case TrainingSessionType.pull:
        return 'PULL';
      case TrainingSessionType.upper:
        return 'UP';
      case TrainingSessionType.lower:
        return 'LOW';
      case TrainingSessionType.rest:
        return '·';
    }
  }
}

class _RepGoalSettingsView extends StatefulWidget {
  final RepGoalProfile current;
  final String Function(RepGoalProfile profile) subBuilder;

  const _RepGoalSettingsView({
    required this.current,
    required this.subBuilder,
  });

  @override
  State<_RepGoalSettingsView> createState() => _RepGoalSettingsViewState();
}

class _RepGoalSettingsViewState extends State<_RepGoalSettingsView> {
  late RepGoalProfile _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScreenScaffold(
      title: 'Rep Target',
      onBack: () => Navigator.of(context).pop(),
      trailingText: 'Save',
      onTrailingTap: () => Navigator.of(context).pop(_picked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Threshold'),
          _SettingsGroup(
            footer: _goalDescription(_picked),
            children: [
              for (var i = 0; i < RepGoalProfile.values.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == RepGoalProfile.values.length - 1,
                  title: RepGoalProfile.values[i].label,
                  sub: widget.subBuilder(RepGoalProfile.values[i]),
                  accessory: _picked == RepGoalProfile.values[i]
                      ? _RowAccessory.check
                      : _RowAccessory.none,
                  onTap: () {
                    setState(() => _picked = RepGoalProfile.values[i]);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _goalDescription(RepGoalProfile profile) {
    switch (profile) {
      case RepGoalProfile.strength:
        return 'Heavier loads, longer rest. Treats the branch like a strength pursuit.';
      case RepGoalProfile.balanced:
        return 'Moderate loads and moderate rest. Balances progression speed, skill quality, and total work.';
      case RepGoalProfile.volume:
        return 'Longer sets and shorter rest. Pushes the branch toward work capacity and repeatable volume.';
    }
  }
}

class _StrengthSettingsView extends StatelessWidget {
  final List<TrainingTrack> tracks;
  final Map<TrainingTrack, TrainingBranchOption> resolvedBranches;
  final Map<String, ExerciseStatus> progressMap;
  final TrainingProgramService programService;
  final RepGoalProfile repGoalProfile;
  final ValueChanged<TrainingTrack> onOpenTrack;

  const _StrengthSettingsView({
    required this.tracks,
    required this.resolvedBranches,
    required this.progressMap,
    required this.programService,
    required this.repGoalProfile,
    required this.onOpenTrack,
  });

  @override
  Widget build(BuildContext context) {
    final total = tracks.length;

    return _SettingsScreenScaffold(
      title: 'Strength',
      large: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Movement Patterns'),
          _SettingsGroup(
            footer:
                'Seven movement patterns cover every basic plane. Each slot can hold a calisthenics progression or a single weighted lift.',
            children: [
              for (var i = 0; i < tracks.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == tracks.length - 1,
                  title: tracks[i].label,
                  sub: _strengthSubline(
                    resolvedBranches[tracks[i]]!,
                    programService.currentExerciseForOption(
                      resolvedBranches[tracks[i]]!,
                      progressMap,
                    ),
                    repGoalProfile,
                  ),
                  value: '1/1',
                  onTap: () => onOpenTrack(tracks[i]),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(text: 'Summary'),
          _SettingsGroup(
            footer: 'Tracks across all seven patterns.',
            children: [
              _SettingsRow(
                first: true,
                last: true,
                title: 'Total tracks',
                value: '$total',
                accessory: _RowAccessory.none,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _strengthSubline(
    TrainingBranchOption option,
    Exercise? currentExercise,
    RepGoalProfile profile,
  ) {
    final reps = switch (profile) {
      RepGoalProfile.strength => '3–8 reps',
      RepGoalProfile.balanced => '3x8 reps',
      RepGoalProfile.volume => '3x12 reps',
    };
    return '${option.title} · ${currentExercise?.name ?? option.title} · $reps';
  }
}

class _TrackSettingsView extends StatelessWidget {
  final TrainingTrack track;
  final String selectedId;
  final List<TrainingBranchOption> options;
  final Exercise? currentExercise;
  final RepGoalProfile repGoalProfile;

  const _TrackSettingsView({
    required this.track,
    required this.selectedId,
    required this.options,
    required this.currentExercise,
    required this.repGoalProfile,
  });

  @override
  Widget build(BuildContext context) {
    final option = options.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => options.first,
    );

    return _SettingsScreenScaffold(
      title: track.label,
      large: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Track'),
          _SettingsGroup(
            footer: option.rationale,
            children: [
              _SettingsRow(
                first: true,
                title: 'Skill Tree',
                value: option.sourceSkillCategoryId,
                accessory: _RowAccessory.none,
              ),
              _SettingsRow(
                title: 'Branch',
                value: option.title,
                onTap: () async {
                  final picked = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => _TrackOptionPickerView(
                        title: track.label,
                        options: options,
                        selectedId: selectedId,
                      ),
                    ),
                  );

                  if (picked == null || !context.mounted) return;
                  Navigator.of(context).pop(picked);
                },
              ),
              _SettingsRow(
                last: true,
                title: 'Current step',
                sub: currentExercise?.name,
                value: _repGoalValue(repGoalProfile),
                accessory: _RowAccessory.none,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(text: 'Actions'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                first: true,
                title: 'Switch Track',
                onTap: () async {
                  final picked = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => _TrackOptionPickerView(
                        title: track.label,
                        options: options,
                        selectedId: selectedId,
                      ),
                    ),
                  );

                  if (picked == null || !context.mounted) return;
                  Navigator.of(context).pop(picked);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _repGoalValue(RepGoalProfile profile) {
    switch (profile) {
      case RepGoalProfile.strength:
        return '5x5';
      case RepGoalProfile.balanced:
        return '3x8';
      case RepGoalProfile.volume:
        return '3x12';
    }
  }
}

class _TrackOptionPickerView extends StatefulWidget {
  final String title;
  final List<TrainingBranchOption> options;
  final String selectedId;

  const _TrackOptionPickerView({
    required this.title,
    required this.options,
    required this.selectedId,
  });

  @override
  State<_TrackOptionPickerView> createState() => _TrackOptionPickerViewState();
}

class _TrackOptionPickerViewState extends State<_TrackOptionPickerView> {
  late String _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.selectedId;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.options.firstWhere(
      (option) => option.id == _picked,
      orElse: () => widget.options.first,
    );

    return _SettingsScreenScaffold(
      title: 'Switch Track',
      large: true,
      onBack: () => Navigator.of(context).pop(),
      trailingText: 'Save',
      onTrailingTap: () => Navigator.of(context).pop(_picked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Choose a Track'),
          _SettingsGroup(
            footer: current.rationale,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == widget.options.length - 1,
                  title: widget.options[i].title,
                  sub:
                      '${widget.options[i].exerciseIds.length} steps · ${widget.options[i].subtitle}',
                  accessory: _picked == widget.options[i].id
                      ? _RowAccessory.check
                      : _RowAccessory.none,
                  onTap: () {
                    setState(() => _picked = widget.options[i].id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSettingsView extends StatelessWidget {
  final String title;
  final String footer;
  final List<_StaticRowData> rows;

  const _InfoSettingsView({
    required this.title,
    required this.footer,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsScreenScaffold(
      title: title,
      large: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Overview'),
          _SettingsGroup(
            footer: footer,
            children: [
              for (var i = 0; i < rows.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == rows.length - 1,
                  title: rows[i].title,
                  value: rows[i].value,
                  accessory: _RowAccessory.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsScreenScaffold extends StatelessWidget {
  final String title;
  final bool large;
  final VoidCallback onBack;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SettingsScreenScaffold({
    required this.title,
    required this.onBack,
    required this.child,
    this.large = false,
    this.trailingText,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: _accent,
          ),
          onPressed: onBack,
        ),
        actions: [
          if (trailingText != null)
            TextButton(
              onPressed: onTrailingTap,
              child: Text(
                trailingText!,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: large ? 34 : 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: large ? -1.1 : -0.7,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.7,
          color: _text2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final String? footer;

  const _SettingsGroup({
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _group,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              footer!,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.45,
                color: _text2,
              ),
            ),
          ),
      ],
    );
  }
}

enum _RowAccessory { chevron, check, none }

class _SettingsRow extends StatelessWidget {
  final bool first;
  final bool last;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? sub;
  final String? value;
  final Color? titleColor;
  final _RowAccessory accessory;
  final VoidCallback? onTap;

  const _SettingsRow({
    this.first = false,
    this.last = false,
    this.icon,
    this.iconColor,
    required this.title,
    this.sub,
    this.value,
    this.titleColor,
    this.accessory = _RowAccessory.chevron,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: (iconColor ?? _text2).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 17,
                color: iconColor ?? _text2,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    letterSpacing: -0.1,
                    color: titleColor ?? _text,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      letterSpacing: -0.05,
                      color: _text2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  letterSpacing: -0.05,
                  color: _text2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (accessory == _RowAccessory.chevron && onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _text3,
            ),
          ],
          if (accessory == _RowAccessory.check) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_rounded,
              size: 18,
              color: _accent,
            ),
          ],
        ],
      ),
    );

    final row = first
        ? content
        : Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _sep, width: 0.5)),
            ),
            child: content,
          );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: row,
    );
  }
}

class _StaticRowData {
  final String title;
  final String value;

  const _StaticRowData({
    required this.title,
    required this.value,
  });
}
