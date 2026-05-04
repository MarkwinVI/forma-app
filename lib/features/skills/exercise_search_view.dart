import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import 'skill_tree_view.dart';

const _masteredColor = Color(0xFF00FF8C);
const _inactiveColor = Color(0xFF52525C);

class ExerciseSearchView extends StatefulWidget {
  final Map<String, ExerciseStatus> progressMap;
  final void Function(String id, ExerciseStatus status) onProgressChanged;

  const ExerciseSearchView({
    super.key,
    required this.progressMap,
    required this.onProgressChanged,
  });

  @override
  State<ExerciseSearchView> createState() => _ExerciseSearchViewState();
}

class _ExerciseSearchViewState extends State<ExerciseSearchView> {
  final _controller = TextEditingController();
  List<Exercise> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _controller.text.toLowerCase();
    setState(() {
      _results = q.isEmpty
          ? []
          : ExerciseCatalog.browsable()
              .where((e) => e.name.toLowerCase().contains(q))
              .toList();
    });
  }

  ExerciseStatus _statusFor(String id) =>
      widget.progressMap[id] ?? ExerciseStatus.inactive;

  Color _dotColor(ExerciseStatus s) {
    switch (s) {
      case ExerciseStatus.mastered:
        return _masteredColor;
      case ExerciseStatus.active:
        return AppColors.accentPrimary;
      case ExerciseStatus.inactive:
        return _inactiveColor;
    }
  }

  String _statusLabel(ExerciseStatus s) {
    switch (s) {
      case ExerciseStatus.mastered:
        return 'Mastered';
      case ExerciseStatus.active:
        return 'Active';
      case ExerciseStatus.inactive:
        return 'Inactive';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar + Cancel ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        border: Border.all(color: AppColors.borderPrimary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.search,
                                color: AppColors.textMuted, size: 16),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search exercises...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                  letterSpacing: -0.15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: AppColors.accentPrimary,
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          if (hasQuery)
                            GestureDetector(
                              onTap: () => _controller.clear(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.close,
                                    color: AppColors.textMuted, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Cancel button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results ─────────────────────────────────────────────────────
            Expanded(
              child: !hasQuery
                  ? const SizedBox.shrink()
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'No exercises found',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.borderPrimary,
                          ),
                          itemBuilder: (context, i) {
                            final exercise = _results[i];
                            final status = _statusFor(exercise.id);
                            final dotColor = _dotColor(status);

                            return _ExerciseResultRow(
                              exercise: exercise,
                              dotColor: dotColor,
                              statusLabel: _statusLabel(status),
                              statusLabelColor: dotColor,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SkillTreeView(
                                      skillCategoryId: ExerciseCatalog
                                          .skillCategoryIdForExercise(
                                        exercise,
                                      ),
                                      progressMap: widget.progressMap,
                                      onProgressChanged:
                                          widget.onProgressChanged,
                                    ),
                                  ),
                                );
                                setState(() {});
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseResultRow extends StatelessWidget {
  final Exercise exercise;
  final Color dotColor;
  final String statusLabel;
  final Color statusLabelColor;
  final VoidCallback onTap;

  const _ExerciseResultRow({
    required this.exercise,
    required this.dotColor,
    required this.statusLabel,
    required this.statusLabelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skillCategory = SkillCategoryCatalog.findById(
      ExerciseCatalog.skillCategoryIdForExercise(exercise),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        skillCategory == null
                            ? exercise.category.label
                            : '${skillCategory.title} · ${skillCategory.subtitle}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusLabelColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right,
                    color: _inactiveColor,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
