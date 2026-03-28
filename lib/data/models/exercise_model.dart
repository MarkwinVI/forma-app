enum ExerciseCategory {
  verticalPull,
  verticalPush,
  horizontalPull,
  horizontalPush,
  legs,
  core,
}

extension ExerciseCategoryX on ExerciseCategory {
  String get id {
    switch (this) {
      case ExerciseCategory.verticalPull:   return 'vertical_pull';
      case ExerciseCategory.verticalPush:   return 'vertical_push';
      case ExerciseCategory.horizontalPull: return 'horizontal_pull';
      case ExerciseCategory.horizontalPush: return 'horizontal_push';
      case ExerciseCategory.legs:           return 'legs';
      case ExerciseCategory.core:           return 'core';
    }
  }

  String get label {
    switch (this) {
      case ExerciseCategory.verticalPull:   return 'Vertical Pull';
      case ExerciseCategory.verticalPush:   return 'Vertical Push';
      case ExerciseCategory.horizontalPull: return 'Horizontal Pull';
      case ExerciseCategory.horizontalPush: return 'Horizontal Push';
      case ExerciseCategory.legs:           return 'Legs';
      case ExerciseCategory.core:           return 'Core';
    }
  }
}

enum ExerciseStatus { inactive, active, mastered }

class Exercise {
  final String id;
  final ExerciseCategory category;
  final String name;
  final String description;
  final int difficulty; // 1–5
  final int treeOrder;  // exercises with the same value appear on the same row
  final List<String> prerequisiteIds;
  final String? imageUrl;

  const Exercise({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.treeOrder,
    this.prerequisiteIds = const [],
    this.imageUrl,
  });
}
