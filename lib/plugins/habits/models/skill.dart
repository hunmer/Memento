class Skill {
  final String id;
  final String title;
  final String? notes;
  final String? group;
  final String? icon;
  final String? image;
  final int maxDurationMinutes; // 0 for unlimited

  Skill({
    required this.id,
    required this.title,
    this.notes,
    this.group,
    this.icon,
    this.image,
    this.maxDurationMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'group': group,
      'icon': icon,
      'image': image,
      'maxDurationMinutes': maxDurationMinutes,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'],
      title: map['title'],
      notes: map['notes'],
      group: map['group'],
      icon: map['icon'],
      image: map['image'],
      maxDurationMinutes: map['maxDurationMinutes'] ?? 0,
    );
  }
}
