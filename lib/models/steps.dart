class StepsEntry {
  final String id;
  final DateTime date;
  final int steps;

  StepsEntry({required this.id, required this.date, required this.steps});

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'steps': steps,
      };

  factory StepsEntry.fromMap(String id, Map<String, dynamic> data) => StepsEntry(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        steps: (data['steps'] as num?)?.toInt() ?? 0,
      );
}
