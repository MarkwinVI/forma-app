import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/core/widgets/forma_splash.dart';
import 'package:forma_app/features/progress/progress_view.dart';
import 'package:forma_app/features/progress/skill_wheel_bundle.dart';
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

  testWidgets('waiting on the bundle holds the splash frame, not a spinner',
      (tester) async {
    // A warm-up still in flight: the tab has to wait for it.
    final pending = Completer<SkillWheelBundle>();
    debugWarmSkillWheelBundle(pending.future);
    addTearDown(() => takeWarmSkillWheelBundle());

    await tester.pumpWidget(
      const MaterialApp(home: ProgressView(isActive: true)),
    );
    await tester.pump();

    expect(find.byType(FormaSplash), findsOneWidget);
    expect(find.text('FORMA'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Held still: nothing is scheduled, so a long pump changes nothing.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(FormaSplash), findsOneWidget);
  });
}
