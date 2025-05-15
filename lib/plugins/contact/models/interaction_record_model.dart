class InteractionRecord {
  final String id;
  final String contactId;
  final DateTime date;
  final String notes;
  final String type;

  InteractionRecord({
    required this.id,
    required this.contactId,
    required this.date,
    required this.notes,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'date': date.toIso8601String(),
      'notes': notes,
      'type': type,
    };
  }

  factory InteractionRecord.fromJson(Map<String, dynamic> json) {
    return InteractionRecord(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      type: json['type'] as String,
    );
  }
}