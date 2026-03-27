import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/exercise_progress_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/progress_service.dart';
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

  int _masteredCount(ExerciseCategory category) {
    return ExerciseCatalog.forCategory(category)
        .where((e) => _progressMap[e.id] == ExerciseStatus.mastered)
        .length;
  }

  @override
  Widget build(BuildContext context) {
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
                      final category = ExerciseCategory.values[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CategoryProgressCard(
                          category: category,
                          mastered: _masteredCount(category),
                          total: ExerciseCatalog.totalForCategory(category),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SkillTreeView(
                                  category: category,
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
                    childCount: ExerciseCategory.values.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
