import 'package:flutter/material.dart';

import '../../core/widgets/app_nav_bar.dart';
import '../data/data_view.dart';
import '../home/home_view.dart';
import '../progress/progress_view.dart';
import '../settings/settings_view.dart';
import '../skills/skills_view.dart';

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProgressView(
        isActive: _currentIndex == 0,
        onOpenSkillsTab: () => setState(() => _currentIndex = 3),
      ),
      HomeView(
        onOpenSettings: () => setState(() => _currentIndex = 4),
        isActive: _currentIndex == 1,
      ),
      DataView(isActive: _currentIndex == 2),
      SkillsView(isActive: _currentIndex == 3),
      const SettingsView(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentIndex >= 4 ? -1 : _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
