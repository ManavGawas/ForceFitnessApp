class NutritionEntry {
  final String id;
  final DateTime date;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  NutritionEntry({
    required this.id,
    required this.date,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      };

  factory NutritionEntry.fromMap(String id, Map<String, dynamic> data) => NutritionEntry(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        name: data['name'] ?? '',
        calories: data['calories'] ?? 0,
        protein: data['protein'] ?? 0,
        carbs: data['carbs'] ?? 0,
        fats: data['fats'] ?? 0,
      );
}
