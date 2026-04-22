import 'package:flutter/material.dart';

import '../../core/widgets/app_nav_bar.dart';
import '../data/data_view.dart';
import '../home/home_view.dart';
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
      const HomeView(),
      DataView(isActive: _currentIndex == 1),
      const SkillsView(),
      const SettingsView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
