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

  /// One scroll controller per tab, handed down as each tab's
  /// [PrimaryScrollController] so a tap on the tab you are already on can
  /// send it back to the top. The tab's own scroll view opts in with
  /// `primary: true`.
  final _tabScrollControllers = [
    for (var i = 0; i < 4; i++) ScrollController(),
  ];

  @override
  void initState() {
    super.initState();
    _resolveLandingTab();
  }

  @override
  void dispose() {
    for (final controller in _tabScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      return;
    }

    // Re-tapping the tab you are on means "take me back to the top". The
    // positions are animated one by one because a tab can host more than one
    // attached scrollable across its states.
    for (final position in _tabScrollControllers[index].positions) {
      position.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
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
        children: [
          for (var i = 0; i < pages.length; i++)
            PrimaryScrollController(
              controller: _tabScrollControllers[i],
              child: pages[i],
            ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
