class Routine {
  final String id;
  final String name;
  // Each item: exerciseId (reference) and display name + default set/rep
  final List<RoutineExercise> exercises;
  Routine({required this.id, required this.name, this.exercises = const []});
  Map<String, dynamic> toMap() => {
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
  factory Routine.fromMap(String id, Map<String, dynamic> m) => Routine(
        id: id,
        name: m['name'] ?? '',
        exercises: ((m['exercises'] as List?) ?? []).map((e) => RoutineExercise.fromMap(Map<String, dynamic>.from(e))).toList(),
      );
}

class RoutineExercise {
  final String exerciseId;
  final String name;
  final List<Map<String, dynamic>> sets; // [{reps:10, kg: null}]
  RoutineExercise({required this.exerciseId, required this.name, this.sets = const []});
  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'name': name,
        'sets': sets,
      };
  factory RoutineExercise.fromMap(Map<String, dynamic> m) => RoutineExercise(
        exerciseId: m['exerciseId'] ?? '',
        name: m['name'] ?? '',
        sets: ((m['sets'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      );
}
