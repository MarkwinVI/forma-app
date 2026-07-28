import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/training_program_store_service.dart';
import '../data/data_view.dart';
import '../home/home_view.dart';
import '../program/program_view.dart';
import '../progress/progress_view.dart';

const _progressTab = 0;
const _trainTab = 1;
const _programTab = 2;
const _profileTab = 3;

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  /// Null until the landing tab is known. Picking it after the first frame
  /// would show one tab and then jump to another, so the shell waits.
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _resolveLandingTab();
  }

  /// Without a program every other tab is an empty state pointing at the
  /// Program tab, so the app opens there rather than making the user follow
  /// the signpost. Anything that goes wrong lands on Progress, the normal
  /// home — a failed lookup should not strand people in setup.
  Future<void> _resolveLandingTab() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _currentIndex = _progressTab);
      return;
    }

    var landing = _progressTab;
    try {
      final logic =
          await TrainingProgramStoreService().fetchProgramLogic(userId);
      if (logic == null) landing = _programTab;
    } catch (error, stackTrace) {
      debugPrint('Failed to resolve the landing tab: $error\n$stackTrace');
    }
    if (mounted) setState(() => _currentIndex = landing);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    if (currentIndex == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: LoadingIndicator()),
      );
    }

    final pages = [
      ProgressView(
        isActive: currentIndex == _progressTab,
        onGoToProgram: () => setState(() => _currentIndex = _programTab),
      ),
      HomeView(
        isActive: currentIndex == _trainTab,
        onGoToProgram: () => setState(() => _currentIndex = _programTab),
      ),
      ProgramView(isActive: currentIndex == _programTab),
      DataView(isActive: currentIndex == _profileTab),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
