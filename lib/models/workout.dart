class SetEntry {
  final int setNumber;
  final double weight;
  final int reps;
  final int? rpe;
  final String? type; // e.g., warmup, drop, failure, normal

  SetEntry({required this.setNumber, required this.weight, required this.reps, this.rpe, this.type});

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
    if (type != null) 'type': type,
      };

  factory SetEntry.fromMap(Map<String, dynamic> data) => SetEntry(
        setNumber: data['setNumber'] ?? 0,
        weight: (data['weight'] ?? 0).toDouble(),
        reps: data['reps'] ?? 0,
    rpe: data['rpe'],
    type: data['type'],
      );
}

class WorkoutEntry {
  final String exerciseId;
  final String exerciseName; // denormalized for convenience
  final List<SetEntry> sets;
  final String? note;
  final String? supersetWith;

  WorkoutEntry({required this.exerciseId, required this.exerciseName, required this.sets, this.note, this.supersetWith});

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toMap()).toList(),
    if (note != null) 'note': note,
    if (supersetWith != null) 'supersetWith': supersetWith,
      };

  factory WorkoutEntry.fromMap(Map<String, dynamic> data) => WorkoutEntry(
        exerciseId: data['exerciseId'] ?? '',
        exerciseName: data['exerciseName'] ?? '',
        sets: (data['sets'] as List<dynamic>? ?? []).map((e) => SetEntry.fromMap(e as Map<String, dynamic>)).toList(),
        note: data['note'],
        supersetWith: data['supersetWith'],
      );
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final List<WorkoutEntry> entries;
  final String? notes;

  WorkoutSession({required this.id, required this.date, required this.entries, this.notes});

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'entries': entries.map((e) => e.toMap()).toList(),
        'notes': notes,
      };

  factory WorkoutSession.fromMap(String id, Map<String, dynamic> data) => WorkoutSession(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        entries: (data['entries'] as List<dynamic>? ?? [])
            .map((e) => WorkoutEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
        notes: data['notes'],
      );
}
