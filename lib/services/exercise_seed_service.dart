import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';
import 'repositories.dart';

class ExerciseSeedService {
  static Future<void> seedIfEmpty(String uid) async {
    final repo = ExerciseRepository();
    final current = await repo.streamAll(uid).first;
    if (current.isNotEmpty) return;
    final data = await rootBundle.loadString('assets/exercises_seed.json');
    final List<dynamic> list = jsonDecode(data);
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final ex = Exercise(
        id: '',
        name: map['name'] as String,
        muscleGroup: (map['muscleGroup'] ?? 'general') as String,
        category: map['category'] as String?,
        primaryMuscle: map['primaryMuscle'] as String?,
      );
      await repo.add(uid, ex);
    }
  }
}
