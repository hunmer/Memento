class Note {
  final String id;
  String title;
  String content;
  final String folderId;
  final DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      folderId: json['folderId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}