// Exports the skill trees as CSV: one row per step per branch, so a step the
// branches share is listed once under each, with the node that precedes it
// there. Run with:
//
//   dart run tool/export_skill_trees.dart [path]
//
// It writes the file itself rather than printing, because `dart run` puts its
// own build chatter on stdout and it would land in the CSV.
import 'dart:io';

import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/catalog/skill_category_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/data/models/skill_category_model.dart';

/// The label the Skills tab shows for a branch. The catalog calls the
/// pull-up close-grip branch "Close Grip"; the tree relabels it.
String branchLabel(SkillCategory category, String branchId) {
  if (category.id == SkillCategoryCatalog.pullupsId &&
      branchId == 'close_grip') {
    return 'High Pull-up';
  }
  for (final branch in category.branches) {
    if (branch.id == branchId) return branch.label;
  }
  return branchId;
}

/// The opening steps every branch of a tree shares.
List<String> sharedFoundation(SkillCategory category) {
  final paths = category.trainingPaths.values.toList();
  if (paths.length < 2 || paths.any((path) => path.isEmpty)) return const [];

  final shared = <String>[];
  final shortest =
      paths.map((path) => path.length).reduce((a, b) => a < b ? a : b);
  for (var index = 0; index < shortest; index++) {
    final candidate = paths.first[index];
    if (paths.every((path) => path[index] == candidate)) {
      shared.add(candidate);
    } else {
      break;
    }
  }
  return shared;
}

String cell(Object? value) {
  final text = '$value';
  return text.contains(RegExp('[",\n]'))
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

void main(List<String> args) {
  final rows = <List<Object>>[
    [
      'Skill tree',
      'Skill tree id',
      'Branch name',
      'Branch id',
      'Step',
      'Exercise',
      'Exercise id',
      'Difficulty',
      'Previous node',
      'Previous node id',
      'Prerequisite ids',
      'Shared foundation',
      'Movement pattern',
      'Measured in',
      'Tree order',
    ],
  ];

  final placed = <String>{};

  for (final category in SkillCategoryCatalog.all()) {
    final paths = category.trainingPaths.isNotEmpty
        ? category.trainingPaths
        : {
            'main': ExerciseCatalog.forSkillCategory(category.id)
                .map((exercise) => exercise.id)
                .toList(),
          };
    final foundation = sharedFoundation(category).toSet();

    for (final entry in paths.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final exercise = ExerciseCatalog.findById(entry.value[index]);
        if (exercise == null) continue;
        placed.add(exercise.id);

        final previous =
            index == 0 ? null : ExerciseCatalog.findById(entry.value[index - 1]);

        rows.add([
          category.title,
          category.id,
          branchLabel(category, entry.key),
          entry.key,
          index + 1,
          exercise.name,
          exercise.id,
          exercise.difficulty,
          previous?.name ?? '',
          previous?.id ?? '',
          exercise.prerequisiteIds.join('; '),
          foundation.contains(exercise.id) ? 'yes' : 'no',
          exercise.category.label,
          exercise.isTimed ? 'seconds' : 'reps',
          exercise.treeOrder,
        ]);
      }
    }
  }

  // Anything the trees never walk over still belongs in the export, or the
  // file quietly claims the catalog is smaller than it is.
  for (final exercise in ExerciseCatalog.all()) {
    if (placed.contains(exercise.id)) continue;
    final categoryId = ExerciseCatalog.skillCategoryIdForExercise(exercise);
    final category = SkillCategoryCatalog.findById(categoryId);
    rows.add([
      category?.title ?? categoryId,
      categoryId,
      '(not on a branch)',
      exercise.branchId,
      '',
      exercise.name,
      exercise.id,
      exercise.difficulty,
      '',
      '',
      exercise.prerequisiteIds.join('; '),
      'no',
      exercise.category.label,
      exercise.isTimed ? 'seconds' : 'reps',
      exercise.treeOrder,
    ]);
  }

  final path = args.isEmpty ? 'skill_trees.csv' : args.first;
  File(path).writeAsStringSync(
    '${rows.map((row) => row.map(cell).join(',')).join('\n')}\n',
  );
  stderr.writeln('Wrote ${rows.length - 1} rows to $path');
}
