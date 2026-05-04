import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
import 'exercise_search_view.dart';
import 'skill_tree_view.dart';
import 'widgets/category_progress_card.dart';

class SkillsView extends StatefulWidget {
  const SkillsView({super.key});

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  final _progressService = ProgressService();
  Map<String, ExerciseStatus> _progressMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    try {
      final progress = await _progressService.fetchAll(userId);
      setState(() {
        _progressMap = {for (final p in progress) p.exerciseId: p.status};
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int _masteredCount(SkillCategory category) {
    return ExerciseCatalog.forSkillCategory(category.id)
        .where((e) => _progressMap[e.id] == ExerciseStatus.mastered)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final categories = SkillCategoryCatalog.browsable();

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Skills',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // ── Search bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 150),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 150),
                      pageBuilder: (_, __, ___) => ExerciseSearchView(
                        progressMap: _progressMap,
                        onProgressChanged: (id, status) =>
                            setState(() => _progressMap[id] = status),
                      ),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  ),
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
                        Text(
                          'Search exercises...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textMuted,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CategoryProgressCard(
                          category: category,
                          mastered: _masteredCount(category),
                          total: ExerciseCatalog.totalForSkillCategory(
                            category.id,
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SkillTreeView(
                                  skillCategoryId: category.id,
                                  progressMap: _progressMap,
                                  onProgressChanged: (id, status) {
                                    setState(() => _progressMap[id] = status);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
