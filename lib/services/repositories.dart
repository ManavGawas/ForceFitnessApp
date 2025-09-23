import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/nutrition.dart';
import '../models/pr.dart';
import '../models/user_profile.dart';
import '../models/split.dart';
import '../models/steps.dart';
import '../models/run.dart';
import '../models/body_measurement.dart';
import '../models/progress_photo.dart';

class _BaseRepo {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String get userPrefix => 'users';
}

class ExerciseRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('exercises');

  Future<void> add(String uid, Exercise ex) async {
    await _col(uid).add(ex.toMap());
  }

  Future<void> upsert(String uid, Exercise ex) async {
    await _col(uid).doc(ex.id).set(ex.toMap(), SetOptions(merge: true));
  }

  Stream<List<Exercise>> streamAll(String uid) {
    return _col(uid).orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => Exercise.fromMap(d.id, d.data())).toList());
  }
}

class WorkoutRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('workouts');

  Future<void> saveSession(String uid, WorkoutSession s) async {
    await _col(uid).doc(s.id).set(s.toMap());
  }

  Stream<List<WorkoutSession>> byMonth(String uid, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkoutSession.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<WorkoutSession>> byDay(String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WorkoutSession.fromMap(d.id, d.data()))
            .toList());
  }

  // Previous values for an exercise (most recent session before today)
  Future<WorkoutEntry?> previousForExercise(String uid, String exerciseName) async {
    final q = await _col(uid)
        .orderBy('date', descending: true)
        .limit(10)
        .get();
    for (final d in q.docs) {
      final s = WorkoutSession.fromMap(d.id, d.data());
      final match = s.entries.firstWhere(
        (e) => e.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
        orElse: () => WorkoutEntry(exerciseId: '', exerciseName: '', sets: const []),
      );
      if (match.exerciseName.isNotEmpty) return match;
    }
    return null;
  }

  // Streak: number of consecutive days with a workout including today
  Future<int> currentStreak(String uid) async {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final list = await byDay(uid, day).first;
      if (list.isEmpty) break;
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class NutritionRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('nutrition');

  Future<void> add(String uid, NutritionEntry e) async {
    await _col(uid).add(e.toMap());
  }

  Future<void> upsert(String uid, NutritionEntry e) async {
    await _col(uid).doc(e.id).set(e.toMap(), SetOptions(merge: true));
  }

  Stream<List<NutritionEntry>> byDay(String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NutritionEntry.fromMap(d.id, d.data()))
            .toList());
  }
}

class PRRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('prs');

  Future<void> add(String uid, PRRecord pr) async {
    await _col(uid).doc(pr.id).set(pr.toMap());
  }

  Stream<List<PRRecord>> all(String uid) => _col(uid)
      .orderBy('exerciseName')
      .orderBy('weight', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => PRRecord.fromMap(d.id, d.data())).toList());
}

class UserProfileRepository extends _BaseRepo {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      db.collection(userPrefix).doc(uid);

  Stream<UserProfile> stream(String uid) => _doc(uid).snapshots().map((d) =>
      UserProfile.fromMap(uid, d.data() ?? {}));

  Future<void> update(String uid, UserProfile profile) async {
    await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }
}

class SplitRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('splits');

  Stream<List<SplitPlan>> all(String uid) => _col(uid)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => SplitPlan.fromMap(d.id, d.data())).toList());

  Stream<SplitPlan?> active(String uid) => _col(uid)
      .where('active', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : SplitPlan.fromMap(s.docs.first.id, s.docs.first.data()));

  Future<void> create(String uid, SplitPlan plan) async {
    await _col(uid).add(plan.toMap());
  }

  Future<void> setActive(String uid, String id, {required bool active}) async {
    final batch = db.batch();
    // Deactivate all, then activate selected
    final current = await _col(uid).get();
    for (final d in current.docs) {
      batch.update(d.reference, {'active': d.id == id ? active : false});
    }
    await batch.commit();
  }

  Future<void> update(String uid, SplitPlan plan) async {
    await _col(uid).doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }
}

class StepsRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('steps');

  Future<void> add(String uid, StepsEntry e) async {
    await _col(uid).add(e.toMap());
  }

  Stream<List<StepsEntry>> byDay(String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .snapshots()
        .map((s) => s.docs.map((d) => StepsEntry.fromMap(d.id, d.data())).toList());
  }
}

class RunRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('runs');

  Future<void> save(String uid, RunSession s) async {
    await _col(uid).doc(s.id).set(s.toMap());
  }

  Stream<List<RunSession>> all(String uid) => _col(uid)
      .orderBy('start', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => RunSession.fromMap(d.id, d.data())).toList());
}

class BodyMeasurementsRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('measurements');

  Future<void> add(String uid, BodyMeasurement m) async {
    await _col(uid).add(m.toMap());
  }

  Stream<List<BodyMeasurement>> all(String uid) => _col(uid)
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map((d) => BodyMeasurement.fromMap(d.id, d.data())).toList());
}

class ProgressPhotosRepository extends _BaseRepo {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection(userPrefix).doc(uid).collection('progress_photos');

  Future<void> add(String uid, ProgressPhoto p) async {
    await _col(uid).add(p.toMap());
  }

  Stream<List<ProgressPhoto>> all(String uid) => _col(uid)
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map((d) => ProgressPhoto.fromMap(d.id, d.data())).toList());
}
