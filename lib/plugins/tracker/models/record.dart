import './goal.dart';

class Record {
  final String id;
  final String goalId;
  final double value;
  final String? note;
  final DateTime recordedAt;
  final int? durationSeconds; // 记录时间（秒）

  Record({
    required this.id,
    required this.goalId,
    required this.value,
    this.note,
    required this.recordedAt,
    this.durationSeconds,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'],
      goalId: json['goalId'],
      value: json['value'],
      note: json['note'],
      recordedAt: DateTime.parse(json['recordedAt']),
      durationSeconds: json['durationSeconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'value': value,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  static void validate(Record record, Goal goal) {
    if (record.value <= 0) {
      throw ArgumentError('Record value must be positive');
    }
    if (record.goalId != goal.id) {
      throw ArgumentError('Record does not belong to the specified goal');
    }
  }
}
