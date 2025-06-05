import 'dart:convert';

class CalendarEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? location;
  final String? mood;
  final String? weather;
  final List<String> imageUrls;

  CalendarEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.location,
    this.mood,
    this.weather,
    this.imageUrls = const [],
  });

  factory CalendarEntry.create({
    required String title,
    required String content,
    List<String> tags = const [],
    String? location,
    String? mood,
    String? weather,
    List<String> imageUrls = const [],
  }) {
    final now = DateTime.now();
    return CalendarEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      location: location,
      mood: mood,
      weather: weather,
      imageUrls: imageUrls,
    );
  }

  CalendarEntry copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    List<String>? tags,
    String? location,
    String? mood,
    String? weather,
    List<String>? imageUrls,
  }) {
    return CalendarEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'location': location,
      'mood': mood,
      'weather': weather,
      'imageUrls': imageUrls,
    };
  }

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    return CalendarEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location'],
      mood: json['mood'],
      weather: json['weather'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  int get wordCount {
    return content.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  // 从Markdown内容中提取图片URL
  List<String> extractImagesFromMarkdown() {
    final RegExp imgRegExp = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = imgRegExp.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}