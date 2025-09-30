import 'package:gymmate/models/routine.dart';
import 'package:gymmate/services/repositories.dart';

class RoutinesSeedService {
  static Future<void> seedCurated(String uid) async {
    // Load existing exercises, map by lowercase name
    final exSnap = await ExerciseRepository().streamAll(uid).first;
    final byName = {for (final e in exSnap) e.name.toLowerCase(): e};

    Routine mk(String name, List<Map<String, dynamic>> spec) {
      final items = <RoutineExercise>[];
      for (final it in spec) {
        final n = (it['name'] as String).trim();
        final ex = byName[n.toLowerCase()];
        if (ex == null) continue; // skip if user doesn't have it
        items.add(RoutineExercise(
          exerciseId: ex.id.isEmpty ? ex.name.toLowerCase().replaceAll(' ', '_') : ex.id,
          name: ex.name,
          sets: (it['sets'] as List).map((s) => {'reps': s[0], 'kg': s.length > 1 ? s[1] : null}).toList(),
        ));
      }
      return Routine(id: name.toLowerCase().replaceAll(' ', '_'), name: name, exercises: items);
    }

    final curated = <Routine>[
      mk('Chest Power', [
        {'name': 'Bench Press', 'sets': [[5],[5],[5],[5],[5]]},
        {'name': 'Incline Dumbbell Press', 'sets': [[10],[10],[10]]},
        {'name': 'Cable Fly', 'sets': [[12],[12],[12]]},
      ]),
      mk('Back Strength', [
        {'name': 'Deadlift', 'sets': [[3],[3],[3],[3],[3]]},
        {'name': 'Lat Pulldown', 'sets': [[10],[10],[10],[10]]},
        {'name': 'Seated Row', 'sets': [[12],[12],[12]]},
      ]),
      mk('Arm Finisher', [
        {'name': 'Barbell Curl', 'sets': [[10],[10],[10],[10]]},
        {'name': 'Triceps Pushdown', 'sets': [[12],[12],[12],[12]]},
        {'name': 'Hammer Curl', 'sets': [[12],[12],[12]]},
      ]),
    ];

    final repo = RoutinesRepository();
    for (final r in curated) {
      await repo.upsert(uid, r);
    }
  }
}
