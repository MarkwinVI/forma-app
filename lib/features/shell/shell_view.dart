import 'package:flutter/material.dart';

import '../../core/widgets/app_nav_bar.dart';
import '../data/data_view.dart';
import '../home/home_view.dart';
import '../program/program_view.dart';
import '../progress/progress_view.dart';

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
      ProgressView(isActive: _currentIndex == 0),
      HomeView(isActive: _currentIndex == 1),
      ProgramView(isActive: _currentIndex == 2),
      DataView(isActive: _currentIndex == 3),
    ];

    return Scaffold(
      extendBody: true,
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
