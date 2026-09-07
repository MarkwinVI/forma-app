import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_links.dart';
import '../../core/format/dates.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/type_led.dart';
import '../../data/models/membership_model.dart';
import '../../data/services/membership_service.dart';
import 'membership_copy.dart';
import 'membership_scope.dart';
import 'membership_toast.dart';
import 'paywall_sheet.dart';

/// The Profile tab's SUBSCRIPTION section. Locked: the way in (the trial,
/// or a plan) and Restore for someone already subscribed on another
/// device. A member: the plan, when it renews or ends, and where to manage
/// it — changes and cancellation happen in the App Store.
class SubscriptionRows extends StatefulWidget {
  final MembershipService service;

  const SubscriptionRows({super.key, required this.service});

  @override
  State<SubscriptionRows> createState() => _SubscriptionRowsState();
}

class _SubscriptionRowsState extends State<SubscriptionRows> {
  List<MembershipPlan>? _plans;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    widget.service.plans().then((plans) {
      if (mounted) setState(() => _plans = plans);
    }, onError: (Object _) {});
  }

  Future<void> _openPaywall() => showPaywallSheet(
        context,
        service: widget.service,
        source: 'profile',
      );

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    String? message;
    try {
      final membership = await widget.service.restore();
      if (membership.entitled) {
        if (mounted) showMembershipToast(context, membership);
      } else {
        message = 'No active subscription found for this Apple ID.';
      }
    } catch (_) {
      message = "Couldn't reach the App Store. Try again.";
    }
    if (!mounted) return;
    setState(() => _restoring = false);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _manage() async {
    final opened = await launchUrl(
      AppLinks.manageSubscriptions,
      mode: LaunchMode.externalApplication,
    );
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open the App Store.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membership = MembershipScope.maybeOf(context);
    if (membership == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TypeSectionLabel('Subscription'),
        if (membership.locked)
          ..._lockedRows(membership)
        else
          ..._memberRows(
            context,
            membership,
          ),
      ],
    );
  }

  List<Widget> _lockedRows(Membership membership) {
    final trial = membership.trialOffered;
    final from = MembershipLockCopy.fromMonthly(_plans);
    final days = MembershipLockCopy.trialDays(_plans);
    return [
      TypeContentRow(
        onTap: _openPaywall,
        child: _AccentName(
          name: trial
              ? 'Start free trial'
              : membership.state == MembershipState.lapsed
                  ? 'Resume plan'
                  : 'Subscribe',
          sub: trial
              ? '${days > 0 ? '$days days' : 'Free'} to start'
                  '${from == null ? '' : ', then from $from / month'}'
              : from == null
                  ? 'Train, log sessions and track progress'
                  : 'From $from / month',
        ),
      ),
      TypeContentRow(
        name: _restoring ? 'Restoring…' : 'Restore purchase',
        sub: 'Already subscribed on another device',
        last: true,
        onTap: _restoring ? null : _restore,
      ),
    ];
  }

  List<Widget> _memberRows(BuildContext context, Membership membership) {
    final end = membership.expiresAt;
    final endLabel = end == null ? null : FormaDates.monthDay(context, end);
    final plan = _plans
        ?.where((plan) => plan.productId == membership.productId)
        .firstOrNull;
    final price =
        plan == null ? null : '${plan.priceString} / ${plan.periodLabel}';
    final yearly = membership.productId == null
        ? null
        : MembershipProducts.isYearly(membership.productId!);

    final String name;
    final String sub;
    String? badge;
    switch (membership.state) {
      case MembershipState.trialing:
        name = yearly == null
            ? 'Free trial'
            : '${yearly ? 'Yearly' : 'Monthly'} plan';
        badge = 'TRIAL';
        sub = endLabel == null
            ? 'Free trial'
            : membership.willRenew
                ? 'Free until $endLabel${price == null ? '' : ', then $price'}'
                : 'Free until $endLabel · cancelled';
      case MembershipState.subscribed:
        name = '${yearly == true ? 'Yearly' : 'Monthly'} plan';
        sub = endLabel == null
            ? 'Active'
            : membership.willRenew
                ? 'Renews $endLabel${price == null ? '' : ' · $price'}'
                : 'Ends $endLabel';
      case MembershipState.complimentary:
        name = 'Free access';
        sub = membership.overrideSource == 'grandfathered'
            ? 'Yours for good — you were here before membership'
            : endLabel == null
                ? 'Complimentary membership'
                : 'Complimentary until $endLabel';
      default:
        return const [];
    }

    final manageable = membership.state != MembershipState.complimentary;
    return [
      TypeContentRow(
        chevron: false,
        last: !manageable,
        child: _AccentName(name: name, sub: sub, badge: badge, accent: false),
      ),
      if (manageable)
        TypeContentRow(
          name: 'Manage subscription',
          sub: 'Change or cancel in the App Store',
          last: true,
          onTap: _manage,
        ),
    ];
  }
}

/// A content row body: the name (accent-coloured for the way in), an
/// optional mono badge beside it, and the line under it.
class _AccentName extends StatelessWidget {
  final String name;
  final String sub;
  final String? badge;
  final bool accent;

  const _AccentName({
    required this.name,
    required this.sub,
    this.badge,
    this.accent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color:
                      accent ? AppColors.accentPrimary : AppColors.textPrimary,
                  letterSpacing: -0.42,
                  height: 1.15,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: monoStyle(
                    size: 9.5,
                    color: AppColors.green,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            sub,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
