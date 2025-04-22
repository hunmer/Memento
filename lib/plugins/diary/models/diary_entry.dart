class DiaryEntry {
  final DateTime date;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? mood; // 心情表情符号

  DiaryEntry({
    required this.date,
    this.title = '',
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.mood,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      mood: json['mood'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mood': mood,
    };
  }

  DiaryEntry copyWith({
    DateTime? date,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mood,
  }) {
    return DiaryEntry(
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mood: mood ?? this.mood,
    );
  }
}
