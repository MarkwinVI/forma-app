// Throwaway harness: boots straight into an exercise detail view so the
// demo player can be exercised on a simulator without signing in.
//
//   flutter run -t lib/dev_video_probe_main.dart
//
// Not part of the app. Delete freely.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'data/catalog/exercise_catalog.dart';
import 'features/exercises/exercise_detail_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fake instance: history calls fail into their error cards, which is fine —
  // the subject here is the video player, which never touches the backend.
  await Supabase.initialize(
    url: 'https://example.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwicm9sZSI6ImFub24iLCJpYXQiOjE1MTYyMzkwMjJ9.c2lnbmVk',
  );
  runApp(const _ProbeApp());
}

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: ExerciseDetailView(
        exercise: ExerciseCatalog.findById('pullups_wide_grip_pull_up')!,
      ),
    );
  }
}
