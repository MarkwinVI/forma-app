import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ExerciseSwitchChoice { progression, exercise, remove }

const _switchSheetBg = Color(0xFF1C1C1E);
const _switchText = Color(0xFFF2F2F7);
const _switchText2 = Color(0xFF8E8E93);
const _switchText3 = Color(0xFF636366);
const _switchAccent = Color(0xFFD4FF3A);
const _switchRed = Color(0xFFFF453A);

class ExerciseSwitchChooserSheet extends StatelessWidget {
  final String title;
  final String description;
  final bool showRemoveAction;

  const ExerciseSwitchChooserSheet({
    super.key,
    required this.title,
    required this.description,
    this.showRemoveAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: _ExerciseSwitchChooserContent(
          title: title,
          description: description,
          showDragHandle: true,
          showCancelAction: false,
          showRemoveAction: showRemoveAction,
          onSelect: (choice) => Navigator.of(context).pop(choice),
          onCancel: null,
        ),
      ),
    );
  }
}

class ExerciseSwitchChooserPage extends StatelessWidget {
  final String title;
  final String description;

  const ExerciseSwitchChooserPage({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _ExerciseSwitchChooserContent(
            title: title,
            description: description,
            showDragHandle: false,
            showCancelAction: true,
            showRemoveAction: false,
            onSelect: (choice) => Navigator.of(context).pop(choice),
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _ExerciseSwitchChooserContent extends StatelessWidget {
  final String title;
  final String description;
  final bool showDragHandle;
  final bool showCancelAction;
  final bool showRemoveAction;
  final ValueChanged<ExerciseSwitchChoice> onSelect;
  final VoidCallback? onCancel;

  const _ExerciseSwitchChooserContent({
    required this.title,
    required this.description,
    required this.showDragHandle,
    required this.showCancelAction,
    required this.showRemoveAction,
    required this.onSelect,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _switchSheetBg,
        borderRadius: BorderRadius.circular(showCancelAction ? 24 : 0),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        showCancelAction ? 20 : 0,
        20,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle)
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          if (showDragHandle) const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: _switchText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: _switchText2,
                      ),
                    ),
                  ],
                ),
              ),
              if (showCancelAction) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: _switchText2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _ExerciseSwitchChoiceTile(
            title: 'SKILL TREE',
            subtitle: 'Follow a skill-tree path that advances over time.',
            tone: _switchAccent,
            icon: Icons.timeline_rounded,
            onTap: () => onSelect(ExerciseSwitchChoice.progression),
          ),
          const SizedBox(height: 10),
          _ExerciseSwitchChoiceTile(
            title: 'SINGLE LIFT',
            subtitle: 'Drop in one standalone movement without a tree.',
            tone: _switchRed,
            icon: Icons.fitness_center_rounded,
            onTap: () => onSelect(ExerciseSwitchChoice.exercise),
          ),
          if (showRemoveAction) ...[
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => onSelect(ExerciseSwitchChoice.remove),
                child: Text(
                  'Remove item',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: _switchRed,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseSwitchChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color tone;
  final IconData icon;
  final VoidCallback onTap;

  const _ExerciseSwitchChoiceTile({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: tone.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 17,
                color: tone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                      color: _switchText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: _switchText2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _switchText3,
            ),
          ],
        ),
      ),
    );
  }
}
