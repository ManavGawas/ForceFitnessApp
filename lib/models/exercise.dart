class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String? equipment;
  final String? notes;
  // Extended optional metadata for richer UI/filters
  final String? category;
  final String? primaryMuscle;
  final List<String>? secondaryMuscles;
  final bool? isCustom;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.equipment,
    this.notes,
    this.category,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.isCustom,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'notes': notes,
        if (category != null) 'category': category,
        if (primaryMuscle != null) 'primaryMuscle': primaryMuscle,
        if (secondaryMuscles != null) 'secondaryMuscles': secondaryMuscles,
        if (isCustom != null) 'isCustom': isCustom,
      };

  factory Exercise.fromMap(String id, Map<String, dynamic> data) => Exercise(
        id: id,
        name: data['name'] ?? '',
        muscleGroup: data['muscleGroup'] ?? '',
        equipment: data['equipment'],
        notes: data['notes'],
        category: data['category'],
        primaryMuscle: data['primaryMuscle'],
        secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        isCustom: data['isCustom'],
      );
}
