import 'package:flutter_test/flutter_test.dart';
import 'package:forma_app/data/models/training_program_model.dart';

void main() {
  group('programDayConfig', () {
    test('reads the shared per-type entry', () {
      final config = {
        'upper': {'strength': []},
      };

      expect(
        programDayConfig(config, TrainingSessionType.upper),
        {'strength': []},
      );
      expect(programDayConfig(config, TrainingSessionType.lower), isNull);
    });

    test('falls back to the earliest legacy per-day entry', () {
      final config = {
        '3:upper': {'strength': ['thursday']},
        '0:upper': {'strength': ['monday']},
      };

      // Monday's old plan stands in for the whole type.
      expect(
        programDayConfig(config, TrainingSessionType.upper),
        {'strength': ['monday']},
      );
    });

    test('prefers the shared entry over legacy per-day ones', () {
      final config = {
        'upper': {'strength': ['shared']},
        '0:upper': {'strength': ['monday']},
      };

      expect(
        programDayConfig(config, TrainingSessionType.upper),
        {'strength': ['shared']},
      );
    });

    test('a legacy entry never leaks onto another session type', () {
      final config = {
        '0:upper': {'strength': ['monday']},
      };

      expect(programDayConfig(config, TrainingSessionType.lower), isNull);
    });
  });

  group('writeProgramDayConfig', () {
    test('writes the shared entry and clears the type\'s legacy days', () {
      final config = <String, dynamic>{
        '0:upper': {'strength': ['monday']},
        '3:upper': {'strength': ['thursday']},
        '1:lower': {'strength': ['tuesday']},
      };

      writeProgramDayConfig(config, TrainingSessionType.upper, {
        'strength': ['shared'],
      });

      expect(config, {
        'upper': {'strength': ['shared']},
        // Another type's legacy entries are not this save's to clean up.
        '1:lower': {'strength': ['tuesday']},
      });
    });
  });
}
