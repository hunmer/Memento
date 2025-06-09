class CompletionRecord {
  final String id;
  final String parentId; // Skill/Habit ID
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int durationMinutes;

  CompletionRecord({
    required this.id,
    required this.parentId,
    this.notes,
    required this.createdAt,
    this.completedAt,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory CompletionRecord.fromMap(Map<String, dynamic> map) {
    return CompletionRecord(
      id: map['id'],
      parentId: map['parentId'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      durationMinutes: map['durationMinutes'],
    );
  }
}
