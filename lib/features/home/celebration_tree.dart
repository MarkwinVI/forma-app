import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/skill_category_model.dart';
import '../progress/skill_wheel_data.dart';
import '../progress/widgets/skill_wheel.dart';
import 'celebration_widgets.dart';

/// The Progress tab's wheel, in the post-workout celebration: opened on
/// one tree from the first frame, every branch and step of it drawn as
/// the wheel draws them, nothing else on the wheel. It cannot be swiped or
/// tapped; the step states and the selector move with the celebration's
/// beats through [families], [selected] and [focus].
class CelebrationTree extends StatefulWidget {
  final List<WheelFamily> families;

  /// Which family is in focus — for a hand-off, the wheel spins from the
  /// old tree to the new one when this changes.
  final int selected;

  /// The exercise id the selector ring sits on.
  final String focusExerciseId;

  const CelebrationTree({
    super.key,
    required this.families,
    required this.selected,
    required this.focusExerciseId,
  });

  @override
  State<CelebrationTree> createState() => _CelebrationTreeState();
}

class _CelebrationTreeState extends State<CelebrationTree> {
  final _controller = SkillWheelController();

  int _flatIndexOf(String exerciseId) {
    final family = widget.families[widget.selected];
    final index =
        family.flat.indexWhere((node) => node.exerciseId == exerciseId);
    return index < 0 ? family.activeFlatIndex : index;
  }

  @override
  void didUpdateWidget(CelebrationTree old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected ||
        old.focusExerciseId != widget.focusExerciseId) {
      // After this frame: the wheel's own state must see the new families
      // before it flies or moves its selector.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.goTo(
            widget.selected,
            _flatIndexOf(widget.focusExerciseId),
          );
        }
      });
    }
  }

  /// The tree runs wider than the bar above it — past the column's own
  /// padding, to this much short of the screen's edge — since it is the
  /// one thing on the screen that gains from every point of width.
  static const double sideMargin = 12;

  @override
  Widget build(BuildContext context) {
    final width = math.max(
      celebrationContentWidth,
      MediaQuery.sizeOf(context).width - 2 * sideMargin,
    );
    final height = SkillWheel.focusedHeightFor(
      width: width,
      familyCount: widget.families.length,
      fitFocusedWidth: true,
    );
    // The slot is the wheel's focused height; inside it the wheel lays
    // out unbounded, so it keeps the width it is given rather than
    // narrowing to fit its opening frame into the slot.
    return SizedBox(
      height: height,
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: IgnorePointer(
            child: SkillWheel(
              families: widget.families,
              controller: _controller,
              initialSelected: widget.selected,
              initialFocus: _flatIndexOf(widget.focusExerciseId),
              hideUnfocused: true,
              fitFocusedWidth: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// A category as the celebration draws it: the route the user is on —
/// [routeIds], the trunk followed by the branch the pair sits on — with
/// everything before [masteredIndex] cleared, the mastered step itself
/// clearing on [cleared], the step after it opening then lighting on
/// [lit], and everything else still locked. At a fork, [openSiblings]
/// opens the other branches' first steps as the step clears, as the app's
/// own rule would. A tree that only receives a slot — the hand-off's new
/// tree — keeps its first step grey until it lights: [nextOpensOnClear]
/// false.
WheelFamily? celebrationFamily({
  required String categoryId,
  required List<String> routeIds,
  required int masteredIndex,
  required bool cleared,
  required bool lit,
  bool openSiblings = false,
  bool nextOpensOnClear = true,
}) {
  final category = SkillCategoryCatalog.findById(categoryId);
  if (category == null) return null;

  final foundation = category.pathFor(category.foundationBranchId);
  final siblingFirsts = <String>{
    for (final branch in category.branches)
      if (!SkillCategory.isFoundationBranchId(branch.id))
        if (category.pathFor(branch.id) case final path
            when path.length > foundation.length)
          path[foundation.length],
  };

  WheelNodeState stateOf(String id) {
    final index = routeIds.indexOf(id);
    if (index >= 0) {
      if (index < masteredIndex) return WheelNodeState.mastered;
      if (index == masteredIndex) {
        return cleared ? WheelNodeState.mastered : WheelNodeState.active;
      }
      if (index == masteredIndex + 1) {
        if (lit) return WheelNodeState.active;
        return cleared && nextOpensOnClear
            ? WheelNodeState.available
            : WheelNodeState.locked;
      }
      return WheelNodeState.locked;
    }
    if (openSiblings && cleared && siblingFirsts.contains(id)) {
      return WheelNodeState.available;
    }
    return WheelNodeState.locked;
  }

  return wheelFamilyFor(category, stateOf);
}
