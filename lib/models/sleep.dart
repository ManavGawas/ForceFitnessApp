class SleepEntry {
  final String id;
  final DateTime date;
  // duration in minutes
  final int minutes;
  SleepEntry({required this.id, required this.date, required this.minutes});
  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'minutes': minutes,
      };
  factory SleepEntry.fromMap(String id, Map<String, dynamic> data) => SleepEntry(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        minutes: (data['minutes'] as num?)?.toInt() ?? 0,
      );
}
