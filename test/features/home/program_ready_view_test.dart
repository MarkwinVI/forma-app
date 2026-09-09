import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/membership_model.dart';
import 'package:forma_app/data/models/skill_track_model.dart';
import 'package:forma_app/data/services/membership_service.dart';
import 'package:forma_app/features/home/program_ready_view.dart';
import 'package:forma_app/features/progress/skill_wheel_bundle.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel.dart';
import 'package:forma_app/features/progress/widgets/skill_wheel_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_purchases_gateway.dart';

WheelFamily _family(
  String id,
  String title, {
  required List<WheelNodeState> trunk,
}) {
  return WheelFamily(
    categoryId: id,
    title: title,
    trunk: [
      for (var i = 0; i < trunk.length; i++)
        WheelNode(
          exerciseId: '$id-$i',
          name: '$title step $i',
          state: trunk[i],
        ),
    ],
    branches: const [],
  );
}

SkillWheelBundle _bundle() => SkillWheelBundle(
      progressMap: const {},
      progressEntries: const {},
      // The running trees, the way the app reads them off the tracks.
      skillTracks: [
        for (final id in ['a', 'b'])
          SkillTrack(
            skillCategoryId: id,
            branchId: 'default',
            included: true,
            updatedAt: DateTime(2026, 9, 7),
          ),
      ],
      logicSnapshot: null,
      pastWorkouts: const [],
      families: [
        _family('a', 'Pullups', trunk: [
          WheelNodeState.mastered,
          WheelNodeState.active,
          WheelNodeState.locked,
        ]),
        _family('b', 'Pushups', trunk: [
          WheelNodeState.active,
          WheelNodeState.locked,
        ]),
        _family('c', 'Squat', trunk: [
          WheelNodeState.locked,
          WheelNodeState.locked,
        ]),
      ],
      journeyByCategory: const {},
      performance: null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // The service follows the auth session, so a (never signed-in)
    // Supabase has to exist.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<MembershipService> service({StoreAccount? account}) async {
    final s = MembershipService(
      gateway: FakePurchasesGateway(account: account ?? StoreAccount.empty),
    );
    await s.setup();
    await s.load('user');
    return s;
  }

  Future<void> pump(
    WidgetTester tester, {
    required MembershipService service,
    required VoidCallback onDone,
  }) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: ProgramReadyView(
        service: service,
        onDone: onDone,
        bundle: _bundle(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  // Wheel families are painter semantics, so only the semantics tree sees
  // them.
  Iterable<SemanticsNode> familyNodes(WidgetTester tester, String title) =>
      find.semantics.byLabel(RegExp('^$title,')).evaluate();

  testWidgets(
      'draws the map and lists where each running tree starts and what '
      'comes next', (tester) async {
    await pump(tester, service: await service(), onDone: () {});

    expect(find.text('Program ready'), findsOneWidget);
    // The title stands alone: no eyebrow above it, no line under it.
    expect(find.text('PROGRAM READY'), findsNothing);
    expect(find.textContaining('days a week'), findsNothing);
    expect(find.text('AVAILABLE'), findsOneWidget);
    expect(find.text('UP NEXT'), findsNothing);
    expect(find.byType(SkillWheel), findsOneWidget);

    expect(find.text('WHERE YOU START'), findsOneWidget);
    expect(find.text('Pullups step 1'), findsOneWidget);
    expect(find.text('Pushups step 0'), findsOneWidget);
    // Only the starting step of each running tree — no "next" column, and
    // an idle tree is not a starting point.
    expect(find.text('NEXT UNLOCK'), findsNothing);
    expect(find.text('Pullups step 2'), findsNothing);
    expect(find.textContaining('Squat step'), findsNothing);

    // The trial leads, with the store's own trial length.
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(find.textContaining(r'then from $4.17/mo'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('"Not now" leaves the wizard', (tester) async {
    var done = 0;
    await pump(tester, service: await service(), onDone: () => done++);
    await tester.tap(find.text('Not now'));
    await tester.pump();
    expect(done, 1);
  });

  testWidgets('without a trial to offer, the button says subscribe',
      (tester) async {
    final s = await service(
      account: const StoreAccount(subscriptions: [], trialEligible: false),
    );
    await pump(tester, service: s, onDone: () {});
    expect(find.text(r'Subscribe · $9.99 / month'), findsOneWidget);
    expect(find.textContaining('free trial'), findsNothing);
  });

  testWidgets(
      'tapping a tree opens the full wheel flown into it, and back returns '
      'here', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, service: await service(), onDone: () {});

    // The wheel's fly-in keeps animating, so fixed pumps stand in for
    // pumpAndSettle throughout.
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    expect(familyNodes(tester, 'Pushups'), hasLength(1));
    tester.semantics.tap(find.semantics.byLabel(RegExp('^Pushups,')));
    await settle();

    expect(find.byType(SkillWheelScreen), findsOneWidget);
    expect(find.text('Pushups'), findsWidgets);
    expect(find.text('Program ready'), findsNothing);

    // Backing out of the tree lands straight on the ready view — no wheel
    // overview in between.
    await tester.tap(find.bySemanticsLabel('Back').first);
    await settle();
    expect(find.byType(SkillWheelScreen), findsNothing);
    expect(find.text('Program ready'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    handle.dispose();
  });
}
