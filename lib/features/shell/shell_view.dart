import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_nav_bar.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/tab_reset.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/membership_service.dart';
import '../data/data_view.dart';
import '../home/home_view.dart';
import '../membership/membership_gate.dart';
import '../membership/membership_scope.dart';
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

  /// Mirrors [_currentIndex] for the tab index pages. They live inside their
  /// tab's [Navigator] route, which is built once and never re-runs on a
  /// shell rebuild, so `isActive` has to reach them through a listenable.
  final _activeIndex = ValueNotifier<int>(_progressTab);

  /// One navigator per tab: pushes inside a tab keep the bottom bar visible,
  /// the stack survives switching tabs, and re-tapping the active tab can
  /// unwind it back to the tab's index page. Flows that must take over the
  /// whole screen (workout, fullscreen video) opt out
  /// by pushing on the root navigator instead.
  final _tabNavigatorKeys = [
    for (var i = 0; i < 4; i++) GlobalKey<NavigatorState>(),
  ];

  /// Rebuilds the shell whenever a tab's stack changes so the [PopScope]
  /// around the scaffold always knows whether the active tab can pop.
  late final _tabStackObservers = [
    for (var i = 0; i < 4; i++) _TabStackObserver(_onTabStackChanged),
  ];

  /// One reset signal per tab, for index pages whose "deeper" state lives
  /// inside a widget rather than on the navigator stack (the Progress
  /// tab's focused skill tree). Fired on a re-tap once nothing is left to
  /// pop.
  final _tabResetNotifiers = [
    for (var i = 0; i < 4; i++) TabResetNotifier(),
  ];

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
    for (final notifier in _tabResetNotifiers) {
      notifier.dispose();
    }
    _activeIndex.dispose();
    super.dispose();
  }

  static const _tabScreenNames = [
    'tab_progress',
    'tab_train',
    'tab_program',
    'tab_profile',
  ];

  void _selectTab(int index) {
    // Tabs live in an IndexedStack, so no route change ever fires for them —
    // the switch itself is the screen view.
    AnalyticsService.screen(_tabScreenNames[index]);
    _activeIndex.value = index;
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      _selectTab(index);
      return;
    }

    // Re-tapping the tab you are on while deeper in it means "take me back
    // to this tab's index page".
    final navigator = _tabNavigatorKeys[index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    // Nothing on the stack, but the index page itself may be "deeper" — a
    // focused tree on the skill wheel — and unwind on its own.
    if (_tabResetNotifiers[index].fire()) return;

    // Already at the index page proper, so the re-tap means "take me back
    // to the top". The positions are animated one by one because a tab can
    // host more than one attached scrollable across its states.
    for (final position in _tabScrollControllers[index].positions) {
      position.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Route changes can land at setState-hostile moments (e.g. a pop driven
  /// from [PopScope]'s callback), so the rebuild waits for the next frame.
  void _onTabStackChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// The app always opens on Progress. The membership is awaited first, so
  /// the first frame already knows whether the tab is locked: main() started
  /// the load behind the splash, and it falls back to its cache on its own.
  Future<void> _resolveLandingTab() async {
    final userId = AuthService().currentUser?.id;
    if (userId != null) {
      try {
        await MembershipService.instance.load(userId);
      } catch (error, stackTrace) {
        debugPrint('Failed to load the membership: $error\n$stackTrace');
      }
    }
    if (mounted) _selectTab(_progressTab);
  }

  // Progress, Train and Program sit behind the membership gate: without a
  // membership they show dimmed under the lock dock. Profile
  // never does — sign out, account deletion and the subscription row have
  // to stay reachable whatever the membership says.
  Widget _tabPage(int tab, int activeIndex) {
    final Widget page;
    switch (tab) {
      case _trainTab:
        page = HomeView(isActive: activeIndex == _trainTab);
      case _programTab:
        page = ProgramView(isActive: activeIndex == _programTab);
      case _profileTab:
        return DataView(isActive: activeIndex == _profileTab);
      case _progressTab:
      default:
        page = ProgressView(isActive: activeIndex == _progressTab);
    }
    return MembershipGate(
      service: MembershipService.instance,
      child: page,
    );
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

    final activeTabCanPop =
        _tabNavigatorKeys[currentIndex].currentState?.canPop() ?? false;

    // The system back gesture unwinds the active tab's stack before it is
    // allowed to leave the app.
    return MembershipScope(
      service: MembershipService.instance,
      child: PopScope(
        canPop: !activeTabCanPop,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _tabNavigatorKeys[currentIndex].currentState?.maybePop();
        },
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: currentIndex,
            children: [
              for (var i = 0; i < 4; i++)
                Navigator(
                  key: _tabNavigatorKeys[i],
                  observers: [_tabStackObservers[i]],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (_) => TabReset(
                      notifier: _tabResetNotifiers[i],
                      child: PrimaryScrollController(
                        controller: _tabScrollControllers[i],
                        child: ValueListenableBuilder<int>(
                          valueListenable: _activeIndex,
                          builder: (_, activeIndex, __) =>
                              _tabPage(i, activeIndex),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: AppNavBar(
            currentIndex: currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}

class _TabStackObserver extends NavigatorObserver {
  _TabStackObserver(this.onStackChanged);

  final VoidCallback onStackChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onStackChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onStackChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onStackChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onStackChanged();
}
