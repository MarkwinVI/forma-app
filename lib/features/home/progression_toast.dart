import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';

/// What a progression change was: the tag color and icon follow it.
enum ProgressionToastKind { started, moved, stopped }

/// One receipt toast's content — shown after a progression change has been
/// applied, spelling out what changed and offering UNDO.
class ProgressionToastData {
  final ProgressionToastKind kind;

  /// Headline for started/stopped receipts. Ignored when [outName]/[inName]
  /// are set — the swap pair is the headline then.
  final String? title;

  /// The old → new exercise pair of a moved progression.
  final String? outName;
  final String? inName;

  /// The consequence line. [subBold] fragments render emphasized.
  final String sub;
  final List<String> subBold;

  final Future<void> Function()? onUndo;

  const ProgressionToastData({
    required this.kind,
    this.title,
    this.outName,
    this.inName,
    required this.sub,
    this.subBold = const [],
    this.onUndo,
  });
}

/// The receipt toast itself: icon, mono status tag, the change spelled out
/// (headline or OUT/IN pair), a consequence line, and UNDO.
class ProgressionToast extends StatelessWidget {
  final ProgressionToastData data;
  final VoidCallback? onUndoTap;

  const ProgressionToast({
    super.key,
    required this.data,
    this.onUndoTap,
  });

  Color get _tagColor => switch (data.kind) {
        ProgressionToastKind.started => AppColors.accentBright,
        ProgressionToastKind.moved => AppColors.accentBright,
        ProgressionToastKind.stopped => AppColors.red,
      };

  String get _tag => switch (data.kind) {
        ProgressionToastKind.started => 'PROGRESSION STARTED',
        ProgressionToastKind.moved => 'PROGRESSION MOVED',
        ProgressionToastKind.stopped => 'PROGRESSION STOPPED',
      };

  IconData get _icon => switch (data.kind) {
        ProgressionToastKind.started => Icons.add_rounded,
        ProgressionToastKind.moved => Icons.swap_horiz_rounded,
        ProgressionToastKind.stopped => Icons.remove_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final hasPair = data.outName != null && data.inName != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF26262C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 34,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _tagColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 18, color: _tagColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tag,
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: _tagColor,
                        ),
                      ),
                    ),
                    if (data.onUndo != null)
                      Pressable(
                        onTap: onUndoTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'UNDO',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.accentBright,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (hasPair) ...[
                  const SizedBox(height: 6),
                  _PairRow(
                    name: data.outName!,
                    tag: 'OUT',
                    out: true,
                  ),
                  const SizedBox(height: 2),
                  _PairRow(
                    name: data.inName!,
                    tag: 'IN',
                    out: false,
                  ),
                ] else if (data.title != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    data.title!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _subLine(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The consequence line with its named things emphasized.
  Widget _subLine() {
    const body = TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: AppColors.textSecondary,
    );
    const bold = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFFD5D6DB),
    );

    var rest = data.sub;
    final spans = <TextSpan>[];
    while (rest.isNotEmpty) {
      var cut = -1;
      String? hit;
      for (final fragment in data.subBold) {
        final at = rest.indexOf(fragment);
        if (at >= 0 && (cut < 0 || at < cut)) {
          cut = at;
          hit = fragment;
        }
      }
      if (hit == null) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (cut > 0) spans.add(TextSpan(text: rest.substring(0, cut)));
      spans.add(TextSpan(text: hit, style: bold));
      rest = rest.substring(cut + hit.length);
    }

    return Text.rich(TextSpan(style: body, children: spans));
  }
}

/// One line of the swap pair: struck-through OUT, bold IN.
class _PairRow extends StatelessWidget {
  final String name;
  final String tag;
  final bool out;

  const _PairRow({required this.name, required this.tag, required this.out});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: out
                ? TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor:
                        AppColors.textMuted.withValues(alpha: 0.6),
                  )
                : const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          tag,
          style: GoogleFonts.robotoMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: out ? AppColors.textMuted : AppColors.accentBright,
          ),
        ),
      ],
    );
  }
}
