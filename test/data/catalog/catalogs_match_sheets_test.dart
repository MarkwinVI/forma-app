import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/generate_catalogs.dart';

/// The catalogues are generated from the sheets in data/, and generated files
/// only stay true if something checks. This runs the generator and compares
/// what it would write against what is committed, so editing a sheet without
/// regenerating — or editing a catalogue by hand — fails here rather than
/// silently shipping. It is the check that was missing when the sheet's
/// exercise-type column was dropped on an earlier rebuild.
///
/// Formatting is ignored: line breaks and trailing commas are `dart format`'s
/// business, not the sheets'.
void main() {
  test('the catalogues match the sheets they are generated from', () {
    generatedCatalogs().forEach((path, expected) {
      expect(
        _withoutFormatting(File(path).readAsStringSync()),
        _withoutFormatting(expected),
        reason: '$path has drifted from data/ — regenerate it with:\n'
            '  dart run tool/generate_catalogs.dart',
      );
    });
  });
}

String _withoutFormatting(String source) => source
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(',]', ']')
    .replaceAll(',}', '}')
    .replaceAll(',)', ')');
