import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/services/feedback_service.dart';
import 'package:forma_app/features/data/support_screens.dart';

/// The Profile tab's two support screens, full screen with an X on the
/// left. Feedback needs a star before it can send and names the rating in
/// a word; Contact needs a first character. Both swap the form for a
/// thanks on the same screen, keep the draft when closed or when the send
/// fails, and clear it once it has gone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpOpener(
      WidgetTester tester, Future<void> Function(BuildContext) open) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => open(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await settle(tester);
  }

  group('feedback', () {
    testWidgets('needs a star, names it, sends the note, then thanks',
        (tester) async {
      final store = FakeStore();
      final draft = FeedbackDraft();
      int? result;
      await pumpOpener(tester, (context) async {
        result = await showFeedbackScreen(context, draft: draft, store: store);
      });

      expect(find.text('Leave feedback'), findsOneWidget);
      expect(find.text('TAP TO RATE'), findsOneWidget);
      // Disabled until a star is picked.
      await tester.tap(find.text('Send feedback'));
      await settle(tester);
      expect(store.feedback, isEmpty);

      await tester.tap(find.bySemanticsLabel('4 stars'));
      await tester.pump();
      expect(find.text('GOOD'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Reorder exercises.');
      await tester.tap(find.text('Send feedback'));
      await settle(tester);

      expect(store.feedback.single.rating, 4);
      expect(store.feedback.single.note, 'Reorder exercises.');
      expect(find.text('Thanks for your feedback!'), findsOneWidget);
      // One heading at a time: the thanks takes the title's place.
      expect(find.text('Leave feedback'), findsNothing);
      // Sent: the draft is spent.
      expect(draft.rating, 0);
      expect(draft.text, '');

      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(result, 4);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('closing keeps the draft for next time', (tester) async {
      final draft = FeedbackDraft();
      await pumpOpener(tester, (context) async {
        await showFeedbackScreen(context, draft: draft, store: FakeStore());
      });
      await tester.tap(find.bySemanticsLabel('2 stars'));
      await tester.enterText(find.byType(TextField), 'Half typed');
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(draft.rating, 2);
      expect(draft.text, 'Half typed');

      // And it comes back filled.
      await tester.tap(find.text('Open'));
      await settle(tester);
      expect(find.text('FAIR'), findsOneWidget);
      expect(find.text('Half typed'), findsOneWidget);
    });

    testWidgets('a failed send says so and keeps everything', (tester) async {
      final store = FakeStore()..failNext = true;
      await pumpOpener(tester, (context) async {
        await showFeedbackScreen(context, draft: FeedbackDraft(), store: store);
      });
      await tester.tap(find.bySemanticsLabel('5 stars'));
      await tester.enterText(find.byType(TextField), 'Love it');
      await tester.tap(find.text('Send feedback'));
      await settle(tester);

      expect(find.text("Couldn't send. Try again."), findsOneWidget);
      expect(find.text('GREAT'), findsOneWidget);
      expect(find.text('Love it'), findsOneWidget);
      expect(find.text('Send feedback'), findsOneWidget);
    });
  });

  group('contact support', () {
    testWidgets('needs text, sends it, thanks with the reply window',
        (tester) async {
      final store = FakeStore();
      final draft = SupportDraft();
      bool? result;
      await pumpOpener(tester, (context) async {
        result = await showContactSupportScreen(
          context,
          draft: draft,
          store: store,
        );
      });

      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('We usually reply within 1–2 business days.'),
          findsOneWidget);
      await tester.tap(find.text('Send message'));
      await settle(tester);
      expect(store.messages, isEmpty);

      await tester.enterText(find.byType(TextField), '  My timer stopped.  ');
      await tester.pump();
      await tester.tap(find.text('Send message'));
      await settle(tester);

      expect(store.messages.single, 'My timer stopped.');
      expect(find.text('Thanks for contacting us'), findsOneWidget);
      expect(find.textContaining('1–2 business days'), findsOneWidget);
      expect(draft.text, '');

      await tester.tap(find.text('Done'));
      await settle(tester);
      expect(result, isTrue);
    });

    testWidgets('a failed send keeps the message', (tester) async {
      final store = FakeStore()..failNext = true;
      final draft = SupportDraft();
      await pumpOpener(tester, (context) async {
        await showContactSupportScreen(
          context,
          draft: draft,
          store: store,
        );
      });
      await tester.enterText(find.byType(TextField), 'Charged twice');
      await tester.pump();
      await tester.tap(find.text('Send message'));
      await settle(tester);

      expect(find.text("Couldn't send. Try again."), findsOneWidget);
      expect(find.text('Charged twice'), findsOneWidget);
      expect(draft.text, 'Charged twice');
    });
  });
}

class FeedbackCall {
  final int rating;
  final String? note;
  FeedbackCall(this.rating, this.note);
}

class FakeStore implements ProfileFeedbackStore {
  final feedback = <FeedbackCall>[];
  final messages = <String>[];
  bool failNext = false;

  @override
  Future<void> sendAppFeedback(
      {required int rating, required String? note}) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    feedback.add(FeedbackCall(rating, note));
  }

  @override
  Future<void> sendSupportMessage(String message) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    messages.add(message);
  }
}
