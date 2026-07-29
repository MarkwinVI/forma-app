import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../home/program_day_items.dart';
import 'exercise_detail_view.dart';

/// Full-screen exercise search. Every exercise is a step of a skill tree, so
/// results lead with the steps that continue a path the user is already on,
/// and filtering is by movement pattern and the muscles that pattern trains.
///
/// Pops the picked exercises, or null when cancelled. In browse mode nothing
/// is picked at all: it is the same page reading as a library, so the search
/// and filters people learn while building a day are the ones they get when
/// they just want to look something up.
class ExercisePickerView extends StatefulWidget {
  /// Exercises already in the day — nothing to add, so they are left out.
  final Set<String> excludedIds;
  final Map<String, ExerciseStatus> progressMap;

  /// Replacing takes the first tap and returns; adding accumulates picks.
  final bool singlePick;

  /// Reading rather than picking: a tap opens the exercise's own page, the
  /// whole catalogue is shown, and nothing is returned.
  final bool browsing;

  const ExercisePickerView({
    super.key,
    required this.excludedIds,
    required this.progressMap,
    this.singlePick = false,
  }) : browsing = false;

  const ExercisePickerView.browse({super.key})
      : excludedIds = const {},
        progressMap = const {},
        singlePick = false,
        browsing = true;

  @override
  State<ExercisePickerView> createState() => ExercisePickerViewState();
}

class ExercisePickerViewState extends State<ExercisePickerView> {
  final _searchController = TextEditingController();

  String _query = '';
  Set<ExerciseCategory> _patterns = {};
  Set<String> _muscles = {};
  final List<Exercise> _picked = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lowercase and drop separators so "pullup" matches "Pull-Up" / "Pull Up".
  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<Exercise> get _matches {
    final tokens = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(_normalize)
        .where((token) => token.isNotEmpty)
        .toList();

    final matches = ExerciseCatalog.everything().where((exercise) {
      if (widget.excludedIds.contains(exercise.id)) return false;
      if (_isLocked(exercise)) return false;
      if (_patterns.isNotEmpty && !_patterns.contains(exercise.category)) {
        return false;
      }
      if (_muscles.isNotEmpty &&
          !ProgramSessionPlan.musclesForExercise(exercise)
              .any(_muscles.contains)) {
        return false;
      }
      if (tokens.isEmpty) return true;
      final haystack = _normalize(
        '${exercise.name} ${programPatternLabel(exercise.category)}',
      );
      return tokens.every(haystack.contains);
    }).toList();

    final queryNorm = _normalize(_query);
    int rank(Exercise exercise) =>
        queryNorm.isNotEmpty && _normalize(exercise.name).startsWith(queryNorm)
            ? 0
            : 1;
    matches.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.name.compareTo(b.name);
    });
    return matches;
  }

  /// Exercises of a tree that is still behind its unlock requirement are not
  /// offered — a handstand pushup cannot be picked before the pushup
  /// foundation is finished. Browsing hides nothing: reading about a move you
  /// have not earned yet is the point of a library.
  bool _isLocked(Exercise exercise) {
    if (widget.browsing) return false;
    if (exercise.skillCategoryId.isEmpty) return false;
    final category = SkillCategoryCatalog.findById(exercise.skillCategoryId);
    return category?.isLockedFor(widget.progressMap) ?? false;
  }

  /// The step a tree is currently sitting on — adding it resumes that path.
  bool _continuesAPath(Exercise exercise) =>
      widget.progressMap[exercise.id] == ExerciseStatus.active;

  void _toggle(Exercise exercise) {
    if (widget.browsing) {
      openExerciseDetailView<void>(context, exercise: exercise);
      return;
    }
    if (widget.singlePick) {
      Navigator.of(context).pop([exercise]);
      return;
    }
    setState(() {
      final index = _picked.indexWhere((entry) => entry.id == exercise.id);
      if (index >= 0) {
        _picked.removeAt(index);
      } else {
        _picked.add(exercise);
      }
    });
  }

  Future<void> _openPatternFilter() async {
    final picked = await showModalBottomSheet<Set<ExerciseCategory>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _FilterSheet<ExerciseCategory>(
        title: 'Movement pattern',
        sub: widget.browsing
            ? 'Narrow the catalogue to one kind of movement'
            : 'Narrow the catalogue to what this day needs',
        options: [
          for (final category in ExerciseCategory.values)
            (value: category, label: programPatternLabel(category)),
        ],
        selected: _patterns,
        resultCount: (selection) => _countFor(patterns: selection),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _patterns = picked);
  }

  Future<void> _openMuscleFilter() async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _FilterSheet<String>(
        title: 'Muscle group',
        sub: 'Filter by what the exercise trains',
        options: [
          for (final group in kProgramMuscleGroups)
            (value: group, label: group),
        ],
        selected: _muscles,
        resultCount: (selection) => _countFor(muscles: selection),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _muscles = picked);
  }

  /// Live result count for a filter sheet's pending selection.
  int _countFor({
    Set<ExerciseCategory>? patterns,
    Set<String>? muscles,
  }) {
    final byPattern = patterns ?? _patterns;
    final byMuscle = muscles ?? _muscles;
    return ExerciseCatalog.everything().where((exercise) {
      if (widget.excludedIds.contains(exercise.id)) return false;
      if (_isLocked(exercise)) return false;
      if (byPattern.isNotEmpty && !byPattern.contains(exercise.category)) {
        return false;
      }
      if (byMuscle.isNotEmpty &&
          !ProgramSessionPlan.musclesForExercise(exercise)
              .any(byMuscle.contains)) {
        return false;
      }
      return true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final resumes = matches.where(_continuesAPath).toList();
    final rest = matches.where((e) => !_continuesAPath(e)).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: widget.browsing
                            ? const Padding(
                                padding: EdgeInsets.only(left: 3),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 26,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.browsing ? 'All exercises' : 'Add exercise',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.9,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChip(
                              label: _patterns.isEmpty
                                  ? 'All patterns'
                                  : '${_patterns.length} pattern'
                                      '${_patterns.length > 1 ? 's' : ''}',
                              active: _patterns.isNotEmpty,
                              onTap: _openPatternFilter,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterChip(
                              label: _muscles.isEmpty
                                  ? 'All muscles'
                                  : '${_muscles.length} muscle'
                                      '${_muscles.length > 1 ? 's' : ''}',
                              active: _muscles.isNotEmpty,
                              onTap: _openMuscleFilter,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: matches.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(22, 36, 22, 0),
                          child: Text(
                            _query.trim().isEmpty
                                ? 'Nothing matches these filters. Clear one to '
                                    'see more of the catalogue.'
                                : 'Nothing matches “${_query.trim()}”. Try a '
                                    'movement pattern — rows, dips, handstand.',
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            22,
                            0,
                            22,
                            _picked.isEmpty ? 40 : 130,
                          ),
                          children: [
                            if (resumes.isNotEmpty) ...[
                              const _ResultsHeader(
                                'Continues a path you’re on',
                              ),
                              for (final exercise in resumes)
                                _ExerciseResultRow(
                                  exercise: exercise,
                                  added: _picked.any(
                                    (entry) => entry.id == exercise.id,
                                  ),
                                  browsing: widget.browsing,
                                  onTap: () => _toggle(exercise),
                                ),
                            ],
                            if (rest.isNotEmpty) ...[
                              _ResultsHeader(
                                resumes.isEmpty
                                    ? 'All exercises'
                                    : 'Everything else',
                              ),
                              for (final exercise in rest)
                                _ExerciseResultRow(
                                  exercise: exercise,
                                  added: _picked.any(
                                    (entry) => entry.id == exercise.id,
                                  ),
                                  browsing: widget.browsing,
                                  onTap: () => _toggle(exercise),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
            if (_picked.isNotEmpty)
              Positioned(
                left: 22,
                right: 22,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x73000000),
                        offset: Offset(0, 10),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: PillButton(
                    label: 'Add ${_picked.length} exercise'
                        '${_picked.length > 1 ? 's' : ''}',
                    onTap: () => Navigator.of(context).pop(List.of(_picked)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.15,
              ),
              cursorColor: AppColors.accentPrimary,
              decoration: const InputDecoration(
                hintText: 'Search exercises and patterns',
                hintStyle: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            Pressable(
              onTap: onClear,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentSoft
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active
                ? AppColors.accentPrimary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                  letterSpacing: -0.15,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? AppColors.accentPrimary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final String label;

  const _ResultsHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.65,
        ),
      ),
    );
  }
}

class _ExerciseResultRow extends StatelessWidget {
  final Exercise exercise;
  final bool added;

  /// Browsing leads into the exercise instead of adding it, so the row ends
  /// in a chevron rather than a plus.
  final bool browsing;
  final VoidCallback onTap;

  const _ExerciseResultRow({
    required this.exercise,
    required this.added,
    required this.browsing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscles = ProgramSessionPlan.musclesForCategory(exercise.category);
    final subtitle = [
      programPatternLabel(exercise.category),
      if (muscles.isNotEmpty) muscles.join(', '),
    ].join(' · ');

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 14, bottom: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.25,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (browsing)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              )
            else
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: added
                      ? AppColors.green
                      : Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  added ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: added ? AppColors.bg : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Two-column filter picker shared by the pattern and muscle chips. Each
/// option carries how much of the catalogue it covers; the primary button
/// shows how many results the pending selection leaves.
class _FilterSheet<T> extends StatefulWidget {
  final String title;
  final String sub;
  final List<({T value, String label})> options;
  final Set<T> selected;
  final int Function(Set<T> selection) resultCount;

  const _FilterSheet({
    required this.title,
    required this.sub,
    required this.options,
    required this.selected,
    required this.resultCount,
  });

  @override
  State<_FilterSheet<T>> createState() => _FilterSheetState<T>();
}

class _FilterSheetState<T> extends State<_FilterSheet<T>> {
  late Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.resultCount(_selected);

    return SheetShell(
      title: widget.title,
      sub: widget.sub,
      footer: Row(
        children: [
          Expanded(
            flex: 10,
            child: PillButton(
              label: 'Clear filters',
              tonal: true,
              onTap: _selected.isEmpty ? null : () => setState(_selected.clear),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 13,
            child: PillButton(
              label: 'Show $count result${count == 1 ? '' : 's'}',
              onTap: () => Navigator.of(context).pop(_selected),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final option in widget.options)
              SizedBox(
                width: (MediaQuery.of(context).size.width - 32 - 9) / 2,
                child: _FilterOption(
                  label: option.label,
                  selected: _selected.contains(option.value),
                  onTap: () => setState(() {
                    if (!_selected.remove(option.value)) {
                      _selected.add(option.value);
                    }
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? AppColors.accentPrimary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}
