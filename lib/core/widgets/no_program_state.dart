import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'polished.dart';
import 'type_led.dart';

/// The shape every empty tab takes before a program exists: a statement of
/// what will be here and the one action that fills it in.
///
/// All three tabs tell the same story and offer the same way out, so they
/// share this shell rather than each inventing an empty screen.
class NoProgramState extends StatelessWidget {
  final String title;
  final String sub;

  /// What sits between the statement and the action — a skeleton week, the
  /// paths not started yet. Program has nothing between the two.
  final List<Widget> children;
  final VoidCallback onCreateProgram;

  const NoProgramState({
    super.key,
    required this.title,
    required this.sub,
    this.children = const [],
    required this.onCreateProgram,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            // Centred in the viewport rather than pinned under the status bar:
            // there is no content above it to anchor to.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 130),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TypeTitle(title, sub: sub),
                  ...children,
                  const SizedBox(height: 26),
                  PillButton(
                    label: 'Create my program',
                    radius: 14,
                    onTap: onCreateProgram,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A row of the thing that is not there yet: a name stepped back, and a mono
/// note on the right saying so.
class GhostRow extends StatelessWidget {
  final String name;
  final String note;
  final double nameSize;
  final bool last;

  const GhostRow({
    super.key,
    required this.name,
    required this.note,
    this.nameSize = 21,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: nameSize,
                fontWeight: nameSize >= 21 ? FontWeight.w800 : FontWeight.w700,
                color: nameSize >= 21
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                letterSpacing: nameSize * -0.02,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            note,
            style: monoStyle(
              size: note == '—' ? 14 : 12.5,
              letterSpacing: note == '—' ? 0 : 1,
            ),
          ),
        ],
      ),
    );
  }
}
