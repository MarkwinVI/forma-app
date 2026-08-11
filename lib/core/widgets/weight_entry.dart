import 'package:flutter/material.dart';

import '../../data/services/weight_unit_service.dart';
import '../theme/app_colors.dart';
import 'polished.dart';

/// Shared pieces of the tap-to-type weight editor: the kg/lbs segmented
/// toggle, the big tappable number with a blinking caret, and the bare
/// decimal keypad. Program setup's bodyweight step and the profile's
/// bodyweight sheet are built from the same three.

/// The typing model both editors share: '' means untouched (the current
/// value shows dimmed as the placeholder), digits append, one decimal
/// place, three integer digits at most.
String weightEntryPress(String edit, String key) {
  if (key == 'del') {
    return edit.isEmpty ? edit : edit.substring(0, edit.length - 1);
  }
  if (key == '.') {
    return edit.contains('.') ? edit : (edit.isEmpty ? '0.' : '$edit.');
  }
  if (edit.contains('.')) {
    return edit.split('.')[1].isNotEmpty ? edit : '$edit$key';
  }
  if (edit.length >= 3) return edit;
  return edit == '0' ? key : '$edit$key';
}

class WeightUnitToggle extends StatelessWidget {
  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  const WeightUnitToggle({
    super.key,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in WeightUnit.values)
            Pressable(
              onTap: () => onChanged(option),
              child: Container(
                constraints: const BoxConstraints(minWidth: 78),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: option == unit ? AppColors.surface2 : null,
                  borderRadius: BorderRadius.circular(9.5),
                  border: option == unit
                      ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                      : null,
                  boxShadow: option == unit
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option.suffix,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: option == unit
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The number itself is the tap target. While editing, a caret blinks after
/// the text and the current value sits dimmed as the placeholder until the
/// first key.
class WeightValueDisplay extends StatelessWidget {
  final String text;
  final bool dim;
  final WeightUnit unit;
  final bool editing;
  final double size;
  final VoidCallback onTap;

  const WeightValueDisplay({
    super.key,
    required this.text,
    required this.dim,
    required this.unit,
    required this.editing,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: size * -0.03,
                color: dim ? AppColors.textMuted : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (editing) ...[
              const SizedBox(width: 5),
              _BlinkingCaret(height: size * 0.78),
            ],
            const SizedBox(width: 7),
            Text(
              unit.suffix,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  final double height;

  const _BlinkingCaret({required this.height});

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: _controller.value < 0.5 ? 1 : 0,
        child: Container(
          width: 3,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Decimal keypad: bare digits on a grid above a hairline — no key tiles.
class WeightKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;

  const WeightKeypad({super.key, required this.onKey});

  static const _keys = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    '.', '0', 'del',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              children: [
                for (var column = 0; column < 3; column++)
                  Expanded(
                    child: Pressable(
                      onTap: () => onKey(_keys[row * 3 + column]),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: _keys[row * 3 + column] == 'del'
                              ? const Icon(
                                  Icons.backspace_outlined,
                                  size: 22,
                                  color: AppColors.textSecondary,
                                )
                              : Text(
                                  _keys[row * 3 + column],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
