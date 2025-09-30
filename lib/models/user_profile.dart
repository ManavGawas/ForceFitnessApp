class UserProfile {
  final String uid;
  final String? displayName;
  final double? bodyWeightKg;
  final int dailyCaloriesGoal;
  final int dailyProteinGoal;
  final int dailyCarbsGoal;
  final int dailyFatsGoal;
  final int dailyStepsTarget;
  final int dailyWaterTargetMl;
  final int dailySleepTargetMin;
  final int weeklyWorkoutTarget;
  final bool usesKg;
  final bool onboarded;
  final bool termsAccepted;

  UserProfile({
    required this.uid,
    this.displayName,
    this.bodyWeightKg,
    this.dailyCaloriesGoal = 2000,
    this.dailyProteinGoal = 150,
    this.dailyCarbsGoal = 300,
    this.dailyFatsGoal = 70,
  this.dailyStepsTarget = 8000,
  this.dailyWaterTargetMl = 2000,
    this.dailySleepTargetMin = 480,
    this.weeklyWorkoutTarget = 5,
    this.usesKg = true,
    this.onboarded = false,
    this.termsAccepted = false,
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'bodyWeightKg': bodyWeightKg,
        'dailyCaloriesGoal': dailyCaloriesGoal,
        'dailyProteinGoal': dailyProteinGoal,
        'dailyCarbsGoal': dailyCarbsGoal,
        'dailyFatsGoal': dailyFatsGoal,
  'dailyStepsTarget': dailyStepsTarget,
  'dailyWaterTargetMl': dailyWaterTargetMl,
    'dailySleepTargetMin': dailySleepTargetMin,
    'weeklyWorkoutTarget': weeklyWorkoutTarget,
        'usesKg': usesKg,
    'onboarded': onboarded,
    'termsAccepted': termsAccepted,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) => UserProfile(
        uid: uid,
        displayName: data['displayName'],
        bodyWeightKg: (data['bodyWeightKg'] as num?)?.toDouble(),
        dailyCaloriesGoal: data['dailyCaloriesGoal'] ?? 2000,
        dailyProteinGoal: data['dailyProteinGoal'] ?? 150,
        dailyCarbsGoal: data['dailyCarbsGoal'] ?? 300,
        dailyFatsGoal: data['dailyFatsGoal'] ?? 70,
  dailyStepsTarget: data['dailyStepsTarget'] ?? 8000,
  dailyWaterTargetMl: data['dailyWaterTargetMl'] ?? 2000,
    dailySleepTargetMin: data['dailySleepTargetMin'] ?? 480,
    weeklyWorkoutTarget: data['weeklyWorkoutTarget'] ?? 5,
        usesKg: data['usesKg'] ?? true,
    onboarded: data['onboarded'] ?? false,
        termsAccepted: data['termsAccepted'] ?? false,
      );
}
