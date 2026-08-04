import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../../../core/widgets/type_led.dart';
import '../../../data/catalog/exercise_catalog.dart';
import '../../../data/models/progression_suggestion_model.dart';
import 'what_changed_card.dart';

/// The Train tab's note that the program wants to change a loaded lift and
/// is waiting on the user.
///
/// It sits where the "updated" line sits and reads the same way — a mono
/// flag, one sentence, a way into the detail — but in amber, because this
/// one is not a report of something that happened. Nothing moves until the
/// user says so.
class NeedsApprovalLine extends StatelessWidget {
  final List<ProgressionSuggestion> suggestions;
  final VoidCallback onTap;

  const NeedsApprovalLine({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = summaryFor(suggestions);
    if (summary == null) return const SizedBox.shrink();

    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 22),
        padding: const EdgeInsets.only(top: 11, bottom: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider),
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Text(
              'NEEDS APPROVAL',
              style: monoStyle(
                size: 10,
                letterSpacing: 1.4,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// One suggestion says what it is; several are counted.
  static String? summaryFor(List<ProgressionSuggestion> suggestions) {
    if (suggestions.isEmpty) return null;
    if (suggestions.length == 1) {
      final suggestion = suggestions.first;
      final name = ExerciseCatalog.findById(suggestion.exerciseId)?.name ??
          'An exercise';
      return '$name · ${_change(suggestion)}';
    }
    return '${suggestions.length} lifts ready to move up';
  }
}

/// What a suggestion proposes, in the app's target vocabulary: sets × reps,
/// and the bar it is on.
String _change(ProgressionSuggestion suggestion) {
  final from = '${suggestion.sets}×${suggestion.fromValue}';
  final to = '${suggestion.sets}×${suggestion.toValue}';
  if (suggestion.kind == ProgressionSuggestionKind.repIncrease) {
    return '$from → $to';
  }
  return '$to at ${weightLabel(suggestion.toWeightKg)}';
}

String _why(ProgressionSuggestion suggestion) {
  final reached = '${suggestion.sets}×${suggestion.fromValue}';
  return switch (suggestion.kind) {
    ProgressionSuggestionKind.repIncrease =>
      'You hit $reached at ${weightLabel(suggestion.fromWeightKg)}. '
          'Same weight, one more rep per set.',
    ProgressionSuggestionKind.loadIncrease =>
      'You hit $reached — the top of the rep range. Add weight and start '
          'the reps again at ${suggestion.toValue}.',
  };
}

/// Lifts the proposals over the session, one card each, with the two answers
/// that resolve them.
Future<void> showNeedsApprovalSheet(
  BuildContext context,
  List<ProgressionSuggestion> suggestions, {
  required Future<void> Function(ProgressionSuggestion suggestion) onApprove,
  required Future<void> Function(ProgressionSuggestion suggestion) onDismiss,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (_) => _NeedsApprovalSheet(
      suggestions: suggestions,
      onApprove: onApprove,
      onDismiss: onDismiss,
    ),
  );
}

class _NeedsApprovalSheet extends StatefulWidget {
  final List<ProgressionSuggestion> suggestions;
  final Future<void> Function(ProgressionSuggestion suggestion) onApprove;
  final Future<void> Function(ProgressionSuggestion suggestion) onDismiss;

  const _NeedsApprovalSheet({
    required this.suggestions,
    required this.onApprove,
    required this.onDismiss,
  });

  @override
  State<_NeedsApprovalSheet> createState() => _NeedsApprovalSheetState();
}

class _NeedsApprovalSheetState extends State<_NeedsApprovalSheet> {
  late List<ProgressionSuggestion> _pending = List.of(widget.suggestions);
  String? _working;

  Future<void> _resolve(
    ProgressionSuggestion suggestion, {
    required bool approve,
  }) async {
    if (_working != null) return;
    setState(() => _working = suggestion.id ?? suggestion.exerciseId);
    try {
      approve
          ? await widget.onApprove(suggestion)
          : await widget.onDismiss(suggestion);
      if (!mounted) return;
      setState(() {
        _pending = [
          for (final item in _pending)
            if (item.exerciseId != suggestion.exerciseId) item,
        ];
        _working = null;
      });
      if (_pending.isEmpty) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _working = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save that. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        30 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            'NEEDS APPROVAL',
            style: monoStyle(
              size: 10.5,
              letterSpacing: 1.55,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _pending.length == 1
                ? 'Ready to move up'
                : '${_pending.length} lifts ready to move up',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.81,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Weighted lifts are yours to load. Forma proposes the next step '
            'and leaves it to you.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          for (final suggestion in _pending)
            _SuggestionBlock(
              suggestion: suggestion,
              busy: _working == (suggestion.id ?? suggestion.exerciseId),
              onApprove: () => _resolve(suggestion, approve: true),
              onDismiss: () => _resolve(suggestion, approve: false),
            ),
        ],
      ),
    );
  }
}

class _SuggestionBlock extends StatelessWidget {
  final ProgressionSuggestion suggestion;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

  const _SuggestionBlock({
    required this.suggestion,
    required this.busy,
    required this.onApprove,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = ExerciseCatalog.findById(suggestion.exerciseId);

    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  exercise?.name ?? suggestion.exerciseId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _change(suggestion),
                style: monoStyle(
                  size: 14,
                  letterSpacing: 0.2,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _why(suggestion),
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'Not yet',
                  onTap: busy ? null : onDismiss,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetButton(
                  label: 'Approve',
                  filled: true,
                  busy: busy,
                  onTap: busy ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback? onTap;

  const _SheetButton({
    required this.label,
    this.filled = false,
    this.busy = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null && !busy ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.accentPrimary : null,
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: AppColors.divider),
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.17,
                  ),
                ),
        ),
      ),
    );
  }
}
