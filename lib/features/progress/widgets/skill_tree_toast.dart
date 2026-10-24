import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A passing confirmation under the status bar — "Now training Pistol
/// Squat", "Squat paused — progress kept". It lives in the root overlay, so
/// it outlives a screen that leaves right after the edit it confirms (the
/// Program tab's wheel pops on a saved pick). Fades in, holds, fades out.
void showSkillTreeToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SkillTreeToast(
      message: message,
      onDismissed: () {
        if (!entry.mounted) return;
        entry
          ..remove()
          ..dispose();
      },
    ),
  );
  overlay.insert(entry);
}

class _SkillTreeToast extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const _SkillTreeToast({required this.message, required this.onDismissed});

  @override
  State<_SkillTreeToast> createState() => _SkillTreeToastState();
}

class _SkillTreeToastState extends State<_SkillTreeToast>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(milliseconds: 2200);

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fade.forward();
    _timer = Timer(_hold, () async {
      if (!mounted) return;
      await _fade.reverse();
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    offset: Offset(0, 10),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
