class RunSession {
  final String id;
  final DateTime start;
  final DateTime? end;
  final double distanceMeters;
  final int durationSeconds;
  final List<Map<String, double>> path; // [{lat, lng}, ...]

  RunSession({
    required this.id,
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.path,
  });

  Map<String, dynamic> toMap() => {
        'start': start.toIso8601String(),
        if (end != null) 'end': end!.toIso8601String(),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'path': path
            .map((p) => {'lat': p['lat'] ?? 0.0, 'lng': p['lng'] ?? 0.0})
            .toList(),
      };

  factory RunSession.fromMap(String id, Map<String, dynamic> data) => RunSession(
        id: id,
        start: DateTime.tryParse(data['start'] ?? '') ?? DateTime.now(),
        end: data['end'] != null ? DateTime.tryParse(data['end']) : null,
        distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
        path: ((data['path'] as List?) ?? [])
            .map((e) => {
                  'lat': (e['lat'] as num?)?.toDouble() ?? 0.0,
                  'lng': (e['lng'] as num?)?.toDouble() ?? 0.0,
                })
            .toList(),
      );
}
