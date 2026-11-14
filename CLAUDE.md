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

## Archiving after a simulator build

Flutter keeps the native-asset frameworks it builds for Dart packages
(today just `objective_c`, pulled in by `path_provider_foundation`) in
`build/native_assets/ios/`, and that cache is not keyed by SDK. After any
`flutter build ios --simulator` or `flutter run` on a simulator, the
cached framework is a simulator binary, and an Xcode archive embeds it as
is: App Store Connect then rejects the upload with "Invalid executable …
references an unsupported platform in the x86_64 slice" for
`Runner.app/Frameworks/objective_c.framework`. The opposite failure is
quieter: clearing only that folder leaves Flutter's install-code-assets
step stamped up to date in `.dart_tool/flutter_build/`, so the next build
does not write the framework back, the folder stays empty, and an archive
embeds no `objective_c` at all — which fails at runtime, not at upload.
Before archiving, run

```bash
rm -rf build/native_assets .dart_tool/flutter_build && flutter build ios --release --no-codesign
```

which rebuilds the framework for device (platform iOS, arm64 only) and
puts it back in the folder the archive copies from. Then check

```bash
otool -l build/native_assets/ios/objective_c.framework/objective_c | grep platform
```

prints `platform 2` only, and never start an Xcode archive while a
Flutter build is running: both write the same `build/` folder, and the
archive fails.

## Error reporting

Sentry (org `forma-rf`, project `forma`, EU region) receives uncaught
Flutter and Dart errors through `ErrorReportingService` in
`lib/data/services/error_reporting_service.dart`, which `main` runs first.
The DSN is a public key and lives in `AppConfig.sentryDsn`; the release is
the bundle id at the version and build (`tryforma.co@X.Y.Z+N` on iOS,
`co.tryforma.app@X.Y.Z+N` on Android) and the environment is `debug`,
`profile` or `production` by build mode, both set by the SDK. Tracing samples every run
in debug builds and one in ten in production. Reports carry the Supabase
user id and nothing else personal.

Native (Swift/ObjC) frames in a crash from a store build are readable only
after that build's dSYMs are uploaded. After the release build in the
archive recipe above, run

```bash
dart run sentry_dart_plugin
```

with `SENTRY_AUTH_TOKEN` set (or in a gitignored `sentry.properties`); the
plugin's settings are the `sentry:` block in `pubspec.yaml`. Dart frames
are readable without this as long as the build is not obfuscated.
