import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _activeColor = Color(0xFFFF8904);
const Color _inactiveColor = Color(0xFF9F9FA9);
const Color _bgColor = Color(0xFF282626);

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: _bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.query_stats,
                    label: 'Data',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Help',
                    index: 2,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? _activeColor : _inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 54,
        height: 54,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                  letterSpacing: 0.16,
                  height: 18 / 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
