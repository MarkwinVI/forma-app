import 'exercise_model.dart';

enum TrainingProgramType { fullBody, pushPull, upperLower }

extension TrainingProgramTypeX on TrainingProgramType {
  String get dbValue {
    switch (this) {
      case TrainingProgramType.fullBody:
        return 'full_body';
      case TrainingProgramType.pushPull:
        return 'push_pull';
      case TrainingProgramType.upperLower:
        return 'upper_lower';
    }
  }

  String get label {
    switch (this) {
      case TrainingProgramType.fullBody:
        return 'Full Body';
      case TrainingProgramType.pushPull:
        return 'Push / Pull';
      case TrainingProgramType.upperLower:
        return 'Upper / Lower';
    }
  }

  static TrainingProgramType fromDbValue(String value) {
    switch (value) {
      case 'push_pull':
        return TrainingProgramType.pushPull;
      case 'upper_lower':
        return TrainingProgramType.upperLower;
      case 'full_body':
      default:
        return TrainingProgramType.fullBody;
    }
  }
}

enum TrainingSessionType { fullBody, push, pull, upper, lower, rest }

extension TrainingSessionTypeX on TrainingSessionType {
  String get dbValue {
    switch (this) {
      case TrainingSessionType.fullBody:
        return 'full_body';
      case TrainingSessionType.push:
        return 'push';
      case TrainingSessionType.pull:
        return 'pull';
      case TrainingSessionType.upper:
        return 'upper';
      case TrainingSessionType.lower:
        return 'lower';
      case TrainingSessionType.rest:
        return 'rest';
    }
  }

  String get label {
    switch (this) {
      case TrainingSessionType.fullBody:
        return 'Today\'s Session';
      case TrainingSessionType.push:
        return 'Push Day';
      case TrainingSessionType.pull:
        return 'Pull Day';
      case TrainingSessionType.upper:
        return 'Upper Day';
      case TrainingSessionType.lower:
        return 'Lower Day';
      case TrainingSessionType.rest:
        return 'Rest Day';
    }
  }

  static TrainingSessionType fromDbValue(String value) {
    switch (value) {
      case 'push':
        return TrainingSessionType.push;
      case 'pull':
        return TrainingSessionType.pull;
      case 'upper':
        return TrainingSessionType.upper;
      case 'lower':
        return TrainingSessionType.lower;
      case 'rest':
        return TrainingSessionType.rest;
      case 'full_body':
      default:
        return TrainingSessionType.fullBody;
    }
  }
}

enum TrainingTrack {
  skillWork,
  verticalPush,
  horizontalPush,
  verticalPull,
  horizontalPull,
  core,
  squat,
  hinge,
}

extension TrainingTrackX on TrainingTrack {
  String get dbValue {
    switch (this) {
      case TrainingTrack.skillWork:
        return 'skill_work';
      case TrainingTrack.verticalPush:
        return 'vertical_push';
      case TrainingTrack.horizontalPush:
        return 'horizontal_push';
      case TrainingTrack.verticalPull:
        return 'vertical_pull';
      case TrainingTrack.horizontalPull:
        return 'horizontal_pull';
      case TrainingTrack.core:
        return 'core';
      case TrainingTrack.squat:
        return 'squat';
      case TrainingTrack.hinge:
        return 'hinge';
    }
  }

  String get label {
    switch (this) {
      case TrainingTrack.skillWork:
        return 'Skill Work';
      case TrainingTrack.verticalPush:
        return 'Vertical Push';
      case TrainingTrack.horizontalPush:
        return 'Horizontal Push';
      case TrainingTrack.verticalPull:
        return 'Vertical Pull';
      case TrainingTrack.horizontalPull:
        return 'Horizontal Pull';
      case TrainingTrack.core:
        return 'Core';
      case TrainingTrack.squat:
        return 'Squat';
      case TrainingTrack.hinge:
        return 'Hinge';
    }
  }

  static TrainingTrack fromDbValue(String value) {
    switch (value) {
      case 'skill_work':
        return TrainingTrack.skillWork;
      case 'vertical_push':
        return TrainingTrack.verticalPush;
      case 'horizontal_push':
        return TrainingTrack.horizontalPush;
      case 'vertical_pull':
        return TrainingTrack.verticalPull;
      case 'horizontal_pull':
        return TrainingTrack.horizontalPull;
      case 'core':
        return TrainingTrack.core;
      case 'squat':
        return TrainingTrack.squat;
      case 'hinge':
      default:
        return TrainingTrack.hinge;
    }
  }
}

enum RepGoalProfile { strength, balanced, volume }

extension RepGoalProfileX on RepGoalProfile {
  String get dbValue {
    switch (this) {
      case RepGoalProfile.strength:
        return 'strength';
      case RepGoalProfile.balanced:
        return 'balanced';
      case RepGoalProfile.volume:
        return 'volume';
    }
  }

  String get label {
    switch (this) {
      case RepGoalProfile.strength:
        return 'Strength';
      case RepGoalProfile.balanced:
        return 'Balanced';
      case RepGoalProfile.volume:
        return 'Volume';
    }
  }

  String get summary {
    switch (this) {
      case RepGoalProfile.strength:
        return 'Bias harder sets and lower rep targets on main lifts.';
      case RepGoalProfile.balanced:
        return 'Keep a mix of skill quality, strength, and repeatable volume.';
      case RepGoalProfile.volume:
        return 'Bias longer sets, cleaner practice, and total reps.';
    }
  }

  static RepGoalProfile fromDbValue(String? value) {
    switch (value) {
      case 'strength':
        return RepGoalProfile.strength;
      case 'volume':
        return RepGoalProfile.volume;
      case 'balanced':
      default:
        return RepGoalProfile.balanced;
    }
  }
}

class TrainingRecommendationItem {
  final TrainingTrack track;
  final Exercise exercise;
  final ExerciseStatus status;
  final ExerciseCategory sourceCategory;
  final String sourceSkillCategoryId;

  /// Ordered exercise ids of the progression this exercise was picked from.
  /// Empty when the branch is not a skill-tree progression.
  final List<String> progressionExerciseIds;

  const TrainingRecommendationItem({
    required this.track,
    required this.exercise,
    required this.status,
    required this.sourceCategory,
    required this.sourceSkillCategoryId,
    this.progressionExerciseIds = const [],
  });
}

class DailyTrainingRecommendation {
  final TrainingProgramType programType;
  final TrainingSessionType sessionType;
  final String sessionLabel;
  final bool isRestDay;
  final List<TrainingRecommendationItem> items;

  const DailyTrainingRecommendation({
    required this.programType,
    required this.sessionType,
    required this.sessionLabel,
    required this.isRestDay,
    required this.items,
  });
}

class UserTrainingProgram {
  final String id;
  final String userId;
  final TrainingProgramType programType;
  final String? scheduleVariant;
  final int frequencyPerWeek;
  final Map<String, dynamic> variationRules;
  final bool isActive;

  /// Exercise ids of the long-term goal skills the user is training toward.
  final List<String> goalSkillIds;

  const UserTrainingProgram({
    required this.id,
    required this.userId,
    required this.programType,
    required this.scheduleVariant,
    required this.frequencyPerWeek,
    required this.variationRules,
    required this.isActive,
    this.goalSkillIds = const [],
  });

  factory UserTrainingProgram.fromMap(Map<String, dynamic> map) {
    return UserTrainingProgram(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      programType: TrainingProgramTypeX.fromDbValue(
        map['program_type'] as String,
      ),
      scheduleVariant: map['schedule_variant'] as String?,
      frequencyPerWeek: map['frequency_per_week'] as int? ?? 3,
      variationRules: Map<String, dynamic>.from(
        map['variation_rules'] as Map? ?? const {},
      ),
      isActive: map['is_active'] as bool? ?? true,
      goalSkillIds: (map['goal_skills'] as List<dynamic>? ?? const [])
          .map((id) => id as String)
          .toList(),
    );
  }
}

class UserTrainingProgramState {
  final String id;
  final String programId;
  final String userId;
  final int nextStepIndex;
  final TrainingSessionType nextSessionType;

  const UserTrainingProgramState({
    required this.id,
    required this.programId,
    required this.userId,
    required this.nextStepIndex,
    required this.nextSessionType,
  });

  factory UserTrainingProgramState.fromMap(Map<String, dynamic> map) {
    return UserTrainingProgramState(
      id: map['id'] as String,
      programId: map['program_id'] as String,
      userId: map['user_id'] as String,
      nextStepIndex: map['next_step_index'] as int? ?? 0,
      nextSessionType: TrainingSessionTypeX.fromDbValue(
        map['next_session_type'] as String,
      ),
    );
  }
}

class UserTrainingProgramSnapshot {
  final UserTrainingProgram program;
  final UserTrainingProgramState state;

  const UserTrainingProgramSnapshot({
    required this.program,
    required this.state,
  });
}

class TrainingProgramLogicSnapshot {
  final UserTrainingProgram program;
  final UserTrainingProgramState state;
  final Map<TrainingTrack, String> branchSelections;
  final RepGoalProfile repGoalProfile;

  const TrainingProgramLogicSnapshot({
    required this.program,
    required this.state,
    required this.branchSelections,
    required this.repGoalProfile,
  });
}
