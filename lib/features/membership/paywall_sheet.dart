import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_links.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/membership_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/membership_service.dart';
import '../../data/services/purchases_gateway.dart';
import 'membership_copy.dart';
import 'membership_toast.dart';

/// Opens the plan sheet over everything. Resolves true once the user is a
/// member — a purchase or a restore that found one — and false otherwise.
Future<bool> showPaywallSheet(
  BuildContext context, {
  required MembershipService service,
  required String source,
}) async {
  AnalyticsService.screen('paywall', properties: {'source': source});
  final result = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallSheet(service: service),
  );
  final entitled = result ?? false;
  // The one confirmation, over whatever screen the sheet closes onto.
  final membership = service.current;
  if (entitled && membership != null && context.mounted) {
    showMembershipToast(context, membership);
  }
  return entitled;
}

/// The plans, priced by the store, with the trial spelled out when one is
/// on offer and billing-today said plainly when it is not. Swipe down or
/// the close button returns to wherever it was opened from.
class PaywallSheet extends StatefulWidget {
  final MembershipService service;

  const PaywallSheet({super.key, required this.service});

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  List<MembershipPlan>? _plans;
  bool _plansFailed = false;

  /// Why the plans failed to load — shown on debug builds only, where the
  /// store setup is what usually needs fixing.
  String? _plansError;

  /// The chosen plan's product id. Yearly is preselected once the plans
  /// are in, whichever id this build's store gives it.
  String? _selected;
  bool _busy = false;
  String? _message;

  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => _openLink(AppLinks.terms);
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openLink(AppLinks.privacy);
  late final _restoreTap = TapGestureRecognizer()..onTap = _restore;

  bool get _trial => widget.service.current?.trialOffered ?? true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _restoreTap.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _plansFailed = false);
    try {
      final plans = await widget.service.plans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        if (!plans.any((plan) => plan.productId == _selected)) {
          _selected =
              plans.where((plan) => plan.isYearly).firstOrNull?.productId ??
                  plans.firstOrNull?.productId;
        }
      });
    } catch (error) {
      debugPrint('Paywall could not load the plans: $error');
      if (!mounted) return;
      setState(() {
        _plansFailed = true;
        _plansError = kDebugMode ? error.toString() : null;
      });
    }
  }

  MembershipPlan? get _selectedPlan =>
      _plans?.where((plan) => plan.productId == _selected).firstOrNull;

  Future<void> _purchase() async {
    final selected = _selected;
    if (_busy || selected == null || _selectedPlan == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final membership = await widget.service.purchase(selected);
      if (!mounted) return;
      if (membership.entitled) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _message =
          "The purchase went through but isn't active yet. Try Restore in "
              'a moment.');
    } on PurchaseCancelled {
      // Backed out of the App Store sheet: nothing to say.
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = "The purchase didn't go through. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final membership = await widget.service.restore();
      if (!mounted) return;
      if (membership.entitled) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(
        () => _message = 'No active subscription found for this Apple ID.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = "Couldn't reach the App Store. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLink(Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    setState(() => _message = "Couldn't open the page.");
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final plans = _plans;
    final trialDays = MembershipLockCopy.trialDays(plans);
    final trial = _trial;
    final selected = _selectedPlan;

    return Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height - media.padding.top - 40,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: Pressable(
                  semanticLabel: 'Close',
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    trial
                        ? trialDays > 0
                            ? 'Try Forma free for $trialDays days'
                            : 'Try Forma free'
                        : 'Choose your plan',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.7,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    trial
                        ? 'Full access to every tree, session logging and '
                            'progression. Nothing is charged until '
                            '${trialDays > 0 ? 'day $trialDays' : 'the trial ends'}.'
                        : 'Your program, sessions and skill-tree progress are '
                            'saved. Pick a plan to keep training.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (trial) ...[
                    const SizedBox(height: 22),
                    _TrialTimeline(trialDays: trialDays),
                  ],
                  const SizedBox(height: 22),
                  if (plans == null && !_plansFailed)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: LoadingIndicator()),
                    )
                  else if (plans == null)
                    _PlansFailed(detail: _plansError, onRetry: _loadPlans)
                  else
                    for (final plan in plans) ...[
                      _PlanCard(
                        plan: plan,
                        selected: plan.productId == _selected,
                        savingsPercent: plan.isYearly
                            ? MembershipLockCopy.yearlySavingsPercent(plans)
                            : null,
                        onTap: () => setState(() => _selected = plan.productId),
                      ),
                      const SizedBox(height: 10),
                    ],
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.amber,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, 6, 22, media.padding.bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PillButton(
                  label: _busy
                      ? 'Contacting the App Store…'
                      : trial
                          ? 'Start free trial'
                          : selected == null
                              ? 'Subscribe'
                              : 'Subscribe · ${selected.priceString} / '
                                  '${selected.periodLabel}',
                  radius: 14,
                  onTap: _busy || selected == null ? null : _purchase,
                ),
                const SizedBox(height: 12),
                _LegalLine(
                  text: _legalText(trial, trialDays, selected),
                  termsTap: _termsTap,
                  privacyTap: _privacyTap,
                  restoreTap: _restoreTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _legalText(
    bool trial,
    int trialDays,
    MembershipPlan? selected,
  ) {
    if (selected == null) return 'Cancel anytime';
    final price = '${selected.priceString} / ${selected.periodLabel}';
    if (trial) {
      final after = trialDays > 0 ? ' after $trialDays days' : '';
      return '\$0.00 today · then $price$after';
    }
    return 'Billed today · renews ${selected.isYearly ? 'yearly' : 'monthly'}'
        ' · cancel anytime';
  }
}

/// Today and the day billing starts — two points, no promises in between.
class _TrialTimeline extends StatelessWidget {
  final int trialDays;

  const _TrialTimeline({required this.trialDays});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TimelineRow(
          on: true,
          title: 'Today — full access',
          sub: 'Train, log and track every rep.',
          last: false,
        ),
        _TimelineRow(
          on: false,
          title: trialDays > 0
              ? 'Day $trialDays — billing starts'
              : 'When the trial ends — billing starts',
          sub: 'Cancel any time before in the App Store.',
          last: true,
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final bool on;
  final String title;
  final String sub;
  final bool last;

  const _TimelineRow({
    required this.on,
    required this.title,
    required this.sub,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? AppColors.accentPrimary : AppColors.surface3,
                    boxShadow: on
                        ? const [
                            BoxShadow(
                              color: AppColors.accentGlow,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: on
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.surface2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MembershipPlan plan;
  final bool selected;
  final int? savingsPercent;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.savingsPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = plan.isYearly ? 'Yearly' : 'Monthly';
    final meta = plan.isYearly
        ? '${plan.monthlyEquivalentString ?? plan.priceString} / month, '
            'billed ${plan.priceString} yearly'
        : 'Billed monthly';

    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$name plan, ${plan.priceString} per ${plan.periodLabel}',
      // Selection switches in one frame: an animated hand-over left the
      // card just left behind reading as selected for a beat.
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? AppColors.accentPrimary : AppColors.surface3,
                  width: selected ? 7 : 2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The badge sits beside the name where there is room and
                  // drops under it at a large text size.
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (savingsPercent != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'SAVE $savingsPercent%',
                            style: monoStyle(
                              size: 9.5,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              plan.priceString,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansFailed extends StatelessWidget {
  final String? detail;
  final VoidCallback onRetry;

  const _PlansFailed({required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          const Text(
            "Couldn't load the plans from the App Store.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextAction(label: 'Try again', onTap: onRetry),
        ],
      ),
    );
  }
}

class _LegalLine extends StatelessWidget {
  final String text;
  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;
  final TapGestureRecognizer restoreTap;

  const _LegalLine({
    required this.text,
    required this.termsTap,
    required this.privacyTap,
    required this.restoreTap,
  });

  static const _link = TextStyle(
    color: AppColors.textSecondary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          height: 1.5,
        ),
        children: [
          TextSpan(text: '$text · '),
          TextSpan(text: 'Terms', recognizer: termsTap, style: _link),
          const TextSpan(text: ' · '),
          TextSpan(text: 'Privacy', recognizer: privacyTap, style: _link),
          const TextSpan(text: ' · '),
          TextSpan(text: 'Restore', recognizer: restoreTap, style: _link),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
