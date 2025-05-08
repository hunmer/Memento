
import './goal.dart';

class Record {
  final String id;
  final String goalId;
  final double value;
  final String? note;
  final DateTime recordedAt;

  Record({
    required this.id,
    required this.goalId,
    required this.value,
    this.note,
    required this.recordedAt,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'],
      goalId: json['goalId'],
      value: json['value'],
      note: json['note'],
      recordedAt: DateTime.parse(json['recordedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'value': value,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
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
