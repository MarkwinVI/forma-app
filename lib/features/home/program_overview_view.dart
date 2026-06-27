import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/exercise_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import 'training_program_logic_view.dart';

const _overviewBg = Color(0xFF161618);
const _overviewCard = Color(0xFF202023);
const _overviewCardAlt = Color(0xFF2A2A2E);
const _overviewBorder = Color(0xFF323237);
const _overviewText = Color(0xFFF5F5F7);
const _overviewTextSecondary = Color(0xFF9C9CA3);
const _overviewTextTertiary = Color(0xFF6C6C73);
const _overviewOrange = Color(0xFFFC5200);
const _overviewOrangeSoft = Color(0x26FC5200);
const _overviewOrangeBright = Color(0xFFFF7E45);
const _overviewBurnt = Color(0xFFC9521E);
const _overviewGold = Color(0xFFE0A526);
const _overviewGray = Color(0xFF55555C);

class ProgramOverviewView extends StatefulWidget {
  final TrainingProgramLogicSnapshot initialLogic;
  final Map<String, ExerciseStatus> progressMap;
  final Future<TrainingProgramLogicSnapshot> Function({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
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

  @override
  void initState() {
    super.initState();
    _logic = widget.initialLogic;
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingProgramLogicView(
          initialLogic: _logic,
          progressMap: widget.progressMap,
          onSave: ({
            required programType,
            required branchSelections,
            required repGoalProfile,
            required sessionItemsConfig,
          }) async {
            final updated = await widget.onSave(
              programType: programType,
              branchSelections: branchSelections,
              repGoalProfile: repGoalProfile,
              sessionItemsConfig: sessionItemsConfig,
            );
            if (!mounted) return;
            setState(() => _logic = updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _programService.scheduleCycleFor(
      programType: _logic.program.programType,
      scheduleVariant: _logic.program.scheduleVariant,
    );
    final balanceItems = _buildTrainingBalance();

    return Scaffold(
      backgroundColor: _overviewBg,
      appBar: AppBar(
        backgroundColor: _overviewBg,
        surfaceTintColor: _overviewBg,
        elevation: 0,
        title: Text(
          'Program Overview',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _overviewText,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _openEditor,
            child: Text(
              'Edit',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _overviewOrange,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _OverviewSectionLabel('Your split'),
              const SizedBox(height: 12),
              _SplitCard(
                splitName: _logic.program.programType.label,
                cadenceLabel:
                    '${cycle.where((day) => day != TrainingSessionType.rest).length}-day',
                cycle: cycle,
              ),
              const SizedBox(height: 26),
              const _OverviewSectionLabel('Training balance'),
              const SizedBox(height: 12),
              _TrainingBalanceCard(items: balanceItems),
            ],
          ),
        ),
      ),
    );
  }

  List<_BalanceItem> _buildTrainingBalance() {
    final counts = <_BalanceBucket, int>{
      for (final bucket in _BalanceBucket.values) bucket: 0,
    };
    final sessionItemsConfig = _sessionItemsConfig();

    for (final sessionType in _programService
        .trainingDaysForProgramType(_logic.program.programType)) {
      final recommendation = _programService.buildToday(
        progressMap: widget.progressMap,
        programType: _logic.program.programType,
        sessionType: sessionType,
        branchSelections: _logic.branchSelections,
        sessionItemsConfig: sessionItemsConfig,
      );

      for (final item in recommendation.items) {
        counts[_bucketForTrack(item.track)] =
            (counts[_bucketForTrack(item.track)] ?? 0) + 1;
      }
    }

    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      return const [
        _BalanceItem(
          label: 'Pull strength',
          percent: 0,
          color: _overviewOrange,
        ),
        _BalanceItem(
          label: 'Push strength',
          percent: 0,
          color: _overviewOrangeBright,
        ),
        _BalanceItem(
          label: 'Lower body',
          percent: 0,
          color: _overviewBurnt,
        ),
        _BalanceItem(
          label: 'Core',
          percent: 0,
          color: _overviewGold,
        ),
        _BalanceItem(
          label: 'Skill control',
          percent: 0,
          color: _overviewGray,
        ),
      ];
    }

    final orderedBuckets = _BalanceBucket.values.toList();
    final percents = <_BalanceBucket, int>{};
    for (final bucket in orderedBuckets) {
      percents[bucket] = ((counts[bucket]! / total) * 100).round();
    }

    final diff =
        100 - percents.values.fold<int>(0, (sum, value) => sum + value);
    if (diff != 0) {
      final largestBucket = orderedBuckets.reduce(
        (best, next) => counts[next]! > counts[best]! ? next : best,
      );
      percents[largestBucket] = (percents[largestBucket] ?? 0) + diff;
    }

    return [
      _BalanceItem(
        label: 'Pull strength',
        percent: percents[_BalanceBucket.pull] ?? 0,
        color: _overviewOrange,
      ),
      _BalanceItem(
        label: 'Push strength',
        percent: percents[_BalanceBucket.push] ?? 0,
        color: _overviewOrangeBright,
      ),
      _BalanceItem(
        label: 'Lower body',
        percent: percents[_BalanceBucket.lower] ?? 0,
        color: _overviewBurnt,
      ),
      _BalanceItem(
        label: 'Core',
        percent: percents[_BalanceBucket.core] ?? 0,
        color: _overviewGold,
      ),
      _BalanceItem(
        label: 'Skill control',
        percent: percents[_BalanceBucket.skill] ?? 0,
        color: _overviewGray,
      ),
    ];
  }

  Map<String, dynamic> _sessionItemsConfig() {
    final raw = _logic.program.variationRules['session_items_v1'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  _BalanceBucket _bucketForTrack(TrainingTrack track) {
    switch (track) {
      case TrainingTrack.verticalPull:
      case TrainingTrack.horizontalPull:
        return _BalanceBucket.pull;
      case TrainingTrack.verticalPush:
      case TrainingTrack.horizontalPush:
        return _BalanceBucket.push;
      case TrainingTrack.squat:
      case TrainingTrack.hinge:
        return _BalanceBucket.lower;
      case TrainingTrack.core:
        return _BalanceBucket.core;
      case TrainingTrack.skillWork:
        return _BalanceBucket.skill;
    }
  }
}

enum _BalanceBucket { pull, push, lower, core, skill }

class _BalanceItem {
  final String label;
  final int percent;
  final Color color;

  const _BalanceItem({
    required this.label,
    required this.percent,
    required this.color,
  });
}

class _OverviewSectionLabel extends StatelessWidget {
  final String text;

  const _OverviewSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _overviewTextSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  final String splitName;
  final String cadenceLabel;
  final List<TrainingSessionType> cycle;

  const _SplitCard({
    required this.splitName,
    required this.cadenceLabel,
    required this.cycle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _overviewCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _overviewBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  splitName,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _overviewText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                cadenceLabel.toUpperCase(),
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _overviewTextSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0; index < cycle.length; index++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        right: index == cycle.length - 1 ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: cycle[index] == TrainingSessionType.rest
                          ? _overviewCardAlt
                          : _overviewOrangeSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cycle[index] == TrainingSessionType.rest
                            ? _overviewBorder
                            : _overviewOrange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _shortCycleLabel(cycle[index]),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cycle[index] == TrainingSessionType.rest
                              ? _overviewTextTertiary
                              : _overviewOrange,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            'Sessions repeat in order — miss one and it slots into your next training day.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: _overviewTextSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _shortCycleLabel(TrainingSessionType type) {
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

class _TrainingBalanceCard extends StatelessWidget {
  final List<_BalanceItem> items;

  const _TrainingBalanceCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _overviewCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _overviewBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final item in items)
                Expanded(
                  flex: item.percent == 0 ? 1 : item.percent,
                  child: Container(
                    height: 13,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Column(
            children: [
              for (final item in items) ...[
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _overviewText,
                        ),
                      ),
                    ),
                    Text(
                      '${item.percent}%',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _overviewText,
                      ),
                    ),
                  ],
                ),
                if (item != items.last) const SizedBox(height: 11),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
