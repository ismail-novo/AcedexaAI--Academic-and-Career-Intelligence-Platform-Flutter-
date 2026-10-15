class StudyMaterial {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StudyMaterial.fromMap(Map<String, dynamic> m) => StudyMaterial(
        id: m['id'] as String,
        title: m['title'] as String? ?? 'Note',
        content: m['content'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
