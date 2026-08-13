import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';

/// A bold name inside a confirm body — the design reads names a shade
/// brighter than the surrounding copy.
TextSpan skillTreeConfirmBold(String text) => TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFFC9CAD1),
        fontWeight: FontWeight.w600,
      ),
    );

/// The confirmation popup every skill-tree edit goes through: a centered
/// card with a tinted icon, the question, what will change, and a Cancel /
/// confirm pair. [caution] renders the amber variant used by the calls that
/// jump ahead of the progression. Resolves true when the user confirms.
Future<bool> showSkillTreeConfirm(
  BuildContext context, {
  required IconData icon,
  required bool caution,
  required String title,
  required List<InlineSpan> body,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      final tint = caution ? AppColors.amber : AppColors.accentPrimary;
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 24),
                  blurRadius: 60,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 23, color: tint),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.38,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 9),
                Text.rich(
                  TextSpan(children: body),
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: Color(0xFF8A8B93),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ConfirmButton(
                        label: 'Cancel',
                        background: Colors.white.withValues(alpha: 0.06),
                        border: Colors.white.withValues(alpha: 0.08),
                        foreground: const Color(0xFFC9CAD1),
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ConfirmButton(
                        label: confirmLabel,
                        background: tint,
                        foreground: caution
                            ? const Color(0xFF1A1408)
                            : Colors.white,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color? border;
  final Color foreground;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.label,
    required this.background,
    this.border,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.15,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
