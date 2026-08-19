/// Answers collected by the post-signup onboarding flow.
/// Mirrors the `user_onboarding_profiles` table (one row per user).
class OnboardingProfileModel {
  final String userId;

  /// 'generalist' | 'technician' | 'specialist' | 'powerhouse' |
  /// 'heavyweight' | 'builder' | 'natural' | 'mover' | 'artist'
  final String archetype;

  /// True when the radar dot was left in the centre ("Balanced").
  final bool radarBalanced;

  /// Radar dot direction in degrees (-90 is up); null when balanced.
  final double? radarAngleDeg;

  final int age;

  /// 'f' | 'm' | 'na' — null if not answered.
  final String? gender;

  /// '0' | '1-2' | '3-4' | '5+' sessions per week — null if not answered.
  final String? trainingFrequency;

  final DateTime completedAt;

  const OnboardingProfileModel({
    required this.userId,
    required this.archetype,
    required this.radarBalanced,
    this.radarAngleDeg,
    required this.age,
    this.gender,
    this.trainingFrequency,
    required this.completedAt,
  });

  factory OnboardingProfileModel.fromMap(Map<String, dynamic> map) {
    return OnboardingProfileModel(
      userId: map['user_id'] as String,
      archetype: map['archetype'] as String,
      radarBalanced: map['radar_balanced'] as bool,
      radarAngleDeg: (map['radar_angle_deg'] as num?)?.toDouble(),
      age: map['age'] as int,
      gender: map['gender'] as String?,
      trainingFrequency: map['training_frequency'] as String?,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'archetype': archetype,
      'radar_balanced': radarBalanced,
      'radar_angle_deg': radarAngleDeg,
      'age': age,
      'gender': gender,
      'training_frequency': trainingFrequency,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}
