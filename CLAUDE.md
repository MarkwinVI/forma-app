# Forma

## Version bumps

The version is `name+build` in `pubspec.yaml` (e.g. `1.1.2+9`). A bump
touches three places, and only the first is the source of truth:

1. `pubspec.yaml` — `version: X.Y.Z+N`. Raise the build number `N` as
   well as the name: App Store Connect rejects an upload that reuses a
   build number it has already seen.
2. `ios/Runner.xcodeproj/project.pbxproj` — the three `MARKETING_VERSION`
   lines on the Runner target, kept equal to `X.Y.Z` so Xcode's Version
   field agrees. Display only: `Info.plist` does not read it.
3. `ios/Flutter/Generated.xcconfig` — what the shipped app reads
   (`Info.plist` points `CFBundleShortVersionString` and `CFBundleVersion`
   at `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`). Gitignored, and
   refreshed only by a Flutter build, not by `flutter pub get`. After
   bumping, run

   ```bash
   flutter build ios --config-only --no-codesign
   ```

   or a build started from Xcode alone ships the previous version.

`android/local.properties` is the Android equivalent of step 3;
`flutter build appbundle` regenerates it.

Commit the bump as `Version X.Y.Z+N: <what it ships>`.
