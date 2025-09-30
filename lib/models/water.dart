class WaterEntry {
  final String id;
  final DateTime date;
  // milliliters consumed in this entry
  final int ml;
  WaterEntry({required this.id, required this.date, required this.ml});
  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'ml': ml,
      };
  factory WaterEntry.fromMap(String id, Map<String, dynamic> data) => WaterEntry(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        ml: (data['ml'] as num?)?.toInt() ?? 0,
      );
}
