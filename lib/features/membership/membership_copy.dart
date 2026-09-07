import '../../data/models/membership_model.dart';

/// What the lock says, by how the user got here. One vocabulary for the
/// lock docks on every tab and the Profile's subscription row, so the app
/// never contradicts itself about someone's membership.
class MembershipLockCopy {
  final String title;
  final String body;

  /// The button, given the plans (null while they load).
  final String Function(List<MembershipPlan>? plans) cta;

  /// The quiet line under the button.
  final String Function(List<MembershipPlan>? plans) sub;

  const MembershipLockCopy({
    required this.title,
    required this.body,
    required this.cta,
    required this.sub,
  });

  /// Whether the CTAs may promise a free trial: Apple would grant one
  /// (per [Membership.trialOffered]) and the plans on sale actually carry
  /// an intro period. Before the plans are in, the store's word stands;
  /// once they are, a product without a free period is sold as a plan.
  static bool offersTrial(
    Membership? membership,
    List<MembershipPlan>? plans,
  ) {
    final storeSays = membership?.trialOffered ?? true;
    return storeSays && (plans == null || trialDays(plans) > 0);
  }

  /// The lock copy for [membership], given the plans: a trial that the
  /// products do not carry reads as "choose a plan" instead.
  static MembershipLockCopy forMembership(
    Membership? membership,
    List<MembershipPlan>? plans,
  ) {
    final state = membership?.state ?? MembershipState.trialAvailable;
    if (state == MembershipState.trialAvailable &&
        !offersTrial(membership, plans)) {
      return forState(MembershipState.subscribeOnly);
    }
    return forState(state);
  }

  static MembershipLockCopy forState(MembershipState state) {
    switch (state) {
      case MembershipState.trialAvailable:
        return MembershipLockCopy(
          title: 'Start free trial',
          body: 'Your program is saved. Start the free trial to train, log '
              'sessions and track progress.',
          cta: (plans) => trialCta(plans),
          sub: (_) => r'$0.00 today · cancel anytime',
        );
      case MembershipState.subscribeOnly:
        return MembershipLockCopy(
          title: 'Choose a plan',
          body: 'Your program is saved. Subscribe to train, log sessions and '
              'track progress.',
          cta: (plans) => subscribeCta('Subscribe', plans),
          sub: (plans) => alternativeSub(plans),
        );
      case MembershipState.trialEnded:
        return MembershipLockCopy(
          title: 'Your free trial has ended',
          body: 'Everything you logged is saved. Subscribe to keep training '
              'and tracking progress.',
          cta: (plans) => subscribeCta('Subscribe', plans),
          sub: (plans) => alternativeSub(plans),
        );
      case MembershipState.lapsed:
        return MembershipLockCopy(
          title: 'Your plan is no longer active',
          body: 'Your program and history are safe. Resume your plan to pick '
              'up where you left off.',
          cta: (plans) => subscribeCta('Resume plan', plans),
          sub: (plans) => alternativeSub(plans),
        );
      case MembershipState.trialing:
      case MembershipState.subscribed:
      case MembershipState.complimentary:
        // Never locked; the dock is not shown. Kept total for the switch.
        return MembershipLockCopy(
          title: '',
          body: '',
          cta: (_) => '',
          sub: (_) => '',
        );
    }
  }

  /// "Start 7-day free trial", with the length read off the store's intro
  /// offer once the plans are in.
  static String trialCta(List<MembershipPlan>? plans) {
    final days = trialDays(plans);
    return days > 0 ? 'Start $days-day free trial' : 'Start free trial';
  }

  /// "Subscribe · $9.99 / month" — leads with the monthly price, the
  /// smaller number.
  static String subscribeCta(String verb, List<MembershipPlan>? plans) {
    final monthly = monthlyPlan(plans);
    return monthly == null ? verb : '$verb · ${monthly.priceString} / month';
  }

  /// "or $49.99 / year · cancel anytime"
  static String alternativeSub(List<MembershipPlan>? plans) {
    final yearly = yearlyPlan(plans);
    return yearly == null
        ? 'Cancel anytime'
        : 'or ${yearly.priceString} / year · cancel anytime';
  }

  /// "$0.00 today · then from $4.17/mo · cancel anytime" — the line under
  /// the Program Ready screen's trial button.
  static String trialTerms(List<MembershipPlan>? plans) {
    final from = fromMonthly(plans);
    return from == null
        ? r'$0.00 today · cancel anytime'
        : '\$0.00 today · then from $from/mo · cancel anytime';
  }

  /// The cheapest monthly rate across the plans — the yearly plan's
  /// per-month equivalent when it is on sale.
  static String? fromMonthly(List<MembershipPlan>? plans) {
    final yearly = yearlyPlan(plans);
    if (yearly?.monthlyEquivalentString != null) {
      return yearly!.monthlyEquivalentString;
    }
    return monthlyPlan(plans)?.priceString;
  }

  static MembershipPlan? yearlyPlan(List<MembershipPlan>? plans) =>
      plans?.where((plan) => plan.isYearly).firstOrNull;

  static MembershipPlan? monthlyPlan(List<MembershipPlan>? plans) =>
      plans?.where((plan) => !plan.isYearly).firstOrNull;

  /// The trial length the plans carry, 0 when none does or they have not
  /// loaded.
  static int trialDays(List<MembershipPlan>? plans) {
    if (plans == null) return 0;
    var days = 0;
    for (final plan in plans) {
      if (plan.trialDays > days) days = plan.trialDays;
    }
    return days;
  }

  /// "Save 58%" — the yearly plan against twelve months of monthly.
  static int? yearlySavingsPercent(List<MembershipPlan>? plans) {
    final yearly = yearlyPlan(plans);
    final monthly = monthlyPlan(plans);
    if (yearly == null || monthly == null || monthly.price <= 0) return null;
    final saving = 1 - yearly.price / (monthly.price * 12);
    if (saving <= 0) return null;
    return (saving * 100).round();
  }
}
