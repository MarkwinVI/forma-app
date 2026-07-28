import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/features/login/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  testWidgets('the sign-in screen keeps animating without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    expect(find.text('FORMA'), findsOneWidget);
    expect(find.textContaining('Level up'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Track progress'), findsOneWidget);

    // The hero loops forever, so drive it through a full run: a frame that
    // throws while painting fails here rather than on a device.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
