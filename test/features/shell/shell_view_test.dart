import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/app_nav_bar.dart';
import 'package:forma_app/features/progress/progress_view.dart';
import 'package:forma_app/features/shell/shell_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Each tab hosts its own navigator, so deeper pages keep the bottom bar
/// visible, the stack survives switching tabs, and tapping the tab you are
/// already on unwinds back to that tab's index page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Finder navItem(String label) => find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text(label),
      );

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ShellView()));
    // Landing-tab resolution (no signed-in user → Progress) plus a frame
    // for the tabs to appear.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pushDeepPage(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(ProgressView))).push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('deep page'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a page pushed inside a tab keeps the bottom bar visible',
      (tester) async {
    await pumpShell(tester);
    expect(find.byType(ProgressView), findsOneWidget);

    await pushDeepPage(tester);

    expect(find.text('deep page'), findsOneWidget);
    expect(navItem('Progress'), findsOneWidget);
    expect(navItem('Train'), findsOneWidget);
  });

  testWidgets('tapping the active tab while deeper returns to its index page',
      (tester) async {
    await pumpShell(tester);
    await pushDeepPage(tester);
    expect(find.text('deep page'), findsOneWidget);

    await tester.tap(navItem('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('deep page'), findsNothing);
    expect(find.byType(ProgressView), findsOneWidget);
  });

  testWidgets('switching tabs keeps the deeper stack for the way back',
      (tester) async {
    await pumpShell(tester);
    await pushDeepPage(tester);

    await tester.tap(navItem('Train'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Hidden with its tab, not popped.
    expect(find.text('deep page'), findsNothing);

    await tester.tap(navItem('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('deep page'), findsOneWidget);

    // And the re-tap still unwinds it.
    await tester.tap(navItem('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('deep page'), findsNothing);
  });
}
