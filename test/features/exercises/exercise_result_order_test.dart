import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/catalog/exercise_catalog.dart';
import 'package:forma_app/data/models/exercise_model.dart';
import 'package:forma_app/features/home/program_day_items.dart';

/// What browse, add-to-day and swap-mid-workout all open on.
void main() {
  List<Exercise> ordered({String query = '', bool isFiltered = false}) {
    final list = ExerciseCatalog.everything().toList();
    sortExerciseResults(list, query: query, isFiltered: isFiltered);
    return list;
  }

  group('the untouched list', () {
    test('opens on the general library, not the skill trees', () {
      final first = ordered().take(20);
      expect(first.every((exercise) => exercise.isLibrary), isTrue);
    });

    test('runs the whole library before the first tree step', () {
      final list = ordered();
      final firstTreeStep = list.indexWhere((exercise) => !exercise.isLibrary);
      expect(firstTreeStep, ExerciseCatalog.everything().length - 136);
    });

    test('is alphabetical inside each half', () {
      final list = ordered();
      final library = list.where((e) => e.isLibrary).map((e) => e.name).toList();
      final tree = list.where((e) => !e.isLibrary).map((e) => e.name).toList();
      expect(library, orderedEquals(library.toList()..sort()));
      expect(tree, orderedEquals(tree.toList()..sort()));
    });
  });

  group('once something is asked for', () {
    test('a query puts the best match first, library or not', () {
      final list = ordered(query: 'scapular');
      expect(list.first.name, 'Scapular Pull');
      expect(list.first.isLibrary, isFalse);
    });

    test('a filter drops the library-first rule', () {
      final list = ordered(isFiltered: true);
      expect(list.first.isLibrary, isFalse,
          reason: 'filtered lists sort alphabetically across both halves');
      expect(list.first.name, list.map((e) => e.name).reduce((a, b) => a.compareTo(b) <= 0 ? a : b));
    });

    test('a query still ranks a prefix match above an alphabetical one', () {
      final list = ordered(query: 'pull');
      expect(normalizeExerciseSearch(list.first.name), startsWith('pull'));
    });
  });
}
