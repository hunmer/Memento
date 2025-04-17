class UsageRecord {
  final DateTime date;
  final String? note;

  UsageRecord({
    required this.date,
    this.note,
  });

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}