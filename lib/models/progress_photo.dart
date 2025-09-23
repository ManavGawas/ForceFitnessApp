class ProgressPhoto {
  final String id;
  final DateTime date;
  final String storagePath; // path or URL
  final String? note;

  ProgressPhoto({required this.id, required this.date, required this.storagePath, this.note});

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'storagePath': storagePath,
        'note': note,
      };

  factory ProgressPhoto.fromMap(String id, Map<String, dynamic> data) => ProgressPhoto(
        id: id,
        date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
        storagePath: data['storagePath'] ?? '',
        note: data['note'],
      );
}
