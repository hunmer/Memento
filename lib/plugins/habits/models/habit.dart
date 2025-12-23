class Habit {
  final String id;
  final String title;
  final String? notes;
  final String? group;
  final String? icon;
  final String? image;
  final List<int> reminderDays; // 0-6 for Sunday-Saturday
  final int intervalDays; // 0 for daily
  final int durationMinutes;
  final List<String> tags;
  final String? skillId;
  final int totalDurationMinutes; // 所有记录累计时长（缓存字段，避免重复计算）

  Habit({
    required this.id,
    required this.title,
    this.notes,
    this.group,
    this.icon,
    this.image,
    this.reminderDays = const [],
    this.intervalDays = 0,
    required this.durationMinutes,
    this.tags = const [],
    this.skillId,
    this.totalDurationMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'group': group,
      'icon': icon,
      'image': image,
      'reminderDays': reminderDays,
      'intervalDays': intervalDays,
      'durationMinutes': durationMinutes,
      'tags': tags,
      'skillId': skillId,
      'totalDurationMinutes': totalDurationMinutes,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      notes: map['notes'],
      group: map['group'],
      icon: map['icon'],
      image: map['image'],
      reminderDays: List<int>.from(map['reminderDays'] ?? []),
      intervalDays: (map['intervalDays'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      skillId: map['skillId'],
      totalDurationMinutes: (map['totalDurationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
