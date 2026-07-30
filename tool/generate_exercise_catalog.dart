// Regenerates lib/data/catalog/exercise_catalog.dart from the two sheets in
// data/. Run it after either sheet changes:
//
//   dart run tool/generate_exercise_catalog.dart
//
// The skill-tree sheet is the shape of the trees — which node follows which,
// what each node is called, and what load it asks for. Everything else about
// a node comes from the movement it is performed with, named by its
// `Excercise id` column, which is a row of the library sheet. Nothing here is
// invented: every field is either a column or a stated rule over one.
//
// The library half of the catalogue is not written by this script.

import 'dart:io';

import 'package:forma_app/data/models/exercise_model.dart';

const _libraryCsv = 'data/exercise_library.csv';
const _treeCsv = 'data/skill_trees_source.csv';
const _output = 'lib/data/catalog/exercise_catalog.dart';

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
/// stated here rather than guessed from the name.
const _openEndedNodes = <String>{
  'barbell_squat_barbell_squat',
  'hinge_romanian_deadlift',
};

void main() {
  final library = {
    for (final row in _readCsv(File(_libraryCsv).readAsStringSync()))
      row['id']!.trim(): row,
  };
  final nodes = _readCsv(File(_treeCsv).readAsStringSync())
      .where((row) => row['Node_id']!.trim().isNotEmpty)
      .toList();

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
      stderr.writeln('$id references unknown exercise id "$movementId"');
      exit(1);
    }

    final type = movement[_typeColumn(movement)]!.trim().toLowerCase();
    final plane = movement['Movement plane id']!.trim();
    final section = _sectionForWorkoutSection[movement['workout section']!
        .trim()
        .toLowerCase()];
    final weightFormula = node['(Optional) weight setting']!.trim();
    final prerequisite = previous[id]!;

    buffer
      ..writeln('    Exercise(')
      ..writeln("      id: '$id',")
      ..writeln(
        '      category: ExerciseCategory.${_categoryForPlane[plane] ?? 'other'},',
      )
      ..writeln("      skillCategoryId: '${node['Skill tree ID']!.trim()}',")
      ..writeln("      branchId: '${node['Branch']!.trim()}',")
      ..writeln("      name: ${_dartString(node['Node name']!.trim())},")
      ..writeln('      description: ${_dartString(_description(movement))},')
      ..writeln("      difficulty: ${node['Difficulty']!.trim()},")
      ..writeln('      treeOrder: ${_depth(id, previous)},');
    if (prerequisite.isNotEmpty) {
      buffer.writeln("      prerequisiteIds: ['$prerequisite'],");
    }
    if (section != null) {
      buffer.writeln('      programSection: ExerciseProgramSection.$section,');
    }
    buffer
      ..writeln('      muscles: [${_muscles(movement).map(_dartString).join(', ')}],')
      ..writeln("      libraryId: '$movementId',");
    if (type.startsWith('timed')) buffer.writeln('      isTimed: true,');
    if (type.contains('weight')) buffer.writeln('      isWeighted: true,');
    if (_openEndedNodes.contains(id)) buffer.writeln('      isLoaded: true,');
    if (weightFormula.isNotEmpty) {
      buffer.writeln('      weightFormula: ${_dartString(weightFormula)},');
    }
    buffer.writeln('    ),');
  }

  // Only the step list is generated. Everything around it — the imports, the
  // header, and the lookups the app actually calls — is written by hand and
  // left exactly as it is.
  final file = File(_output);
  final current = file.readAsStringSync();
  final start = current.indexOf(_listOpens);
  final end = current.indexOf(_listCloses, start);
  if (start < 0 || end < 0) {
    stderr.writeln('Could not find the step list in $_output');
    exit(1);
  }

  file.writeAsStringSync(
    '${current.substring(0, start + _listOpens.length)}\n'
    '$buffer${current.substring(end)}',
  );
  stdout.writeln('Wrote ${nodes.length} steps to $_output');
}

const _listOpens = 'static const List<Exercise> _all = [';
const _listCloses = '\n  ];';

/// The sheet spells the header out in full, brackets and all, so it is found
/// by prefix rather than repeated here and left to rot.
String _typeColumn(Map<String, String> row) =>
    row.keys.firstWhere((key) => key.startsWith('Excercise type'));

/// What a step says about itself in one line: the first sentence of the
/// movement's how-to, or its name where the sheet has no how-to yet.
String _description(Map<String, String> row) {
  final howTo = row['How to']!.trim();
  if (howTo.isEmpty) return row['Name']!.trim();
  final match = RegExp(r'.*?[.!?](\s|$)', dotAll: true).firstMatch(howTo);
  return (match == null ? howTo : match.group(0)!).trim();
}

/// Primary muscles then secondary, spelled the one way [kExerciseMuscleGroups]
/// spells them — the sheet writes some in title case in one column and lower
/// case in the other, and the same muscle spelled twice would be two filters.
List<String> _muscles(Map<String, String> row) {
  final canonical = {
    for (final group in kExerciseMuscleGroups) group.toLowerCase(): group,
  };
  final muscles = <String>[];
  for (final column in [
    'Muscles worked (primary)',
    'Muscles worked (secondary)',
  ]) {
    for (final raw in row[column]!.split(';')) {
      final muscle = raw.trim();
      if (muscle.isEmpty) continue;
      final spelling = canonical[muscle.toLowerCase()] ?? muscle;
      if (!muscles.contains(spelling)) muscles.add(spelling);
    }
  }
  return muscles;
}

/// How many steps deep the node sits — the row it is drawn on, and the order
/// a path is walked in.
int _depth(String id, Map<String, String> previous) {
  var depth = 0;
  var current = id;
  while ((previous[current] ?? '').isNotEmpty) {
    current = previous[current]!;
    depth++;
  }
  return depth;
}

String _dartString(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

/// RFC 4180: quoted fields may hold commas, newlines and doubled quotes.
List<Map<String, String>> _readCsv(String source) {
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
