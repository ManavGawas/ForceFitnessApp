class PRRecord {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final DateTime date;
  final double weight;
  final int reps;

  PRRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.weight,
    required this.reps,
  });

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'date': date.toIso8601String(),
        'weight': weight,
        'reps': reps,
      };

  factory PRRecord.fromMap(String id, Map<String, dynamic> data) => PRRecord(
        id: id,
        exerciseId: data['exerciseId'] ?? '',
        exerciseName: data['exerciseName'] ?? '',
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        weight: (data['weight'] ?? 0).toDouble(),
        reps: data['reps'] ?? 0,
      );
}
