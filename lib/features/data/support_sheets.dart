import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/feedback_service.dart';

/// The word under the stars, one per rating.
const feedbackRatingWords = ['Poor', 'Fair', 'Okay', 'Good', 'Great'];

/// What the feedback sheet holds between opens: dismissing keeps the draft
/// for next time, and a send clears it. Owned by the Profile tab.
class FeedbackDraft {
  int rating = 0;
  String text = '';
}

/// Same for the support sheet.
class SupportDraft {
  String text = '';
}

/// Rate the app 1–5, then say what could be better. Resolves with the
/// rating that was sent, or null when the sheet closed without sending.
Future<int?> showFeedbackSheet(
  BuildContext context, {
  required FeedbackDraft draft,
  ProfileFeedbackStore? store,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _FeedbackSheet(draft: draft, store: store),
  );
}

/// One field to support. Resolves with true when the message was sent.
Future<bool?> showContactSupportSheet(
  BuildContext context, {
  required SupportDraft draft,
  required String? replyEmail,
  ProfileFeedbackStore? store,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ContactSheet(
      draft: draft,
      replyEmail: replyEmail,
      store: store,
    ),
  );
}

// ── Feedback ──────────────────────────────────────────────────────────

class _FeedbackSheet extends StatefulWidget {
  final FeedbackDraft draft;
  final ProfileFeedbackStore? store;
  const _FeedbackSheet({required this.draft, required this.store});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  late final ProfileFeedbackStore _store = widget.store ?? FeedbackService();
  late final _text = TextEditingController(text: widget.draft.text);
  late int _rating = widget.draft.rating;
  bool _sending = false;
  bool _failed = false;
  int? _sentRating;

  @override
  void initState() {
    super.initState();
    AnalyticsService.screen('feedback_sheet');
    _text.addListener(() => widget.draft.text = _text.text);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _rate(int rating) {
    if (_sending) return;
    HapticFeedback.selectionClick();
    setState(() {
      _rating = rating;
      _failed = false;
    });
    widget.draft.rating = rating;
  }

  Future<void> _send() async {
    if (_sending || _rating == 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await _store.sendAppFeedback(rating: _rating, note: _text.text);
    } catch (error, stackTrace) {
      debugPrint('Failed to send app feedback: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failed = true;
      });
      return;
    }
    AnalyticsService.capture('app_feedback_submitted', properties: {
      'rating': _rating,
      'has_note': _text.text.trim().isNotEmpty,
    });
    widget.draft
      ..rating = 0
      ..text = '';
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sentRating = _rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sentRating;
    return _SupportSheetShell(
      caption: 'LEAVE FEEDBACK',
      onDismiss: () => Navigator.of(context).pop(sent),
      child: sent != null
          ? _DoneView(
              title: 'Thanks for your feedback!',
              onDone: () => Navigator.of(context).pop(sent),
            )
          : _FormView(
              title: "How's Forma so far?",
              cta: 'Send feedback',
              canSend: _rating > 0,
              sending: _sending,
              failed: _failed,
              onSend: _send,
              onCancel: () => Navigator.of(context).pop(),
              children: [
                const SizedBox(height: 26),
                _Stars(value: _rating, onChanged: _rate),
                const SizedBox(height: 22),
                Text('WHAT COULD BE BETTER', style: monoStyle(size: 10.5)),
                _BareField(
                  controller: _text,
                  enabled: !_sending,
                  minLines: 3,
                  hint: 'Optional — a missing exercise, something '
                      'confusing, anything.',
                ),
                const SizedBox(height: 12),
                _Footnote(
                    'Sent with your app version and device. No workout data.'),
              ],
            ),
    );
  }
}

// ── Contact support ───────────────────────────────────────────────────

class _ContactSheet extends StatefulWidget {
  final SupportDraft draft;
  final String? replyEmail;
  final ProfileFeedbackStore? store;
  const _ContactSheet({
    required this.draft,
    required this.replyEmail,
    required this.store,
  });

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  late final ProfileFeedbackStore _store = widget.store ?? FeedbackService();
  late final _text = TextEditingController(text: widget.draft.text);
  bool _sending = false;
  bool _failed = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.screen('contact_support_sheet');
    _text.addListener(() {
      // Selection and focus changes report through here too; only the
      // words matter, both for the draft and for clearing an error.
      if (_text.text == widget.draft.text) return;
      widget.draft.text = _text.text;
      setState(() => _failed = false);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSend => _text.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (_sending || !_canSend) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _failed = false;
    });
    final message = _text.text.trim();
    try {
      await _store.sendSupportMessage(message);
    } catch (error, stackTrace) {
      debugPrint('Failed to send support message: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failed = true;
      });
      return;
    }
    AnalyticsService.capture('support_message_sent', properties: {
      'message_length': message.length,
    });
    widget.draft.text = '';
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.replyEmail;
    return _SupportSheetShell(
      caption: 'CONTACT SUPPORT',
      onDismiss: () => Navigator.of(context).pop(_sent),
      child: _sent
          ? _DoneView(
              title: 'Thanks for contacting us',
              sub: 'We will get back to you within 1–2 business days.',
              onDone: () => Navigator.of(context).pop(true),
            )
          : _FormView(
              title: "What's going on?",
              cta: 'Send message',
              canSend: _canSend,
              sending: _sending,
              failed: _failed,
              onSend: _send,
              onCancel: () => Navigator.of(context).pop(false),
              children: [
                const SizedBox(height: 18),
                _BareField(
                  controller: _text,
                  enabled: !_sending,
                  minLines: 5,
                  hint: 'Describe the issue or question — a subscription '
                      'problem, a bug, a request.',
                ),
                const SizedBox(height: 12),
                _Footnote.rich(
                  email == null
                      ? const TextSpan(
                          text: 'We reply to your account email, usually '
                              'within a day.')
                      : TextSpan(children: [
                          const TextSpan(text: 'We reply to '),
                          TextSpan(
                            text: email,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                          const TextSpan(text: ', usually within a day.'),
                        ]),
                ),
              ],
            ),
    );
  }
}

// ── Shared chrome ─────────────────────────────────────────────────────

/// The Profile tab's sheet vocabulary, as the bodyweight edit: surface,
/// grabber, mono caption. The keyboard lifts the whole sheet, and the
/// body scrolls when a short screen cannot hold it.
class _SupportSheetShell extends StatelessWidget {
  final String caption;
  final Widget child;
  final VoidCallback onDismiss;

  const _SupportSheetShell({
    required this.caption,
    required this.child,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onDismiss();
      },
      child: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.only(bottom: keyboard),
          child: Container(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 16 + bottomInset),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(caption, style: monoStyle(size: 10.5)),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final String title;
  final String cta;
  final bool canSend;
  final bool sending;
  final bool failed;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final List<Widget> children;

  const _FormView({
    required this.title,
    required this.cta,
    required this.canSend,
    required this.sending,
    required this.failed,
    required this.onSend,
    required this.onCancel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        ...children,
        if (failed) ...[
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
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
        const SizedBox(height: 22),
        PillButton(
          label: sending ? 'Sending' : cta,
          semanticLabel: cta,
          onTap: canSend && !sending ? onSend : null,
        ),
        const SizedBox(height: 4),
        Pressable(
          onTap: sending ? null : onCancel,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Text(
              'Cancel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Five stars, and the word for the one picked beneath them.
class _Stars extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stars({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var n = 1; n <= 5; n++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: n == 1 ? 0 : 3),
                child: Pressable(
                  semanticLabel: n == 1 ? '1 star' : '$n stars',
                  selected: n <= value,
                  onTap: () => onChanged(n),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      n <= value
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 38,
                      color: n <= value
                          ? AppColors.accentPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value == 0
              ? 'TAP TO RATE'
              : feedbackRatingWords[value - 1].toUpperCase(),
          textAlign: TextAlign.center,
          style: monoStyle(
            size: 11.5,
            letterSpacing: 1.4,
            color: value == 0 ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// A bare text field above a hairline — the sheet's only input.
class _BareField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final String hint;

  const _BareField({
    required this.controller,
    required this.enabled,
    required this.minLines,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: minLines,
        maxLines: minLines + 4,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accentPrimary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  final TextSpan span;

  _Footnote(String text) : span = TextSpan(text: text);
  const _Footnote.rich(this.span);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      span,
      style: const TextStyle(
        fontSize: 13,
        height: 1.45,
        color: AppColors.textMuted,
      ),
    );
  }
}

/// The confirmation that takes the form's place: a green ring pops in,
/// its check draws itself, then the thanks line rises.
class _DoneView extends StatefulWidget {
  final String title;
  final String? sub;
  final VoidCallback onDone;

  const _DoneView({required this.title, this.sub, required this.onDone});

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
  );
  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.33, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 0.95, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 26),
        Center(
          child: ScaleTransition(
            scale: _ring,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green, width: 2),
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(30, 30),
                painter: _CheckPainter(progress: _check),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: _text,
          child: AnimatedBuilder(
            animation: _text,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 8 * (1 - _text.value)),
              child: child,
            ),
            child: Column(
              children: [
                const SizedBox(height: 22),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.sub != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      widget.sub!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        PillButton(label: 'Done', onTap: widget.onDone),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Draws the check stroke from its first corner to its tip as [progress]
/// runs 0 → 1.
class _CheckPainter extends CustomPainter {
  final Animation<double> progress;
  _CheckPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0) return;
    final s = size.width / 24;
    final path = Path()
      ..moveTo(5 * s, 12.6 * s)
      ..lineTo(9.4 * s, 16.9 * s)
      ..lineTo(19 * s, 7.2 * s);
    final paint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      final length = metric.length * math.min(1, t);
      canvas.drawPath(metric.extractPath(0, length), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
