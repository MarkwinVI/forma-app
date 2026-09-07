/// Public pages the app links out to.
class AppLinks {
  AppLinks._();

  static final Uri terms = Uri.parse('https://tryforma.co/terms');
  static final Uri privacy = Uri.parse('https://tryforma.co/privacy');

  /// Apple's subscription management page — where plan changes and
  /// cancellation happen.
  static final Uri manageSubscriptions =
      Uri.parse('https://apps.apple.com/account/subscriptions');
}
