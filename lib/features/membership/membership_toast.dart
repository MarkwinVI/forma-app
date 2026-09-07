import 'package:flutter/material.dart';

import '../../core/format/dates.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/membership_model.dart';

/// One confirmation after a purchase or restore lands: what started and
/// until when. Rides on the root overlay, so it stays up while the sheet
/// and the wizard under it close, and dismisses itself.
void showMembershipToast(BuildContext context, Membership membership) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final end = membership.expiresAt;
  final endLabel = end == null ? null : FormaDates.monthDay(context, end);
  final (title, sub) = switch (membership.state) {
    MembershipState.trialing => (
        'Trial started',
        endLabel == null
            ? 'Full access from today.'
            : 'Full access until $endLabel.',
      ),
    MembershipState.subscribed => (
        "You're in",
        endLabel == null
            ? 'Your plan is active.'
            : 'Your plan is active${membership.willRenew ? ' · renews $endLabel' : ' until $endLabel'}.',
      ),
    _ => ('Membership active', 'Full access from today.'),
  };

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _MembershipToast(
      title: title,
      sub: sub,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _MembershipToast extends StatefulWidget {
  final String title;
  final String sub;
  final VoidCallback onDone;

  const _MembershipToast({
    required this.title,
    required this.sub,
    required this.onDone,
  });

  @override
  State<_MembershipToast> createState() => _MembershipToastState();
}

class _MembershipToastState extends State<_MembershipToast>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(milliseconds: 3600);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void initState() {
    super.initState();
    // A beat after the sheet starts closing, so the toast lands on the
    // screen underneath rather than over the closing sheet.
    Future<void>.delayed(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      await _controller.forward();
      await Future<void>.delayed(_hold);
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    return Positioned(
      left: 16,
      right: 16,
      top: top,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.4), end: Offset.zero)
                .animate(curve),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.sub,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
