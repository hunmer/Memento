class CompletionRecord {
  final String id;
  final String parentId;
  final DateTime date;
  final Duration duration;
  final String notes;

  CompletionRecord({
    required this.id,
    required this.parentId,
    required this.date,
    required this.duration,
    required this.notes,
  });

  factory CompletionRecord.fromMap(Map<String, dynamic> map) {
    return CompletionRecord(
      id: map['id']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      date: map['date'] != null ? DateTime.parse(map['date'].toString()) : DateTime.now(),
      duration: Duration(seconds: (map['duration'] as num?)?.toInt() ?? 0),
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'date': date.toIso8601String(),
      'duration': duration.inSeconds,
      'notes': notes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
