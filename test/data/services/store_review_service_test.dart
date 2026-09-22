import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/services/store_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The store review prompt follows a five-star piece of feedback, once per
/// app version, and only where the platform offers it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('anything under five stars never asks', () async {
    final requester = FakeRequester();
    final service = StoreReviewService(requester: requester);
    for (final rating in [1, 2, 3, 4]) {
      expect(await service.maybeAsk(rating: rating), isFalse);
    }
    expect(requester.requests, 0);
  });

  test('five stars asks once, then not again on this version', () async {
    final requester = FakeRequester();
    final service = StoreReviewService(requester: requester);
    expect(await service.maybeAsk(rating: 5), isTrue);
    expect(await service.maybeAsk(rating: 5), isFalse);
    expect(requester.requests, 1);

    // A fresh service on the same install remembers.
    expect(await StoreReviewService(requester: requester).maybeAsk(rating: 5),
        isFalse);
    expect(requester.requests, 1);
  });

  test('a platform without the prompt is left alone, and asked later',
      () async {
    final requester = FakeRequester()..available = false;
    final service = StoreReviewService(requester: requester);
    expect(await service.maybeAsk(rating: 5), isFalse);
    expect(requester.requests, 0);

    requester.available = true;
    expect(await service.maybeAsk(rating: 5), isTrue);
  });
}

class FakeRequester implements ReviewRequester {
  bool available = true;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;
}
