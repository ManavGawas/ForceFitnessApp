class SplitPlan {
  final String id;
  final String name;
  final Map<int, List<String>> days; // weekday (1=Mon..7=Sun) -> exercise IDs or names
  final bool active;

  SplitPlan({required this.id, required this.name, required this.days, this.active = false});

  Map<String, dynamic> toMap() => {
        'name': name,
        'active': active,
        // Store keys as strings to be Firestore-friendly
        'days': days.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory SplitPlan.fromMap(String id, Map<String, dynamic> data) {
    final raw = (data['days'] as Map<String, dynamic>? ?? {});
    final parsed = <int, List<String>>{};
    for (final entry in raw.entries) {
      final day = int.tryParse(entry.key);
      if (day == null) continue;
      parsed[day] = (entry.value as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    }
    return SplitPlan(
      id: id,
      name: data['name'] ?? 'Split',
      days: parsed,
      active: data['active'] == true,
    );
  }
}
