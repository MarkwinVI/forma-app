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

  testWidgets('draws the map, centred under its title, and nothing else',
      (tester) async {
    await pump(tester, service: await service(), onDone: () {});

    expect(find.text('Your plan is ready'), findsOneWidget);
    expect(
      find.text('Every dot is an exercise. Master one and the next unlocks.'),
      findsOneWidget,
    );
    expect(find.textContaining('days a week'), findsNothing);
    expect(find.text('AVAILABLE'), findsOneWidget);
    expect(find.text('UP NEXT'), findsNothing);
    expect(find.byType(SkillWheel), findsOneWidget);

    // No list of starting exercises under the map.
    expect(find.text('WHERE YOU START'), findsNothing);
    expect(find.text('Pullups step 1'), findsNothing);
    expect(find.text('Pushups step 0'), findsNothing);

    // The wheel sits in the middle of the page across, and the wheel with
    // its legend in the middle of the space between the title and the dock.
    final wheel = tester.getRect(find.byType(SkillWheel));
    expect(wheel.center.dx, moreOrLessEquals(393 / 2, epsilon: 1));
    final space = tester.getRect(find.byType(SingleChildScrollView));
    final map = tester.getRect(
      find.ancestor(of: find.byType(SkillWheel), matching: find.byType(Column))
          .first,
    );
    expect(map.center.dy, moreOrLessEquals(space.center.dy, epsilon: 1));

    // The trial leads, with the store's own trial length.
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(find.textContaining(r'then from $4.17/mo'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('the map builds itself in on arrival, then stands whole',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = await service();

    SkillWheelController wheel() =>
        tester.widget<SkillWheel>(find.byType(SkillWheel)).controller!;

    await tester.pumpWidget(MaterialApp(
      home: ProgramReadyView(service: s, onDone: () {}, bundle: _bundle()),
    ));
    await tester.pump();
    // Still building: the reveal runs for two seconds from the first frame.
    expect(wheel().showsWholeOverview, isFalse);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(wheel().showsWholeOverview, isFalse);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(wheel().showsWholeOverview, isTrue);

    // Under Reduce Motion the map simply stands whole.
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ProgramReadyView(
          key: UniqueKey(),
          service: s,
          onDone: () {},
          bundle: _bundle(),
        ),
      ),
    ));
    await tester.pump();
    expect(wheel().showsWholeOverview, isTrue);
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
    // The ready view's own wheel, which stays in the tree (offstage) while
    // the full wheel covers it.
    SkillWheelController readyWheel() => tester
        .widget<SkillWheel>(find.descendant(
          of: find.byType(ProgramReadyView, skipOffstage: false),
          matching: find.byType(SkillWheel, skipOffstage: false),
        ))
        .controller!;

    expect(readyWheel().showsWholeOverview, isTrue);
    tester.semantics.tap(find.semantics.byLabel(RegExp('^Pushups,')));
    await settle();

    expect(find.byType(SkillWheelScreen), findsOneWidget);
    expect(find.text('Pushups'), findsWidgets);
    // Underneath, the ready view's wheel is already back on its whole map.
    // Animations pause under a covering page, so anything still on its way
    // — the tree names fading back in — would greet the user, on their
    // return, as a map not yet whole.
    expect(readyWheel().showsWholeOverview, isTrue);
    expect(find.text('Your plan is ready'), findsNothing);

    // Backing out of the tree lands straight on the ready view — no wheel
    // overview in between.
    await tester.tap(find.bySemanticsLabel('Back').first);
    await settle();
    expect(find.byType(SkillWheelScreen), findsNothing);
    expect(find.text('Your plan is ready'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    // The map is whole again — every tree on the overview, not the one that
    // was opened, still zoomed in.
    expect(familyNodes(tester, 'Pushups'), hasLength(1));
    expect(familyNodes(tester, 'Pullups'), hasLength(1));
    handle.dispose();
  });

  testWidgets(
      'a member sees the way on, not a plan — including one whose '
      'subscription lands while the screen is up', (tester) async {
    final gateway = FakePurchasesGateway();
    final s = MembershipService(gateway: gateway);
    await s.setup();
    await s.load('user');
    var done = 0;
    await pump(tester, service: s, onDone: () => done++);
    expect(find.text('Start 7-day free trial'), findsOneWidget);

    // The subscription carried over from a previous account arrives.
    gateway.emit(FakePurchasesGateway.activeAccount());
    await tester.pumpAndSettle();

    expect(find.text('Start 7-day free trial'), findsNothing);
    expect(find.text('Not now'), findsNothing);
    await tester.tap(find.text('Let’s go'));
    await tester.pump();
    expect(done, 1);
  });
}
