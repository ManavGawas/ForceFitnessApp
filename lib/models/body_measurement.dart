class BodyMeasurement {
  final String id;
  final DateTime date;
  final double weightKg;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? arm;
  final double? thigh;

  BodyMeasurement({
    required this.id,
    required this.date,
    required this.weightKg,
    this.chest,
    this.waist,
    this.hips,
    this.arm,
    this.thigh,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'chest': chest,
        'waist': waist,
        'hips': hips,
        'arm': arm,
        'thigh': thigh,
      };

  factory BodyMeasurement.fromMap(String id, Map<String, dynamic> data) => BodyMeasurement(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        weightKg: (data['weightKg'] ?? 0).toDouble(),
        chest: (data['chest'] as num?)?.toDouble(),
        waist: (data['waist'] as num?)?.toDouble(),
        hips: (data['hips'] as num?)?.toDouble(),
        arm: (data['arm'] as num?)?.toDouble(),
        thigh: (data['thigh'] as num?)?.toDouble(),
      );
}
