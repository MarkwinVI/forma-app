class UserModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final double? bodyweightKg;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.bodyweightKg,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bodyweightKg: (map['bodyweight_kg'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bodyweight_kg': bodyweightKg,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
