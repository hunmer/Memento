class Skill {
  final String id;
  final String title;
  final String? description;
  final String? notes;
  final String? group;
  final String? icon;
  final String? image;
  final int targetMinutes;
  final int maxDurationMinutes;

  Skill({
    required this.id,
    required this.title,
    this.description,
    this.notes,
    this.group,
    this.icon,
    this.image,
    this.targetMinutes = 0,
    this.maxDurationMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'notes': notes,
      'group': group,
      'icon': icon,
      'image': image,
      'targetMinutes': targetMinutes,
      'maxDurationMinutes': maxDurationMinutes,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description'],
      notes: map['notes'],
      group: map['group'],
      icon: map['icon'],
      image: map['image'],
      targetMinutes: (map['targetMinutes'] as num?)?.toInt() ?? 0,
      maxDurationMinutes: (map['maxDurationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
