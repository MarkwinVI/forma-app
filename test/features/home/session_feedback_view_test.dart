import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/services/feedback_service.dart';
import 'package:forma_app/features/home/session_feedback_view.dart';

/// The session rating closes every workout. A thumb is written the moment
/// it is tapped and opens its reasons; Send writes the reasons and leaves;
/// closing early keeps the thumb; Skip with no thumb records nothing. A
/// thumbs-down that names wrong exercises asks which ones. Every way out
/// lands back on the first route — the tab shell.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A thumb is outlined until it is the chosen one, then filled.
  Finder thumbsUp() => find.byWidgetPredicate((w) =>
      w is Icon &&
      (w.icon == Icons.thumb_up_outlined || w.icon == Icons.thumb_up_rounded));
  Finder thumbsDown() => find.byWidgetPredicate((w) =>
      w is Icon &&
      (w.icon == Icons.thumb_down_outlined ||
          w.icon == Icons.thumb_down_rounded));

  List<Exercise> exercises() => [
        ExerciseCatalog.findById('pullups_scapular_pull')!,
        ExerciseCatalog.findById('dead_hang')!,
        // Done twice in one session: still one chip.
        ExerciseCatalog.findById('dead_hang')!,
      ];

  Future<void> pumpOverShell(
    WidgetTester tester,
    FakeStore store, {
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SessionFeedbackView(
                      workoutSessionId: 'session-1',
                      exercises: exercises(),
                      store: store,
                    ),
                  ),
                ),
                child: const Text('shell'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('shell'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the question, two thumbs and Skip only',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    expect(find.text('How was this session?'), findsOneWidget);
    expect(thumbsUp(), findsOneWidget);
    expect(thumbsDown(), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Send'), findsNothing);
    expect(find.textContaining('PICK ANY'), findsNothing);
  });

  testWidgets('the question rests mid-screen and rises when a thumb is tapped',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    final screen = tester.getSize(find.byType(SessionFeedbackView));
    final question = find.text('How was this session?');
    final thumbs = thumbsDown();
    final restingMiddle =
        (tester.getTopLeft(question).dy + tester.getBottomRight(thumbs).dy) / 2;
    // The block's centre sits within a few points of the screen's.
    expect(restingMiddle, closeTo(screen.height / 2, 24));

    await tester.tap(thumbsUp());
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(question).dy, lessThan(screen.height / 4));
  });

  testWidgets('Skip records nothing and returns to the shell', (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(store.calls, isEmpty);
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('a thumbs up is written at once and opens its reasons',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsUp());
    await tester.pumpAndSettle();

    expect(store.calls, hasLength(1));
    expect(store.calls.single.sentiment, FeedbackSentiment.up);
    expect(store.calls.single.id, isNull);
    expect(store.calls.single.workoutSessionId, 'session-1');
    expect(store.calls.single.tags, isEmpty);

    expect(find.text('WHAT WORKED WELL? (PICK ANY)'), findsOneWidget);
    expect(find.text('Right difficulty'), findsOneWidget);
    expect(find.text('Making progress'), findsOneWidget);
    expect(find.text('Rest times felt right'), findsNothing);
    expect(find.text('Good variety'), findsNothing);
    expect(find.text('Add a note (optional)'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    // Nothing picked yet, so the button only closes.
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Send updates the same row with the picked reasons and leaves',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsUp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Right difficulty'));
    await tester.tap(find.text('Making progress'));
    await tester.pump();
    expect(find.text('Send'), findsOneWidget);

    await tester.enterText(
        find.byType(TextField), 'Rest timer could be adjustable.');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(store.calls, hasLength(2));
    final sent = store.calls.last;
    expect(sent.id, 'row-1');
    expect(sent.sentiment, FeedbackSentiment.up);
    expect(sent.tags, ['right_difficulty', 'making_progress']);
    expect(sent.flaggedExerciseIds, isEmpty);
    expect(sent.note, 'Rest timer could be adjustable.');
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('thumbs down asks which exercises only for "Wrong exercises"',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsDown());
    await tester.pumpAndSettle();

    expect(find.text('WHAT WENT WRONG? (PICK ANY)'), findsOneWidget);
    expect(find.text('Too hard'), findsOneWidget);
    expect(find.text('WHICH ONES? (TAP ANY)'), findsNothing);

    await tester.tap(find.text('Wrong exercises'));
    await tester.pumpAndSettle();

    expect(find.text('WHICH ONES? (TAP ANY)'), findsOneWidget);
    expect(find.text(exercises().first.name), findsOneWidget);
    expect(find.text('Dead Hang'), findsOneWidget);

    await tester.tap(find.text('Dead Hang'));
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    final sent = store.calls.last;
    expect(sent.sentiment, FeedbackSentiment.down);
    expect(sent.tags, ['wrong_exercises']);
    expect(sent.flaggedExerciseIds, ['dead_hang']);
    expect(sent.note, '');
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('dropping "Wrong exercises" hides the chips and their flags',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsDown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrong exercises'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dead Hang'));
    await tester.tap(find.text('Wrong exercises'));
    await tester.pumpAndSettle();

    expect(find.text('WHICH ONES? (TAP ANY)'), findsNothing);
    await tester.tap(find.text('Too hard'));
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(store.calls.last.tags, ['too_hard']);
    expect(store.calls.last.flaggedExerciseIds, isEmpty);
  });

  testWidgets('changing thumbs starts the reasons over', (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsDown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Too hard'));
    await tester.pump();
    await tester.tap(thumbsUp());
    await tester.pumpAndSettle();

    expect(find.text('WHAT WORKED WELL? (PICK ANY)'), findsOneWidget);
    expect(find.text('Too hard'), findsNothing);
    expect(find.text('Done'), findsOneWidget);

    expect(store.calls, hasLength(2));
    expect(store.calls.last.id, 'row-1');
    expect(store.calls.last.sentiment, FeedbackSentiment.up);
    expect(store.calls.last.tags, isEmpty);
  });

  testWidgets('closing after a thumb keeps the thumb and what was picked',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsDown());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Too easy'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('shell'), findsOneWidget);
    expect(store.calls, hasLength(2));
    expect(store.calls.last.id, 'row-1');
    expect(store.calls.last.tags, ['too_easy']);
  });

  testWidgets('a failed send stays put with an error and can be retried',
      (tester) async {
    final store = FakeStore()..failNext = true;
    await pumpOverShell(tester, store);

    await tester.tap(thumbsUp());
    await tester.pumpAndSettle();
    // The thumb write failed quietly: no row yet.
    expect(store.calls, hasLength(1));

    store.failNext = true;
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't send. Try again."), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('shell'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Both earlier writes failed, so this one inserts.
    expect(store.calls.last.id, isNull);
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('the keyboard never covers the note: it scrolls up above Send',
      (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store);

    await tester.tap(thumbsDown());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    // The keyboard arrives over a few frames, as on a device.
    for (final inset in [300.0, 600.0, 900.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump();
      await tester.pump();
    }

    final noteBottom = tester.getBottomRight(find.byType(TextField)).dy;
    final buttonTop = tester.getTopLeft(find.text('Done')).dy;
    final screenBottom =
        tester.getSize(find.byType(SessionFeedbackView)).height;
    expect(noteBottom, lessThan(buttonTop));
    // The button itself sits above the keyboard.
    expect(buttonTop, lessThan(screenBottom - 300));

    // A tap on the background puts the keyboard away.
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
    await tester.tapAt(const Offset(200, 60));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isFalse);
  });

  testWidgets('under Reduce Motion the reasons appear at once', (tester) async {
    final store = FakeStore();
    await pumpOverShell(tester, store, reduceMotion: true);

    await tester.tap(thumbsUp());
    await tester.pump();

    expect(find.text('WHAT WORKED WELL? (PICK ANY)'), findsOneWidget);
  });
}

class SaveCall {
  final String? id;
  final String? workoutSessionId;
  final FeedbackSentiment sentiment;
  final List<String> tags;
  final List<String> flaggedExerciseIds;
  final String? note;

  SaveCall({
    required this.id,
    required this.workoutSessionId,
    required this.sentiment,
    required this.tags,
    required this.flaggedExerciseIds,
    required this.note,
  });
}

class FakeStore implements SessionFeedbackStore {
  final calls = <SaveCall>[];
  bool failNext = false;
  var _nextRow = 1;

  @override
  Future<String> save({
    required String? id,
    required String? workoutSessionId,
    required FeedbackSentiment sentiment,
    required List<String> tags,
    required List<String> flaggedExerciseIds,
    required String? note,
  }) async {
    calls.add(SaveCall(
      id: id,
      workoutSessionId: workoutSessionId,
      sentiment: sentiment,
      tags: tags,
      flaggedExerciseIds: flaggedExerciseIds,
      note: note,
    ));
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    return id ?? 'row-${_nextRow++}';
  }
}
