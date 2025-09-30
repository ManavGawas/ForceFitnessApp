class Tutorial {
  final String id;
  final String title;
  final String? description;
  final List<String> imageUrls; // can be asset paths or network URLs
  final String? videoUrl; // optional network video
  Tutorial({
    required this.id,
    required this.title,
    this.description,
    this.imageUrls = const [],
    this.videoUrl,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
      };

  factory Tutorial.fromMap(String id, Map<String, dynamic> m) => Tutorial(
        id: id,
        title: m['title'] ?? '',
        description: m['description'],
        imageUrls: (m['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        videoUrl: m['videoUrl'],
      );
}
