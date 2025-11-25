class UsageRecord {
  final DateTime date;
  final String? note;
  final int? duration; // Duration in minutes
  final String? location;

  UsageRecord({
    required this.date,
    this.note,
    this.duration,
    this.location,
  });

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      duration: json['duration'] as int?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'note': note,
      'duration': duration,
      'location': location,
    };
  }
}