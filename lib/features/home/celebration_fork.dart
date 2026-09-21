import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import 'celebration_tree.dart';
import 'celebration_widgets.dart';

/// The post-workout step for any unlock inside a tree, drawn as the tree:
/// the shared foundation as a trunk, every branch forking off its end, and
/// the mastered step wherever it sits. One screen, five beats — bar fills →
/// the step clears → hold → the title swaps to the new step and its node
/// lights → a helper. At the fork itself the branch the program is on
/// lights up and the helper says where to change it; nothing is asked.

/// One branch growing out of the foundation, as the mini-map draws it.
class ForkBranch {
  final String id;
  final String label;

  /// The branch's steps past the fork. The branch the user is on carries
  /// all of them; the others carry the two the map has room to show.
  final List<String> nodeNames;

  const ForkBranch({
    required this.id,
    required this.label,
    required this.nodeNames,
  });
}

/// An unlock inside a tree, drawn as the tree: the shared foundation as a
/// trunk, every branch forking off its end, and the step just mastered
/// wherever it sits — in the trunk, at the fork, or up a branch.
/// What happened inside the tree: a step mastered and the next unlocked,
/// a manual jump to a later step, or a mastery at the end of a path with
/// nothing left to unlock.
enum TreeUnlockKind { unlock, jump, end }

class ForkUnlockData {
  final TreeUnlockKind kind;
  final Exercise mastered;

  /// The step that starts training — null at the end of a path.
  final Exercise? newExercise;
  final int masterySets;
  final int masteryValue;
  final int startSets;
  final int startValue;
  final String treeTitle;
  final String categoryId;

  /// The route the pair sits on, as exercise ids: the trunk, then the
  /// chosen branch's steps — the trunk alone while no branch is chosen.
  final List<String> routeIds;

  /// The whole shared trunk, first step to the fork.
  final List<String> foundationNames;

  /// Every branch that grows out of the trunk, in catalog order. Empty for
  /// a tree that is one straight path.
  final List<ForkBranch> branches;

  /// The branch the mastered and new steps sit on, when only one does —
  /// null while both are still in the trunk, where no branch is chosen.
  final String? chosenBranchId;

  /// Where the mastered step sits along the route: the trunk, then the
  /// chosen branch's steps.
  final int masteredIndex;

  const ForkUnlockData({
    this.kind = TreeUnlockKind.unlock,
    required this.mastered,
    required this.newExercise,
    required this.masterySets,
    required this.masteryValue,
    required this.startSets,
    required this.startValue,
    required this.treeTitle,
    required this.categoryId,
    required this.routeIds,
    required this.foundationNames,
    required this.branches,
    required this.chosenBranchId,
    required this.masteredIndex,
  });

  ForkBranch? get chosen {
    for (final branch in branches) {
      if (branch.id == chosenBranchId) return branch;
    }
    return null;
  }

  /// The mastered step ended the trunk and the new one opened a branch,
  /// with others to choose from: the moment the tree actually splits.
  bool get isFork =>
      kind == TreeUnlockKind.unlock &&
      masteredIndex == foundationNames.length - 1 &&
      chosen != null &&
      branches.length >= 2;

  /// The route the map lights along: the trunk, then the chosen branch.
  List<String> get routeNames => [
        ...foundationNames,
        ...?chosen?.nodeNames,
      ];
}

/// The tree behind an in-tree event, or null when it is not one: for an
/// unlock the new exercise must follow the mastered one on a path of its
/// tree; for a jump it must come later on one; at the end of a path there
/// is no new exercise at all. A hand-off to another tree is drawn
/// elsewhere.
ForkUnlockData? resolveForkUnlock({
  required Exercise mastered,
  required Exercise? newExercise,
  required int masterySets,
  required int masteryValue,
  required int startSets,
  required int startValue,
  TreeUnlockKind kind = TreeUnlockKind.unlock,
}) {
  if (mastered.skillCategoryId.isEmpty) return null;
  if (kind == TreeUnlockKind.end) {
    if (newExercise != null) return null;
  } else if (newExercise == null ||
      mastered.skillCategoryId != newExercise.skillCategoryId) {
    return null;
  }
  final category = SkillCategoryCatalog.findById(mastered.skillCategoryId);
  if (category == null) return null;

  // The paths the event sits on: both steps in order (adjacent for an
  // unlock), or just the mastered one at the end of a path.
  final onPaths = <String>[];
  for (final entry in category.trainingPaths.entries) {
    final path = entry.value;
    final at = path.indexOf(mastered.id);
    if (at < 0) continue;
    switch (kind) {
      case TreeUnlockKind.unlock:
        if (at + 1 < path.length && path[at + 1] == newExercise!.id) {
          onPaths.add(entry.key);
        }
      case TreeUnlockKind.jump:
        if (path.indexOf(newExercise!.id) > at) onPaths.add(entry.key);
      case TreeUnlockKind.end:
        if (at == path.length - 1) onPaths.add(entry.key);
    }
  }
  if (onPaths.isEmpty) return null;

  // A tree whose branches share no opening steps (Core) has an empty
  // trunk: every branch is its own route from step one.
  final foundation = category.pathFor(category.foundationBranchId);
  String nameOf(String id) => ExerciseCatalog.findById(id)?.name ?? id;

  // One branch per distinct first step past the trunk. Two paths that
  // open with the same exercise are one route on the map; the one the
  // event sits on keeps the name.
  final chosenId = onPaths.length == 1 ? onPaths.first : null;
  final byFirstStep = <String, ForkBranch>{};
  for (final entry in category.trainingPaths.entries) {
    final path = entry.value;
    if (path.length <= foundation.length ||
        !listEquals(path.sublist(0, foundation.length), foundation)) {
      continue;
    }
    final rest = path.sublist(foundation.length);
    if (byFirstStep.containsKey(rest.first) && entry.key != chosenId) {
      continue;
    }
    final shown = entry.key == chosenId ? rest : rest.take(2).toList();
    byFirstStep[rest.first] = ForkBranch(
      id: entry.key,
      label: _branchLabel(category, entry.key),
      nodeNames: [for (final id in shown) nameOf(id)],
    );
  }
  final branches = byFirstStep.values.toList();
  if (branches.isEmpty && foundation.isEmpty) return null;

  final routeIds = [
    ...foundation,
    if (chosenId != null)
      ...category.trainingPaths[chosenId]!.sublist(foundation.length),
  ];
  // Where the route's cleared part ends: the mastered step, or — on a
  // jump, whose steps in between the shortcut rule proves along the way —
  // the step before the one landed on.
  final anchor = kind == TreeUnlockKind.jump ? newExercise!.id : mastered.id;
  var masteredIndex = routeIds.indexOf(anchor);
  if (masteredIndex < 0) return null;
  if (kind == TreeUnlockKind.jump) masteredIndex -= 1;

  return ForkUnlockData(
    kind: kind,
    mastered: mastered,
    newExercise: newExercise,
    masterySets: masterySets,
    masteryValue: masteryValue,
    startSets: startSets,
    startValue: startValue,
    treeTitle: category.title,
    categoryId: category.id,
    routeIds: routeIds,
    foundationNames: [for (final id in foundation) nameOf(id)],
    branches: branches,
    chosenBranchId: chosenId,
    masteredIndex: masteredIndex,
  );
}

String _branchLabel(SkillCategory category, String branchId) {
  for (final branch in category.branches) {
    if (branch.id == branchId) return branch.label;
  }
  return branchId;
}

/// One screen, five beats: bar fills → foundation cleared (hold) → branch
/// lines draw → title and tag swap to the new exercise, its node lights →
/// helper. The path is changeable on the Program tab, so nothing is asked.
class ForkUnlockContent extends StatefulWidget {
  final ForkUnlockData data;

  const ForkUnlockContent({super.key, required this.data});

  @override
  State<ForkUnlockContent> createState() => _ForkUnlockContentState();
}

class _ForkUnlockContentState extends State<ForkUnlockContent> {
  /// 0 bar filling · 1 foundation cleared, branch firsts open · 2 hold ·
  /// 3 the chosen branch lights, title swaps · 4 helper.
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
    if (widget.data.kind == TreeUnlockKind.end) {
      // Nothing starts: the mastery holds, then the helper.
      at(3100, () => _phase = 4);
      return;
    }
    at(3000, () => _phase = 2);
    at(3600, () {
      _phase = 3;
      _fill = false;
    });
    at(4600, () => _phase = 4);
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
    final kind = data.kind;
    final next = data.newExercise;
    final started = _phase >= 3 && next != null;
    final done = _phase >= 4;
    final title = started ? next.name : data.mastered.name;
    // The volume that mastered it: sets × target, in the step's own unit.
    final total = data.masterySets * data.masteryValue;
    final unit = data.mastered.isTimed ? 'seconds' : 'reps';
    final helper = switch (kind) {
      TreeUnlockKind.unlock =>
        'Completing $total $unit of ${data.mastered.name} '
            'unlocked ${next!.name}.'
            '${data.isFork ? '\nYou’re on the ${data.chosen!.label} path. '
                'Change it anytime on the Program tab.' : ''}',
      TreeUnlockKind.jump =>
        'Your logged result moves your active exercise to ${next!.name}.',
      TreeUnlockKind.end =>
        'Completing $total $unit of ${data.mastered.name} mastered it. '
            'That was the last step of this path.',
    };
    final target = started
        ? '${data.startSets} × ${data.startValue}'
            '${next.isTimed ? 's' : ''}'
        : '${data.masterySets} × ${data.masteryValue}'
            '${data.mastered.isTimed ? 's' : ''}';
    final Widget? tag = started
        ? CelebrationTag(
            key: const ValueKey('started'),
            color: AppColors.accentPrimary,
            label: kind == TreeUnlockKind.jump
                ? 'Exercise changed'
                : 'New exercise started',
          )
        : _phase >= 1
            ? kind == TreeUnlockKind.jump
                ? const CelebrationTag(
                    key: ValueKey('changed'),
                    color: AppColors.accentPrimary,
                    label: 'Exercise changed',
                  )
                : const CelebrationTag(
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
            // The tag's slot keeps its height from the first frame so the
            // title never jumps when the tag arrives.
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
              child: CelebrationTargetBar(
                label: started
                    ? 'STARTING TARGET'
                    : kind == TreeUnlockKind.jump
                        ? 'CURRENT TARGET'
                        : 'PREREQUISITE',
                target: target,
                targetColor:
                    started ? AppColors.textSecondary : AppColors.green,
                fill: _fill,
              ),
            ),
            const SizedBox(height: 16),
            RiseIn(
              delay: const Duration(milliseconds: 140),
              child: CelebrationTree(
                families: [
                  celebrationFamily(
                    categoryId: data.categoryId,
                    routeIds: data.routeIds,
                    masteredIndex: data.masteredIndex,
                    // A jump's route is already cleared up to the landing
                    // step: the shortcut rule proved what it passed over.
                    cleared: _phase >= 1 || kind == TreeUnlockKind.jump,
                    lit: started,
                    openSiblings: data.isFork,
                  )!,
                ],
                selected: 0,
                focusExerciseId: started ? next.id : data.mastered.id,
              ),
            ),
            const SizedBox(height: 16),
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
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      helper,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
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
