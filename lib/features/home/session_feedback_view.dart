import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/feedback_service.dart';

/// One reason a session rating can carry. The [id] is what is stored and
/// reported; the [label] is what the pill says.
class SessionFeedbackTag {
  final String id;
  final String label;
  const SessionFeedbackTag(this.id, this.label);
}

/// The reason set behind each thumb. "Wrong exercises" is the one tag that
/// asks a follow-up — which ones — so the screen knows it by id.
const sessionFeedbackUpTags = [
  SessionFeedbackTag('right_difficulty', 'Right difficulty'),
  SessionFeedbackTag('good_exercise_picks', 'Good exercise picks'),
  SessionFeedbackTag('clear_instructions', 'Clear instructions'),
  SessionFeedbackTag('rest_times_right', 'Rest times felt right'),
  SessionFeedbackTag('good_variety', 'Good variety'),
  SessionFeedbackTag('making_progress', 'Making progress'),
];

const sessionFeedbackDownTags = [
  SessionFeedbackTag('too_hard', 'Too hard'),
  SessionFeedbackTag('too_easy', 'Too easy'),
  SessionFeedbackTag(wrongExercisesTagId, 'Wrong exercises'),
  SessionFeedbackTag('getting_repetitive', 'Getting repetitive'),
  SessionFeedbackTag('not_making_progress', 'Not making progress'),
  SessionFeedbackTag('app_problem', 'App problem'),
];

const wrongExercisesTagId = 'wrong_exercises';

/// The last screen of the post-workout sequence: how was this session?
///
/// A thumb is recorded the moment it is tapped and opens the reasons under
/// it — pills, and for a thumbs-down that names wrong exercises, the
/// session's exercises as chips — plus an optional note. Send writes the
/// lot and leaves; closing early keeps whatever was picked. Skip, with no
/// thumb, records nothing at all. Every path ends back on the tab shell.
class SessionFeedbackView extends StatefulWidget {
  /// The saved `workout_sessions` row the rating is about; null when the
  /// save could not say.
  final String? workoutSessionId;

  /// The session's exercises, in order, for the "which ones?" chips.
  final List<Exercise> exercises;

  /// Where ratings go. Defaults to Supabase; tests hand in a fake.
  final SessionFeedbackStore? store;

  const SessionFeedbackView({
    super.key,
    required this.workoutSessionId,
    required this.exercises,
    this.store,
  });

  @override
  State<SessionFeedbackView> createState() => _SessionFeedbackViewState();
}

class _SessionFeedbackViewState extends State<SessionFeedbackView> {
  late final SessionFeedbackStore _store = widget.store ?? FeedbackService();
  final _note = TextEditingController();

  FeedbackSentiment? _sentiment;
  final _tags = <String>{};
  final _flagged = <String>{};

  bool _sending = false;
  bool _sendFailed = false;

  /// The row a thumb tap created; later writes update it instead of
  /// adding another.
  String? _rowId;

  /// Writes go out one after another, so a thumb tapped twice quickly can
  /// never race itself into two rows.
  Future<void> _writeChain = Future.value();

  bool _analyticsCaptured = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.screen('session_feedback');
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<SessionFeedbackTag> get _tagOptions => switch (_sentiment) {
        FeedbackSentiment.up => sessionFeedbackUpTags,
        FeedbackSentiment.down => sessionFeedbackDownTags,
        null => const [],
      };

  bool get _expanded => _sentiment != null;

  bool get _flagsExercises =>
      _sentiment == FeedbackSentiment.down &&
      _tags.contains(wrongExercisesTagId);

  bool get _hasDetails =>
      _tags.isNotEmpty || _flagged.isNotEmpty || _note.text.trim().isNotEmpty;

  /// The session's exercises, each once, in the order they were done.
  List<Exercise> get _exerciseOptions {
    final seen = <String>{};
    return [
      for (final exercise in widget.exercises)
        if (seen.add(exercise.id)) exercise,
    ];
  }

  // ── Interaction ───────────────────────────────────────────────────

  void _pickSentiment(FeedbackSentiment sentiment) {
    if (_sending) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_sentiment != sentiment) {
        // The reasons belong to a thumb; a change of mind starts them over.
        _tags.clear();
        _flagged.clear();
      }
      _sentiment = sentiment;
      _sendFailed = false;
    });
    _persistQuietly();
  }

  void _toggleTag(String id) {
    if (_sending) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_tags.remove(id)) _tags.add(id);
      if (!_flagsExercises) _flagged.clear();
    });
  }

  void _toggleExercise(String id) {
    if (_sending) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_flagged.remove(id)) _flagged.add(id);
    });
  }

  /// Send: the write must land before the screen goes, so a failure can be
  /// shown and retried with everything still in place.
  Future<void> _send() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _sendFailed = false;
    });
    try {
      await _persist();
    } catch (error, stackTrace) {
      debugPrint('Failed to send session feedback: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendFailed = true;
      });
      return;
    }
    if (!mounted) return;
    _captureAnalytics();
    _leave();
  }

  /// Close or system back: a chosen thumb, and whatever was picked under
  /// it, still counts — the write goes out on its own. No thumb means
  /// nothing is recorded.
  void _dismiss() {
    if (_sending) return;
    if (_sentiment != null) {
      _persistQuietly();
      _captureAnalytics();
    }
    _leave();
  }

  void _leave() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Persistence ───────────────────────────────────────────────────

  Future<void> _persist() {
    final sentiment = _sentiment;
    if (sentiment == null) return Future.value();
    final tags = _tags.toList();
    final flagged = _flagged.toList();
    final note = _note.text;
    final write = _writeChain.then((_) async {
      _rowId = await _store.save(
        id: _rowId,
        workoutSessionId: widget.workoutSessionId,
        sentiment: sentiment,
        tags: tags,
        flaggedExerciseIds: flagged,
        note: note,
      );
    });
    // The chain carries on past a failure; the failure itself is the
    // caller's to handle.
    _writeChain = write.catchError((_) {});
    return write;
  }

  void _persistQuietly() {
    unawaited(_persist().catchError((Object error, StackTrace stackTrace) {
      debugPrint('Failed to save session feedback: $error\n$stackTrace');
    }));
  }

  /// One event per rating, with the reasons and whether a note came with
  /// it — never the note itself.
  void _captureAnalytics() {
    final sentiment = _sentiment;
    if (sentiment == null || _analyticsCaptured) return;
    _analyticsCaptured = true;
    AnalyticsService.capture('session_feedback_submitted', properties: {
      if (widget.workoutSessionId != null)
        'workout_id': widget.workoutSessionId!,
      'sentiment': sentiment.dbValue,
      'tags': _tags.toList(),
      'flagged_exercise_ids': _flagged.toList(),
      'flagged_exercise_count': _flagged.length,
      'has_note': _note.text.trim().isNotEmpty,
    });
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 280);
    const curve = Curves.easeOutCubic;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _dismiss();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _CloseRow(onClose: _sending ? null : _dismiss),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _sending,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: AnimatedPadding(
                      duration: duration,
                      curve: curve,
                      padding: EdgeInsets.fromLTRB(
                          22, _expanded ? 18 : 110, 22, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: duration,
                            curve: curve,
                            style: TextStyle(
                              fontSize: _expanded ? 24 : 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            child: const Text('How was this session?'),
                          ),
                          AnimatedContainer(
                            duration: duration,
                            curve: curve,
                            height: _expanded ? 20 : 40,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ThumbButton(
                                sentiment: FeedbackSentiment.up,
                                selected: _sentiment == FeedbackSentiment.up,
                                compact: _expanded,
                                duration: duration,
                                onTap: () =>
                                    _pickSentiment(FeedbackSentiment.up),
                              ),
                              AnimatedContainer(
                                duration: duration,
                                curve: curve,
                                width: _expanded ? 16 : 20,
                              ),
                              _ThumbButton(
                                sentiment: FeedbackSentiment.down,
                                selected:
                                    _sentiment == FeedbackSentiment.down,
                                compact: _expanded,
                                duration: duration,
                                onTap: () =>
                                    _pickSentiment(FeedbackSentiment.down),
                              ),
                            ],
                          ),
                          _Grow(
                            duration: duration,
                            child: _expanded
                                ? _Details(
                                    key: ValueKey(_sentiment),
                                    sentiment: _sentiment!,
                                    tagOptions: _tagOptions,
                                    tags: _tags,
                                    exercises: _flagsExercises
                                        ? _exerciseOptions
                                        : const [],
                                    flagged: _flagged,
                                    note: _note,
                                    sendFailed: _sendFailed,
                                    duration: duration,
                                    onToggleTag: _toggleTag,
                                    onToggleExercise: _toggleExercise,
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: duration,
                child: _expanded
                    ? _SendFooter(
                        key: const ValueKey('send'),
                        label: _sending
                            ? 'Sending'
                            : _hasDetails
                                ? 'Send'
                                : 'Done',
                        onTap: _sending ? null : _send,
                      )
                    : Padding(
                        key: const ValueKey('skip'),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: Pressable(
                          onTap: _dismiss,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            alignment: Alignment.center,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grows to fit a child that appears or changes. Under Reduce Motion the
/// change is immediate — an AnimatedSize with no duration would try to
/// re-lay itself out mid-layout.
class _Grow extends StatelessWidget {
  final Duration duration;
  final Widget child;
  const _Grow({required this.duration, required this.child});

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Only the close button up top: no step bars here, this is the one and
/// only screen. Drawn at 30; the tap catches 44×44.
class _CloseRow extends StatelessWidget {
  final VoidCallback? onClose;
  const _CloseRow({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 3, 13, 0),
      child: SizedBox(
        height: 44,
        child: Align(
          alignment: Alignment.centerRight,
          child: Pressable(
            semanticLabel: 'Close',
            onTap: onClose,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbButton extends StatelessWidget {
  final FeedbackSentiment sentiment;
  final bool selected;
  final bool compact;
  final Duration duration;
  final VoidCallback onTap;

  const _ThumbButton({
    required this.sentiment,
    required this.selected,
    required this.compact,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final up = sentiment == FeedbackSentiment.up;
    final icon = selected
        ? (up ? Icons.thumb_up_rounded : Icons.thumb_down_rounded)
        : (up ? Icons.thumb_up_outlined : Icons.thumb_down_outlined);
    final size = compact ? 64.0 : 76.0;
    return Pressable(
      semanticLabel: up ? 'Thumbs up' : 'Thumbs down',
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary : AppColors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: compact ? 27 : 32,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// The reasons under a chosen thumb: pills, the exercise chips a
/// thumbs-down may ask for, and the note.
class _Details extends StatelessWidget {
  final FeedbackSentiment sentiment;
  final List<SessionFeedbackTag> tagOptions;
  final Set<String> tags;
  final List<Exercise> exercises;
  final Set<String> flagged;
  final TextEditingController note;
  final bool sendFailed;
  final Duration duration;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<String> onToggleExercise;

  const _Details({
    super.key,
    required this.sentiment,
    required this.tagOptions,
    required this.tags,
    required this.exercises,
    required this.flagged,
    required this.note,
    required this.sendFailed,
    required this.duration,
    required this.onToggleTag,
    required this.onToggleExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 26),
        _SectionLabel(
          sentiment == FeedbackSentiment.up
              ? 'What worked well? (pick any)'
              : 'What went wrong? (pick any)',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tagOptions)
              _Pill(
                label: tag.label,
                selected: tags.contains(tag.id),
                onTap: () => onToggleTag(tag.id),
              ),
          ],
        ),
        _Grow(
          duration: duration,
          child: exercises.isEmpty
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    const _SectionLabel('Which ones? (tap any)'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final exercise in exercises)
                          _Pill(
                            label: exercise.name,
                            selected: flagged.contains(exercise.id),
                            dense: true,
                            onTap: () => onToggleExercise(exercise.id),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _NoteField(controller: note),
        if (sendFailed) ...[
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.red),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  "Couldn't send. Try again.",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: AppColors.textMuted,
      ),
    );
  }
}

/// A multi-select pill: accent when picked, tonal otherwise.
class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary : AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 6,
        maxLength: 1000,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accentPrimary,
        decoration: const InputDecoration(
          hintText: 'Add a note (optional)',
          hintStyle: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _SendFooter extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SendFooter({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 26),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: PillButton(label: label, onTap: onTap),
    );
  }
}
