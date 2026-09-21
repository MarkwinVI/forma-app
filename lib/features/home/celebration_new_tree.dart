import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import 'celebration_tree.dart';
import 'celebration_widgets.dart';

/// The post-workout step for a hand-off: mastering the last shared step of
/// one tree moved the slot to a *different* tree (dips → handstand push-up).
/// Same one-screen beat structure as the fork step, on the Progress tab's
/// wheel: one tree visible at a time, the next one waiting on the spoke
/// below. Beats: bar fills → the step pops green and the old tree's branch
/// firsts open → the wheel spins to the new tree, which sits locked → the
/// padlock pops off → its first step lights and the title swaps → helper.

class NewTreeUnlockData {
  final Exercise mastered;
  final Exercise newExercise;
  final int masterySets;
  final int masteryValue;
  final int startSets;
  final int startValue;

  /// The tree that handed over: its title, the trunk up to the mastered
  /// step, and the branches it would have forked into.
  final String fromTitle;
  final String fromCategoryId;
  final List<String> fromRouteIds;
  final List<String> fromFoundationNames;
  final List<String> fromBranchLabels;

  /// The tree that took the slot: its title and opening steps, with the
  /// index of the one that starts training.
  final String toTitle;
  final String toCategoryId;
  final List<String> toRouteIds;
  final List<String> toNodeNames;
  final int toActiveIndex;

  const NewTreeUnlockData({
    required this.mastered,
    required this.newExercise,
    required this.masterySets,
    required this.masteryValue,
    required this.startSets,
    required this.startValue,
    required this.fromTitle,
    required this.fromCategoryId,
    required this.fromRouteIds,
    required this.fromFoundationNames,
    required this.fromBranchLabels,
    required this.toTitle,
    required this.toCategoryId,
    required this.toRouteIds,
    required this.toNodeNames,
    required this.toActiveIndex,
  });

  /// The old tree as a noun for "your dip progression": its title, lower
  /// case and singular.
  String get fromNoun {
    final lower = fromTitle.toLowerCase();
    return lower.endsWith('s') ? lower.substring(0, lower.length - 1) : lower;
  }
}

/// The hand-off behind an activation, or null when the new exercise is in
/// the mastered one's own tree — a fork or an ordinary next step.
NewTreeUnlockData? resolveNewTreeUnlock({
  required Exercise mastered,
  required Exercise newExercise,
  required int masterySets,
  required int masteryValue,
  required int startSets,
  required int startValue,
}) {
  if (mastered.skillCategoryId.isEmpty ||
      newExercise.skillCategoryId.isEmpty ||
      mastered.skillCategoryId == newExercise.skillCategoryId) {
    return null;
  }
  final from = SkillCategoryCatalog.findById(mastered.skillCategoryId);
  final to = SkillCategoryCatalog.findById(newExercise.skillCategoryId);
  if (from == null || to == null) return null;

  String nameOf(String id) => ExerciseCatalog.findById(id)?.name ?? id;

  // The trunk: any path through the mastered step, up to it.
  List<String> foundation = const [];
  final branchByNext = <String, String>{};
  for (final entry in from.trainingPaths.entries) {
    final path = entry.value;
    final index = path.indexOf(mastered.id);
    if (index < 0) continue;
    if (foundation.isEmpty) foundation = path.sublist(0, index + 1);
    if (index + 1 < path.length &&
        !SkillCategory.isFoundationBranchId(entry.key)) {
      branchByNext.putIfAbsent(
        path[index + 1],
        () => _branchLabel(from, entry.key),
      );
    }
  }
  if (foundation.isEmpty) return null;

  // The new tree's opening: its first steps, and where the new exercise
  // sits among them — normally the very first.
  List<String> opening = const [];
  List<String> toRoute = const [];
  var toActive = 0;
  for (final path in to.trainingPaths.values) {
    final index = path.indexOf(newExercise.id);
    if (index < 0) continue;
    final start = math.max(0, math.min(index, path.length - 3));
    opening = path.sublist(start, math.min(path.length, start + 3));
    toRoute = path;
    toActive = index;
    break;
  }
  if (opening.isEmpty) return null;

  return NewTreeUnlockData(
    mastered: mastered,
    newExercise: newExercise,
    masterySets: masterySets,
    masteryValue: masteryValue,
    startSets: startSets,
    startValue: startValue,
    fromTitle: from.title,
    fromCategoryId: from.id,
    fromRouteIds: foundation,
    fromFoundationNames: [for (final id in foundation) nameOf(id)],
    fromBranchLabels: branchByNext.values.take(3).toList(),
    toTitle: to.title,
    toCategoryId: to.id,
    toRouteIds: toRoute,
    toNodeNames: [for (final id in opening) nameOf(id)],
    toActiveIndex: toActive,
  );
}

String _branchLabel(SkillCategory category, String branchId) {
  for (final branch in category.branches) {
    if (branch.id == branchId) return branch.label;
  }
  return branchId;
}

class NewTreeUnlockContent extends StatefulWidget {
  final NewTreeUnlockData data;

  const NewTreeUnlockContent({super.key, required this.data});

  @override
  State<NewTreeUnlockContent> createState() => _NewTreeUnlockContentState();
}

class _NewTreeUnlockContentState extends State<NewTreeUnlockContent> {
  /// 0 bar filling · 1 step cleared, the old tree's branch firsts open ·
  /// 2 the wheel spins to the new tree · 3 the tree unlocks and its first
  /// step lights · 4 helper. The screen ends on the tree, not the step.
  int _phase = 0;
  bool _fill = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    void at(int ms, VoidCallback fn) {
      _timers.add(Timer(Duration(milliseconds: ms), () {
        if (mounted) setState(fn);
      }));
    }

    at(600, () => _fill = true);
    at(2100, () => _phase = 1);
    at(3200, () => _phase = 2);
    at(4100, () => _phase = 3);
    at(5000, () => _phase = 4);
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final unlocked = _phase >= 3;
    final done = _phase >= 4;
    final title = _phase >= 2 ? data.toTitle : data.mastered.name;
    final target = '${data.masterySets} × ${data.masteryValue}'
        '${data.mastered.isTimed ? 's' : ''}';
    final Widget? tag = unlocked
        ? const CelebrationTag(
            key: ValueKey('tree'),
            color: AppColors.amber,
            label: 'New skill tree unlocked',
          )
        : _phase >= 1
            ? const CelebrationTag(
                key: ValueKey('mastered'),
                color: AppColors.green,
                label: 'Exercise mastered',
              )
            : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: tag ?? const SizedBox.shrink(key: ValueKey('none')),
              ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                title,
                key: ValueKey(title),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            RiseIn(
              delay: const Duration(milliseconds: 80),
              // The bar steps back once the wheel turns: it is about the
              // step just cleared, and the screen is about the new tree.
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _phase >= 2 ? 0.35 : 1,
                child: CelebrationTargetBar(
                  label: 'PREREQUISITE',
                  target: target,
                  targetColor: AppColors.green,
                  fill: _fill,
                ),
              ),
            ),
            const SizedBox(height: 12),
            RiseIn(
              delay: const Duration(milliseconds: 140),
              child: CelebrationTree(
                families: [
                  celebrationFamily(
                    categoryId: data.fromCategoryId,
                    routeIds: data.fromRouteIds,
                    masteredIndex: data.fromRouteIds.length - 1,
                    cleared: _phase >= 1,
                    lit: false,
                    openSiblings: true,
                  )!,
                  // The new tree: whatever was earned on it before stays
                  // green, its first step waits grey until it lights.
                  celebrationFamily(
                    categoryId: data.toCategoryId,
                    routeIds: data.toRouteIds,
                    masteredIndex: data.toActiveIndex - 1,
                    cleared: true,
                    lit: unlocked,
                    nextOpensOnClear: false,
                  )!,
                ],
                selected: _phase >= 2 ? 1 : 0,
                focusExerciseId:
                    _phase >= 2 ? data.newExercise.id : data.mastered.id,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: done ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(0.32, 0.72, 0, 1),
                offset: done ? Offset.zero : const Offset(0, 0.3),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: celebrationContentWidth),
                  child: Text(
                    '${data.toTitle} replaced your ${data.fromNoun} '
                    'progression. Prefer to keep training '
                    '${data.fromTitle.toLowerCase()}? Change it on the '
                    'Program tab.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
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
