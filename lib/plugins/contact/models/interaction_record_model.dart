class InteractionRecord {
  final String id;
  final String contactId;
  final DateTime date;
  final String notes;
  final List<String> participants; // 其他参与联系的联系人ID列表

  InteractionRecord({
    required this.id,
    required this.contactId,
    required this.date,
    required this.notes,
    List<String>? participants,
  }) : participants = participants ?? [];

  factory InteractionRecord.empty() {
    return InteractionRecord(
      id: '',
      contactId: '',
      date: DateTime.now(),
      notes: '',
      participants: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'date': date.toIso8601String(),
      'notes': notes,
      'participants': participants,
    };
  }

  factory InteractionRecord.fromJson(Map<String, dynamic> json) {
    return InteractionRecord(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      participants: List<String>.from(json['participants'] as List? ?? []),
    );
  }

  InteractionRecord copyWith({
    String? id,
    String? contactId,
    DateTime? date,
    String? notes,
    List<String>? participants,
  }) {
    return InteractionRecord(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      participants: participants ?? List<String>.from(this.participants),
    );
  }
}
