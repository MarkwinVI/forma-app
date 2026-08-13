// Regenerates both halves of the exercise catalogue from the two sheets in
// data/. Run it after either sheet changes:
//
//   dart run tool/generate_catalogs.dart
//
// The library sheet is the movements: what each one is called, how it is
// performed, what it trains and what it is measured in. The skill-tree sheet
// is the shape of the trees — which node follows which, what each node is
// called, and what load it asks for — and each node names the movement it is
// performed with in its `Excercise id` column. Everything else about a node
// comes from that movement.
//
// Nothing here is invented: every field is a column, or a stated rule over
// one. Only the data inside each file is written; the imports, the header and
// the lookups the app calls are left exactly as they are.
//
// The test `catalogs match the sheets` runs the same code and fails when a
// committed catalogue has drifted from data/, so a sheet edit cannot be
// half-applied.

import 'dart:io';

import 'package:forma_app/data/models/exercise_model.dart';

const libraryCsvPath = 'data/exercise_library.csv';
const treeCsvPath = 'data/skill_trees_source.csv';
const stepCatalogPath = 'lib/data/catalog/exercise_catalog.dart';
const libraryCatalogPath = 'lib/data/catalog/exercise_library_catalog.dart';

/// Movement plane → the pattern a tree can be built on. Everything that is
/// isolation, power, carry or conditioning is `other`: real training, but not
/// a pattern.
const _categoryForPlane = <String, String>{
  'vertical_pull': 'verticalPull',
  'vertical_push': 'verticalPush',
  'horizontal_pull': 'horizontalPull',
  'horizontal_push': 'horizontalPush',
  'squat': 'squat',
  'lunge': 'squat',
  'hinge': 'hinge',
  'core_flexion': 'core',
  'core_anti_extension': 'core',
  'core_rotation': 'core',
};

const _sectionForWorkoutSection = <String, String>{
  'skill work': 'skillWork',
  'warmup/cooldown': 'warmup',
  'stretching': 'coolDown',
  // 'strength' is the default the model already carries.
};

/// A movement with no harder variation waiting: it is never mastered, and the
/// only way on is more reps and then more load, which the user approves. Not
/// a column in either sheet — it is what the app does with a lift, so it is
/// stated here rather than guessed from the name. Only the legacy one-lift
/// squat tree still works this way; every current tree climbs rungs instead.
const _openEndedNodes = <String>{
  'barbell_squat_barbell_squat',
};

/// The library is outside the progressions, so every movement in it is
/// open-ended, and none of them is a rung with a difficulty or a place in a
/// tree. The sheet has no column for any of that.
const _libraryDifficulty = 3;

void main(List<String> args) {
  final files = generatedCatalogs();
  files.forEach((path, contents) {
    File(path).writeAsStringSync(contents);
    stdout.writeln('Wrote $path');
  });
}

/// What each catalogue file should contain, given the sheets. `main` writes
/// these; the drift test compares them against what is committed.
Map<String, String> generatedCatalogs({String prefix = ''}) {
  final library = {
    for (final row in readCsv(File('$prefix$libraryCsvPath').readAsStringSync()))
      row['id']!.trim(): row,
  };
  final nodes = readCsv(File('$prefix$treeCsvPath').readAsStringSync())
      .where((row) => row['Node_id']!.trim().isNotEmpty)
      .toList();

  return {
    '$prefix$stepCatalogPath': _splice(
      File('$prefix$stepCatalogPath').readAsStringSync(),
      {'static const List<Exercise> _all = [': _steps(nodes, library)},
    ),
    '$prefix$libraryCatalogPath': _splice(
      File('$prefix$libraryCatalogPath').readAsStringSync(),
      {
        'static const List<Exercise> _all = [': _movements(library.values),
        'static const Map<String, ExerciseCoaching> _coaching = {':
            _coaching(library.values),
      },
    ),
  };
}

String _steps(
  List<Map<String, String>> nodes,
  Map<String, Map<String, String>> library,
) {
  final previous = {
    for (final node in nodes)
      node['Node_id']!.trim(): node['Previous Node_id']!.trim(),
  };
  final buffer = StringBuffer();

  for (final node in nodes) {
    final id = node['Node_id']!.trim();
    final movementId = node['Excercise id']!.trim();
    final movement = library[movementId];
    if (movement == null) {
      throw StateError('$id references unknown exercise id "$movementId"');
    }

    final type = _type(movement);
    final section = _section(movement);
    final weightFormula = node['(Optional) weight setting']!.trim();
    final prerequisite = previous[id]!;

    buffer
      ..writeln('    Exercise(')
      ..writeln("      id: '$id',")
      ..writeln('      category: ExerciseCategory.${_category(movement)},')
      ..writeln("      skillCategoryId: '${node['Skill tree ID']!.trim()}',")
      ..writeln("      branchId: '${node['Branch']!.trim()}',")
      ..writeln('      name: ${dartString(node['Node name']!.trim())},')
      ..writeln('      description: ${dartString(description(movement))},')
      ..writeln("      difficulty: ${node['Difficulty']!.trim()},")
      ..writeln('      treeOrder: ${_depth(id, previous)},');
    if (prerequisite.isNotEmpty) {
      buffer.writeln("      prerequisiteIds: ['$prerequisite'],");
    }
    if (section != null) {
      buffer.writeln('      programSection: ExerciseProgramSection.$section,');
    }
    buffer
      ..write(_muscleLists(movement))
      ..writeln("      libraryId: '$movementId',");
    if (type.startsWith('timed')) buffer.writeln('      isTimed: true,');
    if (_openEndedNodes.contains(id)) buffer.writeln('      isLoaded: true,');
    if (type.contains('weight')) buffer.writeln('      isWeighted: true,');
    if (weightFormula.isNotEmpty) {
      buffer.writeln('      weightFormula: ${dartString(weightFormula)},');
    }
    buffer.writeln('    ),');
  }
  return buffer.toString();
}

String _movements(Iterable<Map<String, String>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    final type = _type(row);
    final section = _section(row);

    buffer
      ..writeln('    Exercise(')
      ..writeln("      id: '${row['id']!.trim()}',")
      ..writeln('      category: ExerciseCategory.${_category(row)},')
      ..writeln('      name: ${dartString(row['Name']!.trim())},')
      ..writeln('      description: ${dartString(description(row))},')
      ..writeln('      difficulty: $_libraryDifficulty,')
      ..writeln('      treeOrder: 0,')
      ..writeln('      isLibrary: true,');
    if (section != null) {
      buffer.writeln('      programSection: ExerciseProgramSection.$section,');
    }
    buffer.write(_muscleLists(row));
    if (type.startsWith('timed')) buffer.writeln('      isTimed: true,');
    buffer.writeln('      isLoaded: true,');
    if (type.contains('weight')) buffer.writeln('      isWeighted: true,');
    buffer.writeln('    ),');
  }
  return buffer.toString();
}

/// How a movement is taught. Only movements the sheet has written a how-to
/// for get an entry; the rest fall back to their pattern's generic advice.
String _coaching(Iterable<Map<String, String>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    final howTo = _sentences(row['How to']!);
    if (howTo.isEmpty) continue;

    buffer
      ..writeln("    '${row['id']!.trim()}': ExerciseCoaching(")
      ..writeln('      howTo: [');
    for (final sentence in howTo) {
      buffer.writeln('        ${dartString(sentence)},');
    }
    buffer.writeln('      ],');

    buffer.writeln('      formChecks: [');
    for (final check in _formChecks(row['Form check']!)) {
      buffer.writeln('        ${dartString(check)},');
    }
    buffer
      ..writeln('      ],')
      ..writeln('      videoUrl: ${dartString(row['YT video']!.trim())},')
      ..writeln("      imageUrl: '',")
      ..writeln('    ),');
  }
  return buffer.toString();
}

/// The sheet spells the type header out in full, brackets and all, so it is
/// found by prefix rather than repeated here and left to rot.
String _type(Map<String, String> row) => row[
        row.keys.firstWhere((key) => key.startsWith('Excercise type'))]!
    .trim()
    .toLowerCase();

String _category(Map<String, String> row) =>
    _categoryForPlane[row['Movement plane id']!.trim()] ?? 'other';

String? _section(Map<String, String> row) =>
    _sectionForWorkoutSection[row['workout section']!.trim().toLowerCase()];

/// What an exercise says about itself in one line: the first sentence of its
/// how-to, or its name where the sheet has no how-to yet.
String description(Map<String, String> row) {
  final sentences = _sentences(row['How to']!);
  return sentences.isEmpty ? row['Name']!.trim() : sentences.first;
}

/// A how-to reads as a numbered list, one step per sentence.
List<String> _sentences(String text) {
  final howTo = text.trim();
  if (howTo.isEmpty) return const [];
  return RegExp(r'.*?[.!?](?=\s|$)|.+$', dotAll: true)
      .allMatches(howTo)
      .map((match) => match.group(0)!.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
}

/// Form checks are written as one line separated by middots, and the sheet
/// only capitalises the first — they are read as a list, so each one starts
/// like a line of its own.
List<String> _formChecks(String text) => text
    .split('·')
    .map((check) => check.trim())
    .where((check) => check.isNotEmpty)
    .map((check) => check[0].toUpperCase() + check.substring(1))
    .toList();

/// The two muscle columns, each spelled the one way [kExerciseMuscleGroups]
/// spells them — the sheet writes some in title case in one column and lower
/// case in the other, and the same muscle spelled twice would be two filters.
///
/// A muscle named in both columns is primary and is dropped from secondary:
/// the sheet says of a hyperextension that it works the lower back and also
/// the lower back, which is one fact.
String _muscleLists(Map<String, String> row) {
  final primary = _muscles(row['Muscles worked (primary)']!);
  final secondary = _muscles(row['Muscles worked (secondary)']!)
      .where((muscle) => !primary.contains(muscle))
      .toList();

  final buffer = StringBuffer();
  if (primary.isNotEmpty) {
    buffer.writeln('      primaryMuscles: ${_dartList(primary)},');
  }
  if (secondary.isNotEmpty) {
    buffer.writeln('      secondaryMuscles: ${_dartList(secondary)},');
  }
  return buffer.toString();
}

List<String> _muscles(String column) {
  final canonical = {
    for (final group in kExerciseMuscleGroups) group.toLowerCase(): group,
  };
  final muscles = <String>[];
  for (final raw in column.split(';')) {
    final muscle = raw.trim();
    if (muscle.isEmpty) continue;
    final spelling = canonical[muscle.toLowerCase()] ?? muscle;
    if (!muscles.contains(spelling)) muscles.add(spelling);
  }
  return muscles;
}

String _dartList(List<String> values) =>
    '[${values.map(dartString).join(', ')}]';

/// How many steps deep a node sits — the row it is drawn on, and the order a
/// path is walked in.
int _depth(String id, Map<String, String> previous) {
  var depth = 0;
  var current = id;
  while ((previous[current] ?? '').isNotEmpty) {
    current = previous[current]!;
    depth++;
  }
  return depth;
}

/// Replaces the body of each named collection, leaving everything around it.
String _splice(String source, Map<String, String> bodies) {
  var result = source;
  bodies.forEach((opening, body) {
    final start = result.indexOf(opening);
    if (start < 0) throw StateError('Could not find "$opening"');
    final closes = opening.endsWith('[') ? '\n  ];' : '\n  };';
    final end = result.indexOf(closes, start);
    if (end < 0) throw StateError('Could not find the end of "$opening"');
    result =
        '${result.substring(0, start + opening.length)}\n$body${result.substring(end)}';
  });
  return result;
}

String dartString(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

/// RFC 4180: quoted fields may hold commas, newlines and doubled quotes.
List<Map<String, String>> readCsv(String source) {
  final rows = <List<String>>[];
  var field = StringBuffer();
  var row = <String>[];
  var quoted = false;

  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }
    switch (char) {
      case '"':
        quoted = true;
      case ',':
        row.add(field.toString());
        field = StringBuffer();
      case '\r':
        break;
      case '\n':
        row.add(field.toString());
        field = StringBuffer();
        rows.add(row);
        row = <String>[];
      default:
        field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }

  final header = rows.first;
  return [
    for (final row in rows.skip(1))
      if (row.length >= header.length)
        {
          for (var i = 0; i < header.length; i++) header[i]: row[i],
        },
  ];
}
