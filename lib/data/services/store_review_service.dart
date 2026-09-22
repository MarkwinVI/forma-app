import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'feedback_service.dart';

/// The native store review prompt, behind an interface so a test can see
/// whether it would have been asked for.
abstract class ReviewRequester {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class _InAppReviewRequester implements ReviewRequester {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// Asks for a store rating in place, right after a five-star piece of
/// feedback — the one moment we know the answer is yes. At most once per
/// app version; the stores quota the prompt beyond that anyway, and a
/// prompt that fires too often is the fastest way to a one-star review.
class StoreReviewService {
  static const _askedVersionKey = 'store_review_asked_version';

  final ReviewRequester _requester;
  final Future<SharedPreferences> _prefs;

  StoreReviewService({
    ReviewRequester? requester,
    Future<SharedPreferences>? prefs,
  })  : _requester = requester ?? _InAppReviewRequester(),
        _prefs = prefs ?? SharedPreferences.getInstance();

  /// Prompts when [rating] is five stars and this app version has not asked
  /// before. Returns whether the prompt was requested. Never throws: a
  /// rating that could not be asked for is not worth a crash.
  Future<bool> maybeAsk({required int rating}) async {
    if (rating < 5) return false;
    try {
      final prefs = await _prefs;
      final version =
          (await FeedbackDiagnostics.collect()).appVersion ?? 'unknown';
      if (prefs.getString(_askedVersionKey) == version) return false;
      if (!await _requester.isAvailable()) return false;
      await prefs.setString(_askedVersionKey, version);
      await _requester.requestReview();
      AnalyticsService.capture('store_review_prompted', properties: {
        'app_version': version,
      });
      return true;
    } catch (error) {
      debugPrint('Store review prompt failed: $error');
      return false;
    }
  }
}
