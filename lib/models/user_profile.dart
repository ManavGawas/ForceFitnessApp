class UserProfile {
  final String uid;
  final String? displayName;
  final double? bodyWeightKg;
  final int dailyCaloriesGoal;
  final int dailyProteinGoal;
  final bool usesKg;

  UserProfile({
    required this.uid,
    this.displayName,
    this.bodyWeightKg,
    this.dailyCaloriesGoal = 2000,
    this.dailyProteinGoal = 150,
    this.usesKg = true,
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'bodyWeightKg': bodyWeightKg,
        'dailyCaloriesGoal': dailyCaloriesGoal,
        'dailyProteinGoal': dailyProteinGoal,
        'usesKg': usesKg,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) => UserProfile(
        uid: uid,
        displayName: data['displayName'],
        bodyWeightKg: (data['bodyWeightKg'] as num?)?.toDouble(),
        dailyCaloriesGoal: data['dailyCaloriesGoal'] ?? 2000,
        dailyProteinGoal: data['dailyProteinGoal'] ?? 150,
        usesKg: data['usesKg'] ?? true,
      );
}
